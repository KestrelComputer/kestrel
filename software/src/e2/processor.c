/*
 * KCP53000 Emulator V2
 * Copyright (c) 2018 Samuel A. Falvo II
 * See LICENSE for license.
 *
 * V1 of this software implemented the Polaris CPU core, which later became the
 * KCP53000 processor.  V2 implements the KCP53000B processor.
 *
 * The difference between the two processors are subtle, but should be nearly
 * 100% compatible with each other.
 *
 * Polaris and KCP53000 cores (V1) implemented Privilege Specification 1.9.1.
 * The KCP53000B and KCP53010 cores (V2) implement version 1.10.
 */


#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "address_space.h"
#include "timeline.h"
#include "processor.h"


#define UNDEFINED	(0xCCCCCCCCCCCCCCCC)


static void
trap(Processor *p, Uint64_t cause) {
	/* KCP53000 only supports M-mode, so we can hardwire the
	 * MPP bits of mstatus.
	 */
	Uint64_t newstat = p->mstatus & 0xFFFFFFFFFFFFE777;
	newstat |= (p->mstatus & 0x8) << 4;

	p->mcause = cause;
	p->mepc = p->mtval = p->ia;
	p->mstatus = newstat;
	p->pc = p->mtvec;
}


static int64_t
getCSR(Processor *p, int csr) {
	switch(csr) {
	case CSR_MHARTID:	return p->mhartid;
	case CSR_MSTATUS:	return p->mstatus;
	case CSR_MTVEC:		return p->mtvec;
	case CSR_MEPC:		return p->mepc;
	case CSR_MTVAL:		return p->mtval;
	case CSR_MCAUSE:	return p->mcause;
	case CSR_MIE:		return p->mie;
	case CSR_MIP:		return p->mip;
	default:
		/* Illegal CSR addresses are now spec'd to trigger
		 * illegal instruction traps as of priv-spec 1.9.
		 */
		trap(p, EXCB_ILLEGAL_INST);
		return UNDEFINED;
	}
}


static void
setCSR(Processor *p, int csr, int64_t v) {
	switch(csr) {
	case CSR_MSTATUS:
		/* We only support machine-mode, so hardwire privilege
		 * level.
		 */
		p->mstatus = (v & 0x0000000000000088) | 0x0000000000001800;
		break;
	case CSR_MTVEC:
		p->mtvec = v & -4;
		break;
	case CSR_MEPC:
		p->mepc = v;
		break;
	case CSR_MTVAL:
		p->mtval = v;
		break;
	case CSR_MCAUSE:
		p->mcause = v & 0x800000000000000F;
		break;
	case CSR_MIE:
		/* Only machine-mode interrupts are supported, so
		 * we hardwire hypervisor, supervisor, and user-mode
		 * enables to zero.
		 */
		p->mie = v & 0x888;
		break;
	case CSR_MIP:
		/* Only low 4 bits are changeable, per RV64S V1.7 spec.
		 * Only machine-mode is supported by KCP53000 however;
		 * so only bit 3 is writable in my implementation.
		 */
		p->mip &= -8;
		p->mip |= (v & 8);
		break;

	default:
		/* Illegal CSR addresses are now spec'd to trigger illegal
		 * instruction traps. (RV64S V1.9)
		 */
		trap(p, EXCB_ILLEGAL_INST);
	}
}


static void
orCSR(Processor *p, int csr, int64_t v) {
	setCSR(p, csr, v | getCSR(p, csr));
}


static void
andCSR(Processor *p, int csr, int64_t v) {
	setCSR(p, csr, v & getCSR(p, csr));
}


static void
ecall(Processor *p) {
	/* RV64S V1.9 change: mstatus no longer tracks current operating mode.
	 */
	trap(p, 11);
}


static void
mret(Processor *p) {
	Uint64_t new_mie = (p->mstatus & 0x80) >> 4;
	p->mstatus = (p->mstatus & 0xFFFFFFFFFFFE0F77) | new_mie | 0x1880;
	p->pc = p->mepc;
}


static Processor *
new_processor(AddressSpace *as) {
	Processor *p = (Processor *)malloc(sizeof(Processor));
	if(p) {
		memset(p, 0, sizeof(Processor));
		p->pc = -0x100;
		p->as = as;

		/* We emulate a 64-bit RISC-V instruction set.  No frills.
		 * We are currently vendor ID $8000.
		 */
		p->misa = 0x4000000000040100;
		p->mvendorid = 0;
		p->marchid = 0;
		p->mimpid = 0x0100000000000000;
		p->mhartid = 0;
		p->mstatus = 0x1800;
		p->mtvec = -0x200;
		p->mie = 0;
	}
	return p;
}


void
step(Processor *p, Timeline *t) {
	int32_t ir;
	int opc, rd, fn3, rs1, rs2, imm12, imm12s, disp12;
	int64_t imm20, disp20, ia;
	Uint64_t mask, v;

	/* If service from the virtual machine monitor is required,
	 * return to the VMM until it has been properly serviced.
	 */
	if(p->vmcause) return;

	ia = p->ia = p->pc;

	/* Isolate the highest priority pending interrupt, and dispatch
	 * if needed.  Note that we do *not* attempt to execute the
	 * current instruction yet.
	 *
	 * According to interrupt resolution order specs in priv-spec 1.10,
	 * the software interrupts are higher priority than the timer
	 * interrupts.  This seems bizarre to me.
	 */

	mask = (p->mstatus & MSTATUSF_MIE) ?
		p->mip & p->mie : 0;
	if(mask & MIEF_MEIE) {
		trap(p, MCAUSEF_IRQ | MEIB_MEIE);
	}
	else if(mask & MIEF_MSIE) {
		trap(p, MCAUSEF_IRQ | MEIB_MSIE);
	}
	else if(mask & MIEF_MTIE) {
		trap(p, MCAUSEF_IRQ | MEIB_MTIE);
	}

	ir = as->fetch_word(p->as, ia);
	p->pc = ia + 4;
	tt->step(t, 2); /* 32-bit fetches take 2 cycles over 16-bit bus. */

	/* This takes a bunch of time. */
	opc = ir & 0x7F;
	rd = (ir >> 7) & 0x1F;
	fn3 = (ir >> 12) & 0x07;
	rs1 = (ir >> 15) & 0x1F;
	rs2 = (ir >> 20) & 0x1F;
	imm20 = (ir & 0xFFFFF000) | (-(ir & 0x80000000));
	imm12 = ir >> 20;
	imm12 |= -(imm12 & 0x800);
	imm12s = ((ir >> 7) & 0x1F) | ((ir >> 20) & 0xFE0);
	imm12s |= -(imm12s & 0x800);
	disp20 = (((ir & 0x7FE00000) >> 20)
		 |((ir & 0x00100000) >> 9)
		 |(ir & 0x000FF000)
		 |((ir & 0x80000000) >> 11));
	disp20 |= -(disp20 & 0x00100000);
	disp12 = (((ir >> 7) & 0x001E)
		 |((ir << 4) & 0x0800)
		 |((ir >> 20) & 0x07E0)
		 |((ir >> 19) & 0x1000));
	disp12 |= -(disp12 & 0x00001000);

	switch(opc) {
		/* LUI */
		case 0x37:
			p->x[rd] = imm20;
			break;

		/* AUIPC */
		case 0x17:
			p->x[rd] = imm20 + ia;
			break;

		/* JAL */
		case 0x6F:
			p->x[rd] = p->pc;
			p->pc = ia + disp20;
			break;

		/* JALR */
		case 0x67:
			p->x[rd] = p->pc;
			p->pc = (p->x[rs1] + imm12) & -2;
			break;

		/* Bxx */
		case 0x63:
			switch(fn3) {
				case 0: /* BEQ */
					if(p->x[rs1] == p->x[rs2])
						p->pc = ia + disp12;
					break;

				case 1: /* BNE */
					if(p->x[rs1] != p->x[rs2])
						p->pc = ia + disp12;
					break;

				case 2: /* unused */
				case 3: /* unused */
					trap(p, EXCB_ILLEGAL_INST);
					break;

				case 4: /* BLT */
					if(
						(int64_t)(p->x[rs1]) <
						(int64_t)(p->x[rs2])
					)
						p->pc = ia + disp12;
					break;

				case 5: /* BGE */
					if(
						(int64_t)(p->x[rs1]) >=
						(int64_t)(p->x[rs2])
					)
						p->pc = ia + disp12;
					break;

				case 6: /* BLTU */
					if(
						(Uint64_t)(p->x[rs1]) <
						(Uint64_t)(p->x[rs2])
					)
						p->pc = ia + disp12;
					break;

				case 7: /* BGEU */
					if(
						(Uint64_t)(p->x[rs1]) >=
						(Uint64_t)(p->x[rs2])
					)
						p->pc = ia + disp12;
					break;
			}
			break;

		/* Lx(x) */
		case 0x03:
			switch(fn3) {
				case 0: /* LB */
					p->x[rd] = as->fetch_byte(
						p->as, p->x[rs1] + imm12
					);
					p->x[rd] |= -(p->x[rd] & 0x80);
					tt->step(t, 1);
					break;

				case 1: /* LH */
					p->x[rd] = as->fetch_hword(
						p->as, p->x[rs1] + imm12
					);
					p->x[rd] |= -(p->x[rd] & 0x8000);
					tt->step(t, 1);
					break;

				case 2: /* LW */
					p->x[rd] = as->fetch_word(
						p->as, p->x[rs1] + imm12
					);
					p->x[rd] |= -(p->x[rd] & 0x80000000);
					tt->step(t, 2);
					break;

				case 3: /* LD */
					p->x[rd] = as->fetch_dword(
						p->as, p->x[rs1] + imm12
					);
					tt->step(t, 4);
					break;

				case 4: /* LBU */
					p->x[rd] = as->fetch_byte(
						p->as, p->x[rs1] + imm12
					);
					tt->step(t, 1);
					break;

				case 5: /* LHU */
					p->x[rd] = as->fetch_hword(
						p->as, p->x[rs1] + imm12
					);
					tt->step(t, 1);
					break;

				case 6: /* LWU */
					p->x[rd] = as->fetch_word(
						p->as, p->x[rs1] + imm12
					);
					tt->step(t, 2);
					break;

				case 7: /* LDU */
					p->x[rd] = as->fetch_dword(
						p->as, p->x[rs1] + imm12'
					);
					tt->step(t, 4);
					break;
			}
			break;
		/* Sx */
		case 0x23:
			switch(fn3) {
				case 0: /* SB */
					as->store_byte(
						p->as,
						p->x[rs1]+imm12s,
						p->x[rs2]
					);
					tt->step(t, 1);
					break;

				case 1: /* SH */
					as->store_hword(
						p->as,
						p->x[rs1]+imm12s,
						p->x[rs2]
					);
					tt->step(t, 1);
					break;

				case 2: /* SW */
					as->store_word(
						p->as,
						p->x[rs1]+imm12s,
						p->x[rs2]
					);
					tt->step(t, 2);
					break;

				case 3: /* SD */
					as->store_dword(
						p->as,
						p->x[rs1]+imm12s,
						p->x[rs2]
					);
					tt->step(t, 4);
					break;

				default:
					trap(p, EXCB_ILLEGAL_INST);
					return;
			}
			break;

		/* ADDI, et. al. */
		case 0x13:
			switch(fn3) {
			case 0: /* ADDI */
				p->x[rd] = p->x[rs1] + imm12;
				break;

			case 1: /* SLLI */
				p->x[rd] = p->x[rs1] << imm12;
				break;

			case 2: /* SLTI */
				p->x[rd] = (int64_t)p->x[rs1] < imm12;
				break;

			case 3: /* SLTIU */
				p->x[rd] =
				(Uint64_t)p->x[rs1] < (Uint64_t)imm12;
				break;

			case 4: /* XORI */
				p->x[rd] = p->x[rs1] ^ imm12;
				break;

			case 5: /* SRLI, SRAI */
				if(ir & 0x40000000) {
					p->x[rd] =
					(int64_t)p->x[rs1] >> imm12;
				}
				else {
					p->x[rd] =
					(Uint64_t)p->x[rs1] >> (Uint64_t)imm12;
				}
				break;

			case 6: /* ORI */
				p->x[rd] = p->x[rs1] | imm12;
				break;

			case 7: /* ANDI */
				p->x[rd] = p->x[rs1] & imm12;
				break;

			}
			break;

		/* CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
		 * and other system-type instructions.
		 */
		case 0x73:
			imm12 = imm12 & 0xFFF;
			v = p->x[rs1];

			if(fn3 != 0) {
				p->x[rd] = getCSR(p, imm12);
			}
			else {
				switch(imm12) {
				case 0x000:	/* ECALL */
					ecall(p);
					break;

				case 0x001:	/* EBREAK */
					trap(p, EXCB_BREAKPOINT);
					break;

				case 0x002:	/* URET */
				case 0x102:	/* SRET */
				case 0x202:	/* HRET */
					trap(p, EXCB_ILLEGAL_INST);
					break;

				case 0x302:	/* MRET */
					mret(p);
					break;

				case 0x105:	/* WFI == NOP for now. */
					break;

				case 0x104:	/* VMFENCE (aka FENCE.VM) */
					break;	/* NOP for now. */

				default:
					trap(p, EXCB_ILLEGAL_INST);
				};
				break;
			}

			if(rs1) {
				switch(fn3) {
				case 1: /* CSRRW */
					setCSR(p, imm12, v);
					break;

				case 2: /* CSRRS */
					orCSR(p, imm12, v);
					break;

				case 3: /* CSRRC */
					andCSR(p, imm12, ~v);
					break;

				case 4: /* undefined */
					trap(p, EXCB_ILLEGAL_INST);
					break;

				case 5: /* CSRRWI */
					setCSR(p, imm12, rs1);
					break;

				case 6: /* CSRRSI */
					orCSR(p, imm12, rs1);
					break;

				case 7: /* CSRRCI */
					andCSR(p, imm12, ~rs1);
					break;
				}
			}
			break;

		/* ADD, et. al. */
		case 0x33:
			switch(fn3) {
			case 0: /* ADD, SUB */
				if(ir & 0x40000000) {
					p->x[rd] = p->x[rs1] - p->x[rs2];
				}
				else {
					p->x[rd] = p->x[rs1] + p->x[rs2];
				}
				break;

			case 1: /* SLL */
				p->x[rd] = p->x[rs1] << p->x[rs2];
				break;

			case 2: /* SLT */
				p->x[rd] =
				(int64_t)p->x[rs1] < (int64_t)p->x[rs2];
				break;

			case 3: /* SLTU */
				p->x[rd] =
				(Uint64_t)p->x[rs1] < (Uint64_t)p->x[rs2];
				break;

			case 4: /* XOR */
				p->x[rd] = p->x[rs1] ^ p->x[rs2];
				break;

			case 5: /* SRL, SRA */
				if(ir & 0x40000000) {
					p->x[rd] =
					(int64_t)p->x[rs1] >> p->x[rs2];
				}
				else {
					p->x[rd] =
					(Uint64_t)p->x[rs1] >>
					(Uint64_t)p->x[rs2];
				}
				break;

			case 6: /* OR */
				p->x[rd] = p->x[rs1] | p->x[rs2];
				break;

			case 7: /* AND */
				p->x[rd] = p->x[rs1] & p->x[rs2];
				break;
			}
			break;

		default:
			trap(p, EXCB_ILLEGAL_INST);
	}

	p->x[0] = 0;
}
