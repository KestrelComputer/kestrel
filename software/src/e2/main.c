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
};


uint64_t
rom_fetch_dword(AddressSpace *as, uint64_t addr) {
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
rom_fetch_word(AddressSpace *as, uint64_t addr) {
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
}

uint16_t
rom_fetch_hword(AddressSpace *as, uint64_t addr) {
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
rom_fetch_byte(AddressSpace *as, uint64_t addr) {
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

struct IAddressSpace rom_segment_interface = {
	.fetch_dword = rom_fetch_dword,
	.fetch_word = rom_fetch_word,
	.fetch_hword = rom_fetch_hword,
	.fetch_byte = rom_fetch_byte,
	.store_dword = rom_store_dword,
	.store_word = rom_store_word,
	.store_hword = rom_store_hword,
	.store_byte = rom_store_byte,
};


uint64_t
root_fetch_dword(AddressSpace *as, uint64_t addr) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX @D\n", addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top))
		return root->rom_seg.as.i->fetch_dword(&root->rom_seg.as, addr);

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
	return 0xCCCCCCCCCCCCCCCC;
}

uint32_t
root_fetch_word(AddressSpace *as, uint64_t addr) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX @W\n", addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top))
		return root->rom_seg.as.i->fetch_word(&root->rom_seg.as, addr);

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
	return 0xCCCCCCCC;
}

uint16_t
root_fetch_hword(AddressSpace *as, uint64_t addr) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX @H\n", addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top))
		return root->rom_seg.as.i->fetch_dword(&root->rom_seg.as, addr);

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
	return 0xCCCC;
}

uint8_t
root_fetch_byte(AddressSpace *as, uint64_t addr) {
	RootAS *root = (RootAS *)as;

	fprintf(stderr, "$%016llX @B\n", addr);

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top))
		return root->rom_seg.as.i->fetch_dword(&root->rom_seg.as, addr);

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
	return 0xCC;
}

void
root_store_dword(AddressSpace *as, uint64_t addr, uint64_t datum) {
	RootAS *root = (RootAS *)as;

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top)) {
		root->rom_seg.as.i->store_dword(&root->rom_seg.as, addr, datum);
		return;
	}

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
}

void
root_store_word(AddressSpace *as, uint64_t addr, uint32_t datum) {
	RootAS *root = (RootAS *)as;

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top)) {
		root->rom_seg.as.i->store_word(&root->rom_seg.as, addr, datum);
		return;
	}

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
}

void
root_store_hword(AddressSpace *as, uint64_t addr, uint16_t datum) {
	RootAS *root = (RootAS *)as;

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top)) {
		root->rom_seg.as.i->store_hword(&root->rom_seg.as, addr, datum);
		return;
	}

	fprintf(stderr, "TODO: raise access error trap to CPU\n");
}

void
root_store_byte(AddressSpace *as, uint64_t addr, uint8_t datum) {
	RootAS *root = (RootAS *)as;

	if((root->rom_seg.bottom <= addr) && (addr < root->rom_seg.top)) {
		root->rom_seg.as.i->store_byte(&root->rom_seg.as, addr, datum);
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
		free(ras);
	}
}

RootAS *
new_root_address_space(void) {
	RootAS *ras = (RootAS *)(malloc(sizeof(RootAS)));
	if(ras) {
		memset(ras, 0, sizeof(RootAS));
		ras->as.i = &root_interface;

		ras->rom_seg.as.i = &rom_segment_interface;
		ras->rom_seg.bottom = 0x0000000000000000;
		ras->rom_seg.top = 0x0000000000100000;
		ras->rom_seg.image = malloc(ras->rom_seg.top - ras->rom_seg.bottom);
		if(!ras->rom_seg.image) {
			fprintf(stderr, "cannot allocate 1MB ROM image\n");
			dispose_root_address_space(ras);
			return NULL;
		}
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

	p->pc = 0;	// KCP53000B cold-starts at address 0.

	while(1) {
		step(p);
	}
}

