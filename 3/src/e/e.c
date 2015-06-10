/* vim: set noet ts=8 sw=8: */


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <termios.h>
#include <unistd.h>

#include "types.h"
#include "config.h"
#include "options.h"
#include "address_space.h"
#include "processor.h"

extern const struct interface_AddressSpace module_AddressSpace;
static const struct interface_AddressSpace const *as = &module_AddressSpace;

extern const struct interface_Processor module_Processor;
static const struct interface_Processor *pp = &module_Processor;

extern const struct interface_Options module_Options;
static const struct interface_Options *oo = &module_Options;

static struct termios stored_settings;


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



int run(int argc, char *argv[]) {
	Processor *p = NULL;

	printf("This is e, the Polaris 64-bit RISC-V architecture emulator.\n");
	printf("Version %d.%d.%d.\n", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
	p = pp->make(as->make(oo->make(argc, argv)));

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

