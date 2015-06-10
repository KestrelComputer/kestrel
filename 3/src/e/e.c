/* vim: set noet ts=8 sw=8: */


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <termios.h>
#include <unistd.h>

#include "types.h"
#include "config.h"


static struct termios stored_settings;


#include "options.h"
#include "address_space.h"
#include "processor.h"


extern const struct interface_AddressSpace module_AddressSpace;
static const struct interface_AddressSpace const *as = &module_AddressSpace;

extern const struct interface_Processor module_Processor;
static const struct interface_Processor *pp = &module_Processor;


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


int run(int argc, char *argv[]) {
	Options *opts = NULL;
	Processor *p = NULL;

	printf("This is e, the Polaris 64-bit RISC-V architecture emulator.\n");
	printf("Version %d.%d.%d.\n", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
	opts = options_get(argc, argv);
	p = pp->make(as->make(opts));

	while(p->running) {
		pp->step(p);
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

