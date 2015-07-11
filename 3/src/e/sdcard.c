#include <stdio.h>

#include "types.h"
#include "sdcard.h"


#define R1(x) ((DWORD)(x) << 40)


static DWORD handle_command(int, WORD);


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
		result = handle_command(
			(cmdPacket >> 40) & 0xFF,
			(cmdPacket >> 8) & 0xFFFFFFFF
		);
		cmdPacket = -1;
	}
}


static DWORD
handle_command(int cmd, WORD address) {
	fprintf(stderr, "Command $%02X Address $%08lX\n", cmd, address);
	return R1(0x4A);
}

