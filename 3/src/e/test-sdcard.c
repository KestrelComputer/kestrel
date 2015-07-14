#include <cut/2.7/cut.h>

#include "types.h"
#include "sdcard.h"


SDCard *sdc;

void __CUT_BRINGUP__fresh_sdcard(void) {
	sdc = sdcard_new();
}

void __CUT__ignores_command_bytes(void) {
	BYTE r = sdcard_byte(sdc, 0x40);
	ASSERT(r == -1, "Fresh card must ignore R1 commands");
}

void __CUT_TAKEDOWN__fresh_sdcard(void) {
	sdcard_dispose(sdc);
}

