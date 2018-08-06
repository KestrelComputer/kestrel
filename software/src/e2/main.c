#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "processor.h"


typedef struct RootAS RootAS;
typedef struct Segment Segment;

struct Segment {
	AddressSpace	as;
	uint64_t	bottom, top;
	uint8_t		*image;
};

struct RootAS {
	AddressSpace	as;
	Segment		rom_seg;
	Segment		ram_seg;
	Segment		sia1;
};


uint8_t
sia1_fetch_byte(AddressSpace *as, uint64_t addr) {
	/* Emulator has no read registers yet. */
	return 0xCC;
}

uint16_t
sia1_fetch_hword(AddressSpace *as, uint64_t addr) {
	if(addr & 1) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return 0xCCCC;
	}
	return (
		(uint8_t)(sia1_fetch_byte(as, addr))
	|	(uint8_t)(sia1_fetch_byte(as, addr+1) << 8)
	);
}

uint32_t
sia1_fetch_word(AddressSpace *as, uint64_t addr) {
	if(addr & 3) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return 0xCCCCCCCC;
	}
	return (
		(uint32_t)(sia1_fetch_hword(as, addr))
	|	(uint32_t)(sia1_fetch_hword(as, addr+2) << 16)
	);
}

uint64_t
sia1_fetch_dword(AddressSpace *as, uint64_t addr) {
	if(addr & 7) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return 0xCCCCCCCCCCCCCCCC;
	}
	return (
		(uint64_t)(sia1_fetch_word(as, addr))
	|	((uint64_t)(sia1_fetch_word(as, addr+4)) << 32)
	);
}

void
sia1_store_byte(AddressSpace *as, uint64_t addr, uint8_t datum) {
	if(addr == 0) {
		fprintf(stdout, "%c", datum);
	}
}

void
sia1_store_hword(AddressSpace *as, uint64_t addr, uint16_t datum) {
	if(addr & 1) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return;
	}
	
	sia1_store_byte(as, addr, (uint16_t)datum);
	sia1_store_byte(as, addr+1, (uint16_t)datum >> 8);
}

void
sia1_store_word(AddressSpace *as, uint64_t addr, uint32_t datum) {
	if(addr & 3) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return;
	}
	
	sia1_store_hword(as, addr, (uint16_t)datum);
	sia1_store_hword(as, addr+2, (uint16_t)datum >> 16);
}

void
sia1_store_dword(AddressSpace *as, uint64_t addr, uint64_t datum) {
	if(addr & 7) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return;
	}
	
	sia1_store_word(as, addr, (uint32_t)datum);
	sia1_store_word(as, addr+4, (uint32_t)(datum >> 32));
}

struct IAddressSpace sia1_interface = {
	.fetch_dword = sia1_fetch_dword,
	.fetch_word = sia1_fetch_word,
	.fetch_hword = sia1_fetch_hword,
	.fetch_byte = sia1_fetch_byte,
	.store_dword = sia1_store_dword,
	.store_word = sia1_store_word,
	.store_hword = sia1_store_hword,
	.store_byte = sia1_store_byte,
};


uint64_t
mem_fetch_dword(AddressSpace *as, uint64_t addr) {
	Segment *s = (Segment *)as;
	int i;

	if(addr & 7) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return 0xCCCCCCCCCCCCCCCC;
	}
	
	i = (int)(addr - s->bottom);
	return (
		(uint64_t)(s->image[i])
	|	(((uint64_t)(s->image[i+1])) << 8)
	|	(((uint64_t)(s->image[i+2])) << 16)
	|	(((uint64_t)(s->image[i+3])) << 24)
	|	(((uint64_t)(s->image[i+4])) << 32)
	|	(((uint64_t)(s->image[i+5])) << 40)
	|	(((uint64_t)(s->image[i+6])) << 48)
	|	(((uint64_t)(s->image[i+7])) << 56)
	);
}

uint32_t
mem_fetch_word(AddressSpace *as, uint64_t addr) {
	Segment *s = (Segment *)as;
	int i;

	if(addr & 3) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return 0xCCCCCCCC;
	}
	
	i = (int)(addr - s->bottom);
	return (
		s->image[i]
	|	(s->image[i+1] << 8)
	|	(s->image[i+2] << 16)
	|	(s->image[i+3] << 24)
	);
};


uint16_t
mem_fetch_hword(AddressSpace *as, uint64_t addr) {
	Segment *s = (Segment *)as;
	int i;

	if(addr & 1) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
		return 0xCCCC;
	}
	
	i = (int)(addr - s->bottom);
	return (
		s->image[i]
	|	(s->image[i+1] << 8)
	);
}

uint8_t
mem_fetch_byte(AddressSpace *as, uint64_t addr) {
	Segment *s = (Segment *)as;
	int i;

	i = (int)(addr - s->bottom);
	return s->image[i];
}

void
rom_store_dword(AddressSpace *as, uint64_t addr, uint64_t datum) {
	if(addr & 7) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
	}
	/* Do nothing, for we are ROM. */
}

void
rom_store_word(AddressSpace *as, uint64_t addr, uint32_t datum) {
	if(addr & 3) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
	}
	/* Do nothing, for we are ROM. */
}

void
rom_store_hword(AddressSpace *as, uint64_t addr, uint16_t datum) {
	if(addr & 1) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
	}
	/* Do nothing, for we are ROM. */
}

void
rom_store_byte(AddressSpace *as, uint64_t addr, uint8_t datum) {
	/* Do nothing, for we are ROM. */
}

void
ram_store_dword(AddressSpace *as, uint64_t addr, uint64_t datum) {
	Segment *s = (Segment *)as;
	int i;

	if(addr & 7) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
	}

	i = (int)(addr - s->bottom);
	s->image[i] = (uint8_t)(datum & 0xFF);
	s->image[i+1] = (uint8_t)((datum >> 8) & 0xFF);
	s->image[i+2] = (uint8_t)((datum >> 16) & 0xFF);
	s->image[i+3] = (uint8_t)((datum >> 24) & 0xFF);
	s->image[i+4] = (uint8_t)((datum >> 32) & 0xFF);
	s->image[i+5] = (uint8_t)((datum >> 40) & 0xFF);
	s->image[i+6] = (uint8_t)((datum >> 48) & 0xFF);
	s->image[i+7] = (uint8_t)((datum >> 56) & 0xFF);
}

void
ram_store_word(AddressSpace *as, uint64_t addr, uint32_t datum) {
	Segment *s = (Segment *)as;
	int i;

	if(addr & 3) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
	}

	i = (int)(addr - s->bottom);
	s->image[i] = (uint8_t)(datum & 0xFF);
	s->image[i+1] = (uint8_t)((datum >> 8) & 0xFF);
	s->image[i+2] = (uint8_t)((datum >> 16) & 0xFF);
	s->image[i+3] = (uint8_t)((datum >> 24) & 0xFF);
}

void
ram_store_hword(AddressSpace *as, uint64_t addr, uint16_t datum) {
	Segment *s = (Segment *)as;
	int i;

	if(addr & 1) {
		fprintf(stderr, "TODO: raise a misalignment trap to the processor\n");
	}

	i = (int)(addr - s->bottom);
	s->image[i] = (uint8_t)(datum & 0xFF);
	s->image[i+1] = (uint8_t)((datum >> 8) & 0xFF);
}

void
ram_store_byte(AddressSpace *as, uint64_t addr, uint8_t datum) {
	Segment *s = (Segment *)as;
	int i;

	i = (int)(addr - s->bottom);
	s->image[i] = datum;
}

struct IAddressSpace rom_segment_interface = {
	.fetch_dword = mem_fetch_dword,
	.fetch_word = mem_fetch_word,
	.fetch_hword = mem_fetch_hword,
	.fetch_byte = mem_fetch_byte,
	.store_dword = rom_store_dword,
	.store_word = rom_store_word,
	.store_hword = rom_store_hword,
	.store_byte = rom_store_byte,
};


struct IAddressSpace ram_segment_interface = {
	.fetch_dword = mem_fetch_dword,
	.fetch_word = mem_fetch_word,
	.fetch_hword = mem_fetch_hword,
	.fetch_byte = mem_fetch_byte,
	.store_dword = ram_store_dword,
	.store_word = ram_store_word,
	.store_hword = ram_store_hword,
	.store_byte = ram_store_byte,
};


uint64_t
root_fetch_dword(AddressSpace *as, uint64_t addr) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX @D\n", addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top))
		return root->rom_seg.as.i->fetch_dword(&root->rom_seg.as, addr);

	if((root->ram_seg.bottom <= addr) && (addr < root->ram_seg.top))
		return root->ram_seg.as.i->fetch_dword(&root->ram_seg.as, addr);

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
	return 0xCCCCCCCCCCCCCCCC;
}

uint32_t
root_fetch_word(AddressSpace *as, uint64_t addr) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX @W\n", addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top))
		return root->rom_seg.as.i->fetch_word(&root->rom_seg.as, addr);

	if((root->ram_seg.bottom <= addr) && (addr < root->ram_seg.top))
		return root->ram_seg.as.i->fetch_word(&root->ram_seg.as, addr);

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
	return 0xCCCCCCCC;
}

uint16_t
root_fetch_hword(AddressSpace *as, uint64_t addr) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX @H\n", addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top))
		return root->rom_seg.as.i->fetch_hword(&root->rom_seg.as, addr);

	if((root->ram_seg.bottom <= addr) && (addr < root->ram_seg.top))
		return root->ram_seg.as.i->fetch_hword(&root->ram_seg.as, addr);

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
	return 0xCCCC;
}

uint8_t
root_fetch_byte(AddressSpace *as, uint64_t addr) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX @B\n", addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top))
		return root->rom_seg.as.i->fetch_byte(&root->rom_seg.as, addr);

	if((root->ram_seg.bottom <= addr) && (addr < root->ram_seg.top))
		return root->ram_seg.as.i->fetch_byte(&root->ram_seg.as, addr);

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
	return 0xCC;
}

void
root_store_dword(AddressSpace *as, uint64_t addr, uint64_t datum) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX $%016llX !D\n", datum, addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top)) {
		root->rom_seg.as.i->store_dword(&root->rom_seg.as, addr, datum);
		return;
	}

	if((root->ram_seg.bottom <= addr) && (addr < root->ram_seg.top)) {
		root->ram_seg.as.i->store_dword(&root->ram_seg.as, addr, datum);
		return;
	}

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
}

void
root_store_word(AddressSpace *as, uint64_t addr, uint32_t datum) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%08lX $%016llX !W\n", datum, addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top)) {
		root->rom_seg.as.i->store_word(&root->rom_seg.as, addr, datum);
		return;
	}

	if((root->ram_seg.bottom <= addr) && (addr < root->ram_seg.top)) {
		root->ram_seg.as.i->store_word(&root->ram_seg.as, addr, datum);
		return;
	}

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
}

void
root_store_hword(AddressSpace *as, uint64_t addr, uint16_t datum) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%04X $%016llX !H\n", datum, addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top)) {
		root->rom_seg.as.i->store_hword(&root->rom_seg.as, addr, datum);
		return;
	}

	if((root->ram_seg.bottom <= addr) && (addr < root->ram_seg.top)) {
		root->ram_seg.as.i->store_hword(&root->ram_seg.as, addr, datum);
		return;
	}

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
}

void
root_store_byte(AddressSpace *as, uint64_t addr, uint8_t datum) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%02X $%016llX !B\n", datum, addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top)) {
		root->rom_seg.as.i->store_byte(&root->rom_seg.as, addr, datum);
		return;
	}

	if((root->ram_seg.bottom <= addr) && (addr < root->ram_seg.top)) {
		root->ram_seg.as.i->store_byte(&root->ram_seg.as, addr, datum);
		return;
	}

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
}

struct IAddressSpace root_interface = {
	.fetch_dword = root_fetch_dword,
	.fetch_word = root_fetch_word,
	.fetch_hword = root_fetch_hword,
	.fetch_byte = root_fetch_byte,
	.store_dword = root_store_dword,
	.store_word = root_store_word,
	.store_hword = root_store_hword,
	.store_byte = root_store_byte,
};

void
dispose_root_address_space(RootAS *ras) {
	if(ras) {
		if(ras->rom_seg.image) free(ras->rom_seg.image);
		if(ras->ram_seg.image) free(ras->ram_seg.image);
		free(ras);
	}
}

RootAS *
new_root_address_space(void) {
	RootAS *ras = (RootAS *)(malloc(sizeof(RootAS)));
	FILE *fh;
	size_t size, actual;

	if(ras) {
		memset(ras, 0, sizeof(RootAS));
		ras->as.i = &root_interface;

		ras->rom_seg.as.i = &rom_segment_interface;
		ras->rom_seg.bottom = 0x0000000000000000;
		ras->rom_seg.top = 0x0000000000100000;
		size = ras->rom_seg.top - ras->rom_seg.bottom;
		ras->rom_seg.image = malloc(size);
		if(!ras->rom_seg.image) {
			fprintf(stderr, "cannot allocate 1MB ROM image\n");
			dispose_root_address_space(ras);
			return NULL;
		}
		memset(ras->rom_seg.image, 0xAA, size);
		fh = fopen("rom-image.bin", "rb");
		if(!fh) {
			fprintf(stderr, "cannot read rom-image.bin\n");
			dispose_root_address_space(ras);
			return NULL;
		}
		actual = fread(ras->rom_seg.image, 1, size, fh);
		if(actual < size) {
			fprintf(stderr, "WARNING: Expected %d byte file, but got %d.\n", size, actual);
		}
		fclose(fh);

		ras->ram_seg.as.i = &ram_segment_interface;
		ras->ram_seg.bottom = 0x0000000040000000;
		ras->ram_seg.top = 0x0000000040100000;
		ras->ram_seg.image = malloc(ras->ram_seg.top - ras->ram_seg.bottom);
		if(!ras->ram_seg.image) {
			fprintf(stderr, "cannot allocate 1MB RAM image\n");
			dispose_root_address_space(ras);
			return NULL;
		}

		ras->sia1.as.i = &sia1_interface;
		ras->sia1.bottom = 0xFFFFFFFFFFFFF000;
		ras->sia1.top = 0xFFFFFFFFFFFFF001;
	}
	return ras;
}


int
main(int argc, char *argv[]) {
	Processor *p;
	RootAS *root_as;

	root_as = new_root_address_space();
	if(!root_as) {
		fprintf(stderr, "cannot create root address space.\n");
		exit(1);
	}

	p = new_processor(&root_as->as);
	if(!p) {
		fprintf(stderr, "cannot create processor.\n");
		exit(1);
	}

	p->pc = 0;		// KCP53000B cold-starts at address 0.
	p->mtvec = 0x100;	// KCP53000B traps by default to 0x100.

	while(1) {
		step(p);
	}
}

