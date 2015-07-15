#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#include "types.h"
#include "sdcard.h"


static void sdcard_default_handler(SDCard *);
static void sdcard_do_read_block(SDCard *);
static void sdcard_do_write_block(SDCard *);
static void sdcard_do_write_block_2nd(SDCard *);


void
sdcard_reset(SDCard *sdc) {
	memset(sdc, 0, sizeof(SDCard));
	sdc->cmd_handler = &sdcard_default_handler;
	sdc->cmd_length = 6;
	sdc->blockLength = 1024;
}


SDCard *
sdcard_new(void) {
	SDCard *sdc = malloc(sizeof(SDCard));
	if(sdc) sdcard_reset(sdc);
	return sdc;
}


void
sdcard_dispose(SDCard *sdc) {
	if(sdc) free(sdc);
}


int
sdcard_response_empty(SDCard *sdc) {
	return sdc->response_rd == sdc->response_wr;
}


BYTE
sdcard_dequeue(SDCard *sdc) {
	BYTE b;
	if(sdcard_response_empty(sdc)) {
		return -1;
	}
	b = sdc->response[sdc->response_rd];
	sdc->response_rd = (sdc->response_rd + 1) % SDBUF_SIZE;
	return b;
}


void
sdcard_enqueue_response(SDCard *sdc, BYTE b) {
	sdc->response[sdc->response_wr] = b;
	sdc->response_wr = (sdc->response_wr + 1) % SDBUF_SIZE;
}


BYTE
sdcard_byte(SDCard *sdc, BYTE input) {
	BYTE b;

	if(!sdc->selected) return -1;

	b = sdcard_dequeue(sdc);
	if((input == -1) && (sdc->cmd_index == 0)) return b;

	sdc->command[sdc->cmd_index] = input;
	sdc->cmd_index++;

	if(sdc->cmd_index >= sdc->cmd_length) {
		sdc->cmd_handler(sdc);
		sdc->cmd_index = 0;
	}

	return b;
}


void
sdcard_select(SDCard *sdc) {
	sdcard_reset(sdc);
	sdc->selected = 1;
}


static void
sdcard_default_handler(SDCard *sdc) {
	int nextPrefix = 0;
	WORD param = ((WORD)sdc->command[1] << 24) | ((WORD)sdc->command[2] << 16) | ((WORD)sdc->command[3] << 8) | (WORD)sdc->command[4];

	switch((sdc->command[0]) & 0x3F) {
		case SDCMD_GO_IDLE_STATE:
			sdcard_enqueue_response(sdc, 0x01);
			break;

		case SDCMD_APP_CMD:
			sdcard_enqueue_response(sdc, 0x01);
			nextPrefix = 1;
			break;

		case SDCMD_SEND_OP_COND:
			sdcard_enqueue_response(sdc, (sdc->acmdPrefix)?0:5);
			break;

		case SDCMD_SET_BLKLEN:
			sdc->blockLength = param;
			sdcard_enqueue_response(sdc, 0x00);
			break;

		case SDCMD_READ_BLOCK:
			sdcard_do_read_block(sdc);
			break;

		case SDCMD_WRITE_BLOCK:
			sdcard_do_write_block(sdc);
			break;

		default:
			sdcard_enqueue_response(sdc, 0x05);
			break;
	}
	sdc->acmdPrefix = nextPrefix;
}


static void
sdcard_do_read_block(SDCard *sdc) {
	int i, h;
	BYTE buf[2048];

	WORD addr =	(((WORD)sdc->command[1] & 0xFF) << 24) |
			(((WORD)sdc->command[2] & 0xFF) << 16) |
			(((WORD)sdc->command[3] & 0xFF) << 8) |
			(((WORD)sdc->command[4] & 0xFF));

	/* Limiting to 1GB for now. */
	if(addr >= (1024*1048576)) {
		sdcard_enqueue_response(sdc, 0x20);
		return;
	}

	sdcard_enqueue_response(sdc, 0x00);
	sdcard_enqueue_response(sdc, 0xFF);

	h = open("sdcard.sdc", O_RDONLY);
	if(h < 0) {
		sdcard_enqueue_response(sdc, 0x05);
		return;
	}

	lseek(h, addr, SEEK_SET);
	read(h, buf, sdc->blockLength);
	close(h);

	sdcard_enqueue_response(sdc, 0xFE);
	for(i = 0; i < sdc->blockLength; i++) {
		sdcard_enqueue_response(sdc, buf[i]);
	}
	sdcard_enqueue_response(sdc, 0x01);	/* fake CRC */
	sdcard_enqueue_response(sdc, 0x01);
}

static void
sdcard_do_write_block(SDCard *sdc) {
	WORD addr =	(((WORD)sdc->command[1] & 0xFF) << 24) |
			(((WORD)sdc->command[2] & 0xFF) << 16) |
			(((WORD)sdc->command[3] & 0xFF) << 8) |
			(((WORD)sdc->command[4] & 0xFF));

	/* Limiting to 1GB for now. */
	if(addr >= (1024*1048576)) {
		sdcard_enqueue_response(sdc, 0x20);
		return;
	}

	sdcard_enqueue_response(sdc, 0x00);
	sdcard_enqueue_response(sdc, 0xFF);

	sdc->cmd_handler = &sdcard_do_write_block_2nd;
	sdc->cmd_length = sdc->blockLength+3;
	sdc->seek_address = addr;
}

static void
sdcard_do_write_block_2nd(SDCard *sdc) {
	int h;

	sdc->cmd_handler = &sdcard_default_handler;
	sdc->cmd_length = 6;

	if(sdc->command[0] != -2) {
		sdcard_enqueue_response(sdc, 0xED);
		return;
	}

	h = open("sdcard.sdc", O_RDWR);
	if(h < 0) {
		sdcard_enqueue_response(sdc, 0xED);
		return;
	}
	lseek(h, sdc->seek_address, SEEK_SET);
	write(h, &sdc->command[1], sdc->blockLength);
	close(h);

	sdcard_enqueue_response(sdc, 0xE5);
	sdcard_enqueue_response(sdc, 0x00);
	sdcard_enqueue_response(sdc, 0xFF);
}

