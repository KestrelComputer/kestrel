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

	if((cmdPacket & 0xC00000000001) == 0x400000000001) {
		result = handle_command(
			(cmdPacket >> 40) & 0xFF,
			(cmdPacket >> 8) & 0xFFFFFFFF
		);
		cmdPacket = -1;
	}
}


#define APPCMD_PREFIX	0x100

static DWORD
handle_command(int cmd, WORD address) {
	static int acmdPrefix = 0;
	static DWORD result;
	static int blockSize;

	fprintf(stderr, "Command $%03X Address $%08lX\n", cmd | acmdPrefix, address);
	switch(cmd | acmdPrefix) {
		case SDCMD_GO_IDLE_STATE:
			fprintf(stderr, "SD: going idle\n");
			blockSize = 1024;
			result = R1(0x01);
			break;

		case SDCMD_APP_CMD:
			acmdPrefix = APPCMD_PREFIX;
			// We return here instead of break, because we don't
			// want the remainder of the code to reset our freshly
			// set acmdPrefix setting.
			return R1(result);

		case APPCMD_PREFIX | SDCMD_SEND_OP_COND:
			fprintf(stderr, "SD: going operational\n");
			result = R1(0x00);
			break;

		case SDCMD_SET_BLKLEN:
			fprintf(stderr, "SD: Changing block size from %d to %ld", blockSize, address);
			blockSize = address;
			break;

		default:
			fprintf(stderr, "SD: $%02X, $%08lX: Illegal command\n", cmd, address);
			result = R1(0x05);
			break;
	}

	acmdPrefix = 0;
	return result;
}

