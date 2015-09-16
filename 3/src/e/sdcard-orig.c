#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include "types.h"
#include "sdcard.h"


#define R3(x,y)	(((DWORD)(x) << 32) | ((WORD)y) | 0xFFFFFF0000000000)
#define R1(x)	(R3(x, 0xFFFFFFFF))

#define SDCARD_IMG_FILE		"sdcard.sdc"


static DWORD handle_command(int, WORD);

static int offset;
static int bytesLeft;

#define BUFSIZE 3172
static BYTE buffer[BUFSIZE];


void
handle_spi(void) {
	static int previouslySelected = 0;
	static DWORD cmdPacket;
	static DWORD result;
	static int bits = 0;

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
		gpia_in |= (result >> 37) & 4;
		result = (result << 1) | 1;
		cmdPacket <<= 1;
		cmdPacket |= (gpia_out & GPIA_OUT_SD_MOSI) >> 2;
		bits++;
		fprintf(stderr, "BIT: %d BYTESLEFT: %d\n", bits, bytesLeft);
		if(bytesLeft && (bits == 8)) {
			result = R1(buffer[offset]);
			offset++;
			bytesLeft--;
		}
		if(bits >= 8) {
			bits = 0;
		}
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
	int fh;
  int n;

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

		case SDCMD_READ_BLOCK:
			fprintf(stderr, "SD: Reading from block %ld (offset $%08lX)\n", address >> 9, address & 0x1FF);
			result = -1;
			memset(buffer, 0xFF, BUFSIZE);
			buffer[0] = 0x00;
			offset = 0;

			fh = open(SDCARD_IMG_FILE, O_RDONLY);
			if(fh < 0) {
				bytesLeft = 6;
				buffer[5] = 0x05;
				break;
			}
			buffer[5] = 0xFE;
			lseek(fh, address, SEEK_SET);
			n = read(fh, &buffer[6], blockSize);
			fprintf(stderr, "N=%d\n", n);
			if(n < blockSize) {
				fprintf(stderr, "ERRNO=%d", errno);
				bytesLeft = 6;
				buffer[5] = 0x09;
				break;
			}
			close(fh);
			bytesLeft = 8 + blockSize;
			break;

		default:
			fprintf(stderr, "SD: $%02X, $%08lX: Illegal command\n", cmd, address);
			result = R1(0x05);
			break;
	}

	acmdPrefix = 0;
	return result;
}

