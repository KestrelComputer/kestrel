#include <stdio.h>

#include "types.h"
#include "sdcard.h"


#define R1(x) ((DWORD)(x) << 40)

void
handle_spi(void) {
	static int previouslySelected = 0;
	static DWORD cmdPacket;
	static DWORD result;

	if(gpia_out & GPIA_OUT_SD_SS) {
		previouslySelected = 0;
		return;
	}

	if(!previouslySelected && ((gpia_out & GPIA_OUT_SD_SS) == 0)) {
		previouslySelected = 1;
		cmdPacket = -1;
		result = -1;
	}

	if((gpia_out & GPIA_OUT_SD_CLK)) {
		gpia_in &= 0xFFFFFFFFFFFFFFFB;
		gpia_in |= (result >> 45) & 4;
		result <<= 1;
		cmdPacket <<= 1;
		cmdPacket |= (gpia_out & GPIA_OUT_SD_MOSI) >> 2;
	}

	if((cmdPacket & 0xC00000000000) == 0x400000000000) {
		fprintf(stderr, "Command received: $%016llX\n", cmdPacket);
		cmdPacket = -1;
    result = R1(0x4A);  /* Some random looking code */
	}
}

