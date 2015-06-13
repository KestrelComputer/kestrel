#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "types.h"
#include "config.h"
#include "options.h"
#include "address_space.h"
#include "processor.h"


extern const struct interface_AddressSpace module_AddressSpace;
static const struct interface_AddressSpace const *as = &module_AddressSpace;


static DWORD
getCSR(Processor *p, int csr) {
	switch(csr) {
	case r_MCPUID:		return p->csr[i_MCPUID];
	case r_MIMPID:		return p->csr[i_MIMPID];
	case r_MHARTID:		return p->csr[i_MHARTID];
	case r_MSTATUS:		return p->csr[i_MSTATUS];
	case r_MTVEC:		return p->csr[i_MTVEC];
	case r_MEPC:		return p->csr[i_MEPC];
	case r_MBADADDR:	return p->csr[i_MBADADDR];
	case r_MCAUSE:		return p->csr[i_MCAUSE];
	default:
		fprintf(stderr, "Warning: At $%016llX, attempt to read unsupported CSR %d\n", p->pc-4, csr);
		return 0xCCCCCCCCCCCCCCCC;
	}
}


static void
setCSR(Processor *p, int csr, DWORD v) {
	switch(csr) {
	case r_MSTATUS:
		p->csr[i_MSTATUS] = (v & 0x00000000003FFFF9) | 0x06;	// We only support machine-mode, so hardwire privilege level.
		break;
	case r_MTVEC:
		p->csr[i_MTVEC] = v & -0x200;
		break;
	case r_MEPC:
		p->csr[i_MEPC] = v;
		break;
	case r_MBADADDR:
		p->csr[i_MBADADDR] = v;
		break;
	case r_MCAUSE:
		p->csr[i_MCAUSE] = v & 0x800000000000000F;
		break;
	default:
		fprintf(stderr, "Warning: At $%016llX, attempt to write $%016llX to unsupported CSR %d\n", p->pc-4, v, csr);
	}
}


static void
orCSR(Processor *p, int csr, DWORD v) {
	setCSR(p, csr, v | getCSR(p, csr));
}


static void
andCSR(Processor *p, int csr, DWORD v) {
	setCSR(p, csr, v & getCSR(p, csr));
}


static void
trap(Processor *p, int cause) {
	UDWORD privStack = ((p->csr[i_MSTATUS] & 0x1FF) << 3) | 6;
	int offset;

	// What mode are we coming from?  Calculate MVTEC offset from that.
	offset = (privStack & 0x6) << 5;

	// Assume the role of machiine-mode.
	p->csr[i_MCAUSE] = (UDWORD)cause;
	p->csr[i_MEPC] = p->csr[i_MBADADDR] = p->pc - 4;
	p->csr[i_MSTATUS] = ((p->csr[i_MSTATUS] & -0x1000) | privStack) & ~0x10000;
	p->pc = p->csr[i_MTVEC] + offset;
}


static void
ecall(Processor *p) {
	trap(p, 8 + ((p->csr[i_MSTATUS] & 6) >> 1));
}


static void
eret(Processor *p) {
	UDWORD privStack = ((p->csr[i_MSTATUS] & 0xFF8) >> 3) | 0x206;	// 0x206 vs 0x200 b/c we only support M-mode.
	p->csr[i_MSTATUS] = (p->csr[i_MSTATUS] & -0x1000) | privStack;
	p->pc = p->csr[i_MEPC];
}


static Processor *
make(AddressSpace *as) {
	Processor *p = (Processor *)malloc(sizeof(Processor));
	if(p) {
		memset(p, 0, sizeof(Processor));
		p->pc = -0x100;
		p->as = as;
		p->running = 1;

		// We emulate a 64-bit RISC-V instruction set.  No frills.
		// We are currently vendor ID $8000.
		p->csr[i_MCPUID] = 0x8000000000000100;
		p->csr[i_MIMPID] = 0x0000000000008000;
		p->csr[i_MHARTID] = 0;
		p->csr[i_MSTATUS] = 0xDD6;	// Make sure to boot in machine mode!!  :)
		p->csr[i_MTVEC] = -0x200;
	}
	return p;
}


static void
step(Processor *p) {
	WORD ir;
	int opc, rd, fn3, rs1, rs2, imm12, imm12s, disp12;
	DWORD imm20, disp20, ia;

	if(!p->running) return;

	ia = p->pc;
	ir = as->fetch_word(p->as, ia);
	p->pc = ia + 4;

	/* This takes a bunch of time.  But it's still faster than live FPGA hardware.  ;) */
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
		// LUI
		case 0x37:
			p->x[rd] = imm20;
			break;

		// AUIPC
		case 0x17:
			p->x[rd] = imm20 + p->pc;
			break;

		// JAL
		case 0x6F:
			p->x[rd] = p->pc;
			p->pc = ia + disp20;
			break;

		// JALR
		case 0x67:
			p->x[rd] = p->pc;
			p->pc = (p->x[rs1] + imm12) & -2;
			break;

		// Bxx
		case 0x63:
			switch(fn3) {
				case 0: // BEQ
					if(p->x[rs1] == p->x[rs2])
						p->pc = ia + disp12;
					break;

				case 1: // BNE
					if(p->x[rs1] != p->x[rs2])
						p->pc = ia + disp12;
					break;

				case 2: // unused
				case 3: // unused
					trap(p, 2);
					break;

				case 4: // BLT
					if((DWORD)(p->x[rs1]) < (DWORD)(p->x[rs2]))
						p->pc = ia + disp12;
					break;

				case 5: // BGE
					if((DWORD)(p->x[rs1]) >= (DWORD)(p->x[rs2]))
						p->pc = ia + disp12;
					break;

				case 6: // BLTU
					if((UDWORD)(p->x[rs1]) < (UDWORD)(p->x[rs2]))
						p->pc = ia + disp12;
					break;

				case 7: // BGEU
					if((UDWORD)(p->x[rs1]) >= (UDWORD)(p->x[rs2]))
						p->pc = ia + disp12;
					break;
			}
			break;

		// Lx(x)
		case 0x03:
			switch(fn3) {
				case 0: // LB
					p->x[rd] = as->fetch_byte(p->as, p->x[rs1] + imm12);
					p->x[rd] |= -(p->x[rd] & 0x80);
					break;

				case 1: // LH
					p->x[rd] = as->fetch_hword(p->as, p->x[rs1] + imm12);
					p->x[rd] |= -(p->x[rd] & 0x8000);
					break;

				case 2: // LW
					p->x[rd] = as->fetch_word(p->as, p->x[rs1] + imm12);
					p->x[rd] |= -(p->x[rd] & 0x80000000);
					break;

				case 3: // LD
					p->x[rd] = as->fetch_dword(p->as, p->x[rs1] + imm12);
					// p->x[rd] |= -(p->x[rd] & 0x8000000000000000);
					break;

				case 4: // LBU
					p->x[rd] = as->fetch_byte(p->as, p->x[rs1] + imm12);
					break;

				case 5: // LHU
					p->x[rd] = as->fetch_hword(p->as, p->x[rs1] + imm12);
					break;

				case 6: // LWU
					p->x[rd] = as->fetch_word(p->as, p->x[rs1] + imm12);
					break;

				case 7: // LDU
					p->x[rd] = as->fetch_dword(p->as, p->x[rs1] + imm12);
					break;
			}
			break;
		// Sx
		case 0x23:
			switch(fn3) {
				case 0: // SB
					as->store_byte(p->as, p->x[rs1]+imm12s, p->x[rs2]);
					break;

				case 1: // SH
					as->store_hword(p->as, p->x[rs1]+imm12s, p->x[rs2]);
					break;

				case 2: // SW
					as->store_word(p->as, p->x[rs1]+imm12s, p->x[rs2]);
					break;

				case 3: // SD
					as->store_dword(p->as, p->x[rs1]+imm12s, p->x[rs2]);
					break;

				default:
					trap(p, 2);
					return;
			}
			break;

		// ADDI, et. al.
		case 0x13:
			switch(fn3) {
			case 0: // ADDI
				p->x[rd] = p->x[rs1] + imm12;
				break;

			case 1: // SLLI
				p->x[rd] = p->x[rs1] << imm12;
				break;

			case 2: // SLTI
				p->x[rd] = (DWORD)p->x[rs1] < imm12;
				break;

			case 3: // SLTIU
				p->x[rd] = (UDWORD)p->x[rs1] < (UDWORD)imm12;
				break;

			case 4: // XORI
				p->x[rd] = p->x[rs1] ^ imm12;
				break;

			case 5: // SRLI, SRAI
				if(ir & 0x40000000) p->x[rd] = (DWORD)p->x[rs1] >> imm12;
				else                p->x[rd] = (UDWORD)p->x[rs1] >> (UDWORD)imm12;
				break;

			case 6: // ORI
				p->x[rd] = p->x[rs1] | imm12;
				break;

			case 7: // ANDI
				p->x[rd] = p->x[rs1] & imm12;
				break;

			}
			break;

		// CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
		// and other system-type instructions.
		case 0x73:
			imm12 = imm12 & 0xFFF;

			if(fn3 != 0) {
				p->x[rd] = getCSR(p, imm12);
			} else {
				switch(imm12) {
				case 0x000:		// ECALL
					ecall(p);
					break;

				case 0x001:		// EBREAK
					trap(p, 3);
					break;

				case 0x100:		// ERET
					eret(p);
					break;

				case 0x102:		// WFI == NOP for now.
					break;

				case 0x305:		// MRTS
				case 0x306:		// MRTH
				case 0x205:		// HRTS
				case 0x101:		// VMFENCE (aka FENCE.VM)
				default:
					trap(p, 2);
				};
				break;
			}

			if(rs1) {
				switch(fn3) {
				case 1: // CSRRW
					setCSR(p, imm12, p->x[rs1]);
					break;

				case 2: // CSRRS
					orCSR(p, imm12, p->x[rs1]);
					break;

				case 3: // CSRRC
					andCSR(p, imm12, ~(p->x[rs1]));
					break;

				case 4: // undefined
					trap(p, 2);
					break;

				case 5: // CSRRW
					setCSR(p, imm12, rs1);
					break;

				case 6: // CSRRS
					orCSR(p, imm12, rs1);
					break;

				case 7: // CSRRC
					andCSR(p, imm12, ~rs1);
					break;
				}
			}
			break;

		// ADD, et. al.
		case 0x33:
			switch(fn3) {
			case 0: // ADD, SUB
				if(ir & 0x40000000) p->x[rd] = p->x[rs1] - p->x[rs2];
				else                p->x[rd] = p->x[rs1] + p->x[rs2];
				break;

			case 1: // SLL
				p->x[rd] = p->x[rd] << p->x[rs2];
				break;

			case 2: // SLT
				p->x[rd] = (DWORD)p->x[rs1] < (DWORD)p->x[rs2];
				break;

			case 3: // SLTU
				p->x[rd] = (UDWORD)p->x[rs1] < (UDWORD)p->x[rs2];
				break;

			case 4: // XOR
				p->x[rd] = p->x[rs1] ^ p->x[rs2];
				break;

			case 5: // SRL, SRA
				if(ir & 0x40000000) p->x[rd] = (DWORD)p->x[rs1] >> p->x[rs2];
				else                p->x[rd] = (UDWORD)p->x[rs1] >> (UDWORD)p->x[rs2];
				break;

			case 6: // OR
				p->x[rd] = p->x[rs1] | p->x[rs2];
				break;

			case 7: // AND
				p->x[rd] = p->x[rs1] & p->x[rs2];
				break;
			}
			break;

		default:
			trap(p, 2);
	}

	p->x[0] = 0;
}


const struct interface_Processor module_Processor = {
	.make = &make,
	.step = &step,
};


