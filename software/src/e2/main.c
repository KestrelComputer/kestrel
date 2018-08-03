#include <stdlib.h>
#include <stdio.h>

#include "processor.h"


uint32_t
my_fetch_word(AddressSpace *as, uint64_t addr) {
	fprintf(stderr, "A=$%016llX\n", addr);
	return 0xCCCCCCCC;
}

int
main(int argc, char *argv[]) {
	Processor *p;
	IAddressSpace my_ias = {
		.fetch_word = &my_fetch_word,
	};

	AddressSpace as = { &my_ias, };

	p = new_processor(&as);
	if(!p) {
		fprintf(stderr, "cannot create processor.\n");
		exit(1);
	}

	while(1) {
		step(p);
	}
}

