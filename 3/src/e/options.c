#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "options.h"


static Options *
_new() {
	Options *opts = (Options *)malloc(sizeof(Options));
	if(opts) {
		memset(opts, 0, sizeof(Options));
	}
	return opts;
}


static Options *
make(int argc, char *argv[]) {
	Options *opts = _new();
	int i = 1;

	for(;;) {
		if(i >= (argc - 1)) break;

		if(!strcmp(argv[i], "sdbfile")) {
			opts->sdbFilename = argv[i+1];
			i = i + 2;
		} else if(!strcmp(argv[i], "romfile")) {
			opts->romFilename = argv[i+1];
			i = i + 2;
		} else {
			fprintf(stderr, "Warning: unknown option %s\n", argv[i]);
			i++;
		}
	}

	if (!opts->romFilename) {
		opts->romFilename = "roms/forth";
	}

	return opts;
}


const struct interface_Options module_Options = {
	.make = &make,
};

