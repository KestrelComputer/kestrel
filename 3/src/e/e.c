/* vim: set noet ts=8 sw=8: */


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <termios.h>
#include <unistd.h>


static struct termios stored_settings;


enum {
	VERSION_MAJOR	= 0,
	VERSION_MINOR	= 2,
	VERSION_PATCH	= 0,

	MB		= 1048576L,

	MAX_DEVS	= 16,
	DEV_MASK	= 0x0F00000000000000,
	CARD_MASK	= 0xF000000000000000,

	ROM_SIZE	= 65536,
	ROM_MASK	= ROM_SIZE-1,
	PHYS_RAM_SIZE	= 16*MB,
	PHYS_RAM_MASK	= PHYS_RAM_SIZE - 1,
	PHYS_ADDR_SIZE	= 32*MB,

	r_MCPUID	= 0xF00,
	r_MIMPID	= 0xF01,
	r_MHARTID	= 0xF10,
	r_MSTATUS	= 0x300,
	r_MTVEC		= 0x301,
	r_MDELEG	= 0x302,
	r_MEPC		= 0x341,
	r_MBADADDR	= 0x343,
	r_MCAUSE	= 0x342,
};


enum {
	i_MCPUID	= 0,
	i_MIMPID,
	i_MHARTID,
	i_MSTATUS,
	i_MTVEC,
	i_MDELEG,
	i_MEPC,
	i_MBADADDR,
	i_MCAUSE,
	i_MAXCSR
};


typedef signed char		BYTE;
typedef signed short		HWORD;
typedef signed long		WORD;
typedef signed long long	DWORD;

typedef unsigned char		UBYTE;
typedef unsigned short		UHWORD;
typedef unsigned long		UWORD;
typedef unsigned long long	UDWORD;

typedef struct AddressSpace	AddressSpace;
typedef struct Options		Options;
typedef struct Processor	Processor;

typedef void (*WRFUNC)(AddressSpace *, UDWORD, UDWORD, int);
typedef UDWORD (*RDFUNC)(AddressSpace *, UDWORD, int);


struct AddressSpace {
	UBYTE	*rom;
	UBYTE	*ram;
	WRFUNC	writers[MAX_DEVS];
	RDFUNC	readers[MAX_DEVS];
};


struct Options {
	char *	romFilename;
};


struct Processor {
	UDWORD       csr[i_MAXCSR];
	UDWORD       x[32];
	UDWORD       pc;
	AddressSpace *as;
	int          running;
};


void console_1char_mode(void) {
	struct termios new_settings;

	tcgetattr(0, &stored_settings);
	new_settings = stored_settings;
	new_settings.c_lflag &= ~ICANON;
	new_settings.c_lflag &= ~ECHO;
	new_settings.c_cc[VTIME] = 0;
	new_settings.c_cc[VMIN] = 1;

	tcsetattr(0, TCSANOW, &new_settings);
}


void console_line_mode(void) {
	tcsetattr(0,TCSANOW,&stored_settings);
}


AddressSpace *address_space_new(void) {
	AddressSpace *as = (AddressSpace*)malloc(sizeof(AddressSpace));
	if(as) {
		memset(as, 0, sizeof(AddressSpace));
	}
	return as;
}


void address_space_ram_writer(AddressSpace *as, UDWORD addr, UDWORD b, int sz) {
	addr &= ~(DEV_MASK | CARD_MASK);
	if(addr > PHYS_RAM_MASK) {
		fprintf(stderr, "Warning: writing $%016llX to mirrored RAM at $%016llX, size code %d\n", b, addr, sz);
	}
	switch(sz) {
	case 0:
		as->ram[addr & PHYS_RAM_MASK] = b;
		break;

	case 1:
		as->ram[addr & PHYS_RAM_MASK] = b;
		as->ram[(addr+1) & PHYS_RAM_MASK] = b >> 8;
		break;

	case 2:
		as->ram[addr & PHYS_RAM_MASK] = b;
		as->ram[(addr+1) & PHYS_RAM_MASK] = b >> 8;
		as->ram[(addr+2) & PHYS_RAM_MASK] = b >> 16;
		as->ram[(addr+3) & PHYS_RAM_MASK] = b >> 24;
		break;

	case 3:
		as->ram[addr & PHYS_RAM_MASK] = b;
		as->ram[(addr+1) & PHYS_RAM_MASK] = b >> 8;
		as->ram[(addr+2) & PHYS_RAM_MASK] = b >> 16;
		as->ram[(addr+3) & PHYS_RAM_MASK] = b >> 24;
		as->ram[(addr+4) & PHYS_RAM_MASK] = b >> 32;
		as->ram[(addr+5) & PHYS_RAM_MASK] = b >> 40;
		as->ram[(addr+6) & PHYS_RAM_MASK] = b >> 48;
		as->ram[(addr+7) & PHYS_RAM_MASK] = b >> 56;
		break;
	}
}


#define RAMF(a) (UDWORD)(as->ram[(a) & PHYS_RAM_MASK])

UDWORD address_space_ram_reader(AddressSpace *as, UDWORD addr, int sz) {
	addr &= ~(DEV_MASK | CARD_MASK);
	if(addr > PHYS_RAM_MASK) {
		fprintf(stderr, "Warning: reading mirrored RAM at $%016llX\n", addr);
	}
	switch(sz) {
	case 0:
		return RAMF(addr);

	case 1:
		return (RAMF(addr)
			| (RAMF(addr+1) << 8));

	case 2:
		return (RAMF(addr)
			| (RAMF(addr+1) << 8)
			| (RAMF(addr+2) << 16)
			| (RAMF(addr+3) << 24));

	case 3:
		return (RAMF(addr)
			| (RAMF(addr+1) << 8)
			| (RAMF(addr+2) << 16)
			| (RAMF(addr+3) << 24)
			| (RAMF(addr+4) << 32)
			| (RAMF(addr+5) << 40)
			| (RAMF(addr+6) << 48)
			| (RAMF(addr+7) << 56));
	}
	fprintf(stderr, "Read of unknown size at address $%016llX\n", addr);
	return 0xDDDDDDDD;
}


#define ROMF(a) (UDWORD)(as->rom[(a) & ROM_MASK])
UDWORD address_space_rom_reader(AddressSpace *as, UDWORD addr, int sz) {
	addr |= DEV_MASK | CARD_MASK;
	if((addr | ROM_MASK) != -1) {
		fprintf(stderr, "Warning: reading mirrored ROM at $%016llX\n", addr);
	}
	switch(sz) {
	case 0:
		return ROMF(addr);

	case 1:
		return (ROMF(addr)
			| (ROMF(addr+1) << 8));

	case 2:
		return (ROMF(addr)
			| (ROMF(addr+1) << 8)
			| (ROMF(addr+2) << 16)
			| (ROMF(addr+3) << 24));

	case 3:
		return (ROMF(addr)
			| (ROMF(addr+1) << 8)
			| (ROMF(addr+2) << 16)
			| (ROMF(addr+3) << 24)
			| (ROMF(addr+4) << 32)
			| (ROMF(addr+5) << 40)
			| (ROMF(addr+6) << 48)
			| (ROMF(addr+7) << 56));
	}
	fprintf(stderr, "Read of unknown size at address $%016llX\n", addr);
	return 0xDDDDDDDD;
}


void address_space_uart_writer(AddressSpace *as, UDWORD addr, UDWORD b, int sz) {
	addr &= ~(DEV_MASK | CARD_MASK);
	switch(addr & 1) {
	case 0:		printf("%c", (BYTE)b); fflush(stdout); break;
	default:	break;
	}
}


int debug_port_has_data() {
	fd_set fds;
	struct timeval tv = {0,};
	FD_ZERO(&fds);
	FD_SET(0, &fds);
	select(1, &fds, NULL, NULL, &tv);
	return FD_ISSET(0, &fds) != 0;
}

UDWORD address_space_uart_reader(AddressSpace *as, UDWORD addr, int sz) {
	int n;
	BYTE c;

	addr &= ~(DEV_MASK | CARD_MASK);
	switch(addr & 1) {
	case 0:		return debug_port_has_data();
	case 1:
		for(n = 0; !n; n = read(1, &c, 1));
		return c;
	}
	return 0;
}


void address_space_no_writer(AddressSpace *as, UDWORD addr, UDWORD b, int sz) {
	fprintf(stderr, "Error: Writing $%016llX to address $%016llX\n", b, addr);
}


UDWORD address_space_no_reader(AddressSpace *as, UDWORD addr, int sz) {
	fprintf(stderr, "Error: Reading from address $%016llX; returning $CC\n", addr);
	return 0xCCCCCCCCCCCCCCCC;
}


AddressSpace *address_space_configure(Options *opts) {
	AddressSpace *as = address_space_new();
	FILE *romFile;
	int n, overflow;

	assert(opts);
	assert(opts->romFilename);

	as->rom = (UBYTE *)malloc(ROM_SIZE);
	memset(as->rom, 0, ROM_SIZE);
	romFile = fopen(opts->romFilename, "rb");
	if(!romFile) {
		fprintf(stderr, "Cannot open ROM file %s\n", opts->romFilename);
		exit(1);
	}
	n = fread(as->rom, 1, ROM_SIZE, romFile);
	if(n == ROM_SIZE) {
		n = fread(&overflow, 1, 1, romFile);
		if(n == 1) {
			fprintf(stderr, "ROM file is too big; should be %d bytes.\n", ROM_SIZE);
			fclose(romFile);
			exit(1);
		}
	}
	fclose(romFile);

	as->ram = (UBYTE *)malloc(PHYS_RAM_SIZE);
	if(!as->ram) {
		fprintf(stderr, "Cannot allocate physical RAM for emulated computer.\n");
		exit(1);
	}

	for(n = 0; n < MAX_DEVS; n++) {
		as->writers[n] = address_space_no_writer;
		as->readers[n] = address_space_no_reader;
	}
	as->readers[15] = address_space_rom_reader;
	as->writers[0] = address_space_ram_writer;
	as->readers[0] = address_space_ram_reader;
	as->writers[14] = address_space_uart_writer;
	as->readers[14] = address_space_uart_reader;

	for(n = 0; n < MAX_DEVS; n++) {
		assert(as->writers[n]);
		assert(as->readers[n]);
	}
	assert(as->rom);
	assert(as->ram);
	return as;
}

int address_space_valid_card(DWORD address) {
	int card = (address & CARD_MASK) >> 60;
	int element = 1 << card;
	return (element & 0x8003) != 0;		// Cards 0, 1, and 15 are valid.
}

void address_space_store_byte(AddressSpace *as, DWORD address, BYTE datum) {
	int dev = (address & DEV_MASK) >> 56;
	if(!address_space_valid_card(address)) {
		fprintf(stderr, "Warning: attempt to write to %016llX.\n", address);
		return;
	}
	assert(as->writers);
	assert(as->writers[dev]);
	as->writers[dev](as, address, datum, 0);
}


void address_space_store_hword(AddressSpace *as, DWORD address, UHWORD datum) {
	int dev = (address & DEV_MASK) >> 56;
	if(!address_space_valid_card(address)) {
		fprintf(stderr, "Warning: attempt to write to %016llX.\n", address);
		return;
	}
	assert(as->writers);
	assert(as->writers[dev]);
	as->writers[dev](as, address, datum, 1);
}


void address_space_store_word(AddressSpace *as, DWORD address, UWORD datum) {
	int dev = (address & DEV_MASK) >> 56;
	if(!address_space_valid_card(address)) {
		fprintf(stderr, "Warning: attempt to write to %016llX.\n", address);
		return;
	}
	assert(as->writers);
	assert(as->writers[dev]);
	as->writers[dev](as, address, datum, 2);
}


void address_space_store_dword(AddressSpace *as, DWORD address, UDWORD datum) {
	int dev = (address & DEV_MASK) >> 56;
	if(!address_space_valid_card(address)) {
		fprintf(stderr, "Warning: attempt to write to %016llX.\n", address);
		return;
	}
	assert(as->writers);
	assert(as->writers[dev]);
	as->writers[dev](as, address, datum, 3);
}


BYTE address_space_fetch_byte(AddressSpace *as, DWORD address) {
	int dev = (address & DEV_MASK) >> 56;
	if(!address_space_valid_card(address)) {
		fprintf(stderr, "Warning: attempt to read from %016llX; returning 0xCC\n", address);
		return 0xCC;
	}
	assert(as->readers);
	assert(as->readers[dev]);
	return as->readers[dev](as, address, 0);
}


HWORD address_space_fetch_hword(AddressSpace *as, DWORD address) {
	int dev = (address & DEV_MASK) >> 56;
	if(!address_space_valid_card(address)) {
		fprintf(stderr, "Warning: attempt to read from %016llX; returning 0xCCCC\n", address);
		return 0xCCCC;
	}
	assert(as->readers);
	assert(as->readers[dev]);
	return as->readers[dev](as, address, 1);
}


WORD address_space_fetch_word(AddressSpace *as, DWORD address) {
	int dev = (address & DEV_MASK) >> 56;
	if(!address_space_valid_card(address)) {
		fprintf(stderr, "Warning: attempt to read from %016llX; returning 0xCCCCCCCC\n", address);
		return 0xCCCCCCCC;
	}
	assert(as->readers);
	assert(as->readers[dev]);
	return as->readers[dev](as, address, 2);
}


DWORD address_space_fetch_dword(AddressSpace *as, DWORD address) {
	int dev = (address & DEV_MASK) >> 56;
	if(!address_space_valid_card(address)) {
		fprintf(stderr, "Warning: attempt to read from %016llX; returning 0xCCCCCCCCCCCCCCCC\n", address);
		return 0xCCCCCCCCCCCCCCCC;
	}
	assert(as->readers);
	assert(as->readers[dev]);
	return as->readers[dev](as, address, 3);
}


Options *options_new() {
	Options *opts = (Options *)malloc(sizeof(Options));
	if(opts) {
		memset(opts, 0, sizeof(Options));
	}
	return opts;
}


Options *options_get(int argc, char *argv[]) {
	Options *opts = options_new();
	int i = 1;

	for(;;) {
		if(i >= (argc - 1)) break;

		if(!strcmp(argv[i], "romfile")) {
			opts->romFilename = argv[i+1];
			i = i + 2;
		} else {
			fprintf(stderr, "Warning: unknown option %s\n", argv[i]);
			i++;
		}
	}

	return opts;
}


Processor *processor_new(AddressSpace *as) {
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


DWORD processor_getCSR(Processor *p, int csr) {
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


void processor_setCSR(Processor *p, int csr, DWORD v) {
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


void processor_orCSR(Processor *p, int csr, DWORD v) {
	processor_setCSR(p, csr, v | processor_getCSR(p, csr));
}


void processor_andCSR(Processor *p, int csr, DWORD v) {
	processor_setCSR(p, csr, v & processor_getCSR(p, csr));
}


void processor_trap(Processor *p, int cause) {
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


void processor_ecall(Processor *p) {
	processor_trap(p, 8 + ((p->csr[i_MSTATUS] & 6) >> 1));
}


void processor_eret(Processor *p) {
	UDWORD privStack = ((p->csr[i_MSTATUS] & 0xFF8) >> 3) | 0x206;	// 0x206 vs 0x200 b/c we only support M-mode.
	p->csr[i_MSTATUS] = (p->csr[i_MSTATUS] & -0x1000) | privStack;
	p->pc = p->csr[i_MEPC];
}

void processor_step(Processor *p) {
	WORD ir;
	int opc, rd, fn3, rs1, rs2, imm12, imm12s, disp12;
	DWORD imm20, disp20, ia;

	if(!p->running) return;

	ia = p->pc;
	ir = address_space_fetch_word(p->as, ia);
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
					fprintf(stderr, "$%016llX  B??.%d X%d, X%d, %d", p->pc, fn3, rs1, rs2, disp12);
					p->running = 0;
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
					p->x[rd] = address_space_fetch_byte(p->as, p->x[rs1] + imm12);
					p->x[rd] |= -(p->x[rd] & 0x80);
					break;

				case 1: // LH
					p->x[rd] = address_space_fetch_hword(p->as, p->x[rs1] + imm12);
					p->x[rd] |= -(p->x[rd] & 0x8000);
					break;

				case 2: // LW
					p->x[rd] = address_space_fetch_word(p->as, p->x[rs1] + imm12);
					p->x[rd] |= -(p->x[rd] & 0x80000000);
					break;

				case 3: // LD
					p->x[rd] = address_space_fetch_dword(p->as, p->x[rs1] + imm12);
					// p->x[rd] |= -(p->x[rd] & 0x8000000000000000);
					break;

				case 4: // LBU
					p->x[rd] = address_space_fetch_byte(p->as, p->x[rs1] + imm12);
					break;

				case 5: // LHU
					p->x[rd] = address_space_fetch_hword(p->as, p->x[rs1] + imm12);
					break;

				case 6: // LWU
					p->x[rd] = address_space_fetch_word(p->as, p->x[rs1] + imm12);
					break;

				case 7: // LDU
					p->x[rd] = address_space_fetch_dword(p->as, p->x[rs1] + imm12);
					break;
			}
			break;
		// Sx
		case 0x23:
			switch(fn3) {
				case 0: // SB
					address_space_store_byte(p->as, p->x[rs1]+imm12s, p->x[rs2]);
					break;

				case 1: // SH
					address_space_store_hword(p->as, p->x[rs1]+imm12s, p->x[rs2]);
					break;

				case 2: // SW
					address_space_store_word(p->as, p->x[rs1]+imm12s, p->x[rs2]);
					break;

				case 3: // SD
					address_space_store_dword(p->as, p->x[rs1]+imm12s, p->x[rs2]);
					break;

				default:
					processor_trap(p, 2);
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
				p->x[rd] = p->x[rd] << imm12;
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
				p->x[rd] = processor_getCSR(p, imm12);
			} else {
				switch(imm12) {
				case 0x000:		// ECALL
					processor_ecall(p);
					break;

				case 0x001:		// EBREAK
					processor_trap(p, 3);
					break;

				case 0x100:		// ERET
					processor_eret(p);
					break;

				case 0x102:		// WFI == NOP for now.
					break;

				case 0x305:		// MRTS
				case 0x306:		// MRTH
				case 0x205:		// HRTS
				case 0x101:		// VMFENCE (aka FENCE.VM)
				default:
					processor_trap(p, 2);
				};
				break;
			}

			if(rs1) {
				switch(fn3) {
				case 1: // CSRRW
					processor_setCSR(p, imm12, p->x[rs1]);
					break;

				case 2: // CSRRS
					processor_orCSR(p, imm12, p->x[rs1]);
					break;

				case 3: // CSRRC
					processor_andCSR(p, imm12, ~(p->x[rs1]));
					break;

				case 4: // undefined
					processor_trap(p, 2);
					break;

				case 5: // CSRRW
					processor_setCSR(p, imm12, rs1);
					break;

				case 6: // CSRRS
					processor_orCSR(p, imm12, rs1);
					break;

				case 7: // CSRRC
					processor_andCSR(p, imm12, ~rs1);
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
			processor_trap(p, 2);
	}

	p->x[0] = 0;
}


int run(int argc, char *argv[]) {
	Options *opts = NULL;
	AddressSpace *as = NULL;
	Processor *p = NULL;

	printf("This is e, the Polaris 64-bit RISC-V architecture emulator.\n");
	printf("Version %d.%d.%d.\n", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
	opts = options_get(argc, argv);
	as = address_space_configure(opts);
	p = processor_new(as);

	while(p->running) {
		processor_step(p);
	}

	return 0;
}


int main(int argc, char *argv[]) {
	int result;

	console_1char_mode();
	result = run(argc, argv);
	console_line_mode();
	return result;
}

