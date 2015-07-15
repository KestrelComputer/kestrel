#include <cut/2.7/cut.h>
#include <stdio.h>

#include "types.h"
#include "sdcard.h"


SDCard *sdc;
int calledBack;


void
send_address(WORD addr, char *msg) {
	BYTE r;

	r = sdcard_byte(sdc, (addr >> 24) & 0xFF); ASSERT(r == -1, msg);
	r = sdcard_byte(sdc, (addr >> 16) & 0xFF); ASSERT(r == -1, msg);
	r = sdcard_byte(sdc, (addr >> 8) & 0xFF); ASSERT(r == -1, msg);
	r = sdcard_byte(sdc, addr & 0xFF); ASSERT(r == -1, msg);
}

void
send_address_crc(WORD addr) {
	BYTE r;

	send_address(addr, "");
	r = sdcard_byte(sdc, 0x01); ASSERT(r == -1, "");
}

void
send_cmd0(void) {
	sdcard_byte(sdc, 0x40);
	send_address_crc(0);
}

void
send_cmd55(void) {
	sdcard_byte(sdc, 64+55);
	send_address_crc(0);
}

void
send_cmd1(void) {
	sdcard_byte(sdc, 0x41);
	send_address_crc(0);
}

void
send_set_block_length(WORD blklen) {
	sdcard_byte(sdc, 0x50);
	send_address_crc(blklen);
}

void
send_read_block_cmd(WORD addr) {
	sdcard_byte(sdc, 0x51);
	send_address_crc(addr);
}

void
send_write_block_cmd(WORD addr) {
	sdcard_byte(sdc, 0x58);
	send_address_crc(addr);
}

static void
write_some_data(void) {
	int i, n;
	BYTE r;

	send_write_block_cmd(0);
	r = sdcard_byte(sdc, 0xFF);
	r = sdcard_byte(sdc, 0xFF);
	r = sdcard_byte(sdc, 0xFE);
	for(i = 0; i < 514; i++) {	// 512 bytes + 2 CRC bytes
		r = sdcard_byte(sdc, 0xAA);
	}
	r = sdcard_byte(sdc, 0xFF);
	r = sdcard_byte(sdc, 0xFF);
	r = sdcard_byte(sdc, 0xFF);
}



void __CUT_SETUP__fresh_sdcard(void) {
	sdc = sdcard_new();
}

void __CUT__ignores_command_bytes(void) {
	BYTE r = sdcard_byte(sdc, 0x40);
	ASSERT(r == -1, "Fresh card must ignore R1 commands");
	ASSERT(sdc->cmd_index == 0, "Ignored bytes should not affect cmd index");
	ASSERT_(!sdc->selected);
}

void __CUT__ignores_wait_bytes(void) {
	BYTE r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == -1, "Fresh card takes no action for idle cycles");
	ASSERT(sdc->cmd_index == 0, "Ignored bytes should not affect cmd index");
	ASSERT_(!sdc->selected);
}

void __CUT__accepts_response_bytes(void) {
	sdcard_enqueue_response(sdc, 0x12);
	ASSERT(sdc->response_wr == sdc->response_rd+1, "Enqueueing output should advance write pointer");
}

void __CUT_TAKEDOWN__fresh_sdcard(void) {
	sdcard_dispose(sdc);
}



void
my_cmd_handler(SDCard *s) {
	calledBack++;
	ASSERT_(s == sdc);
	sdcard_enqueue_response(s, 0x01);
}

void setup_selected_sdcard(void) {
	sdc = sdcard_new();
	sdcard_select(sdc);
	calledBack = 0;
	sdc->cmd_handler = &my_cmd_handler;
}

void __CUT_SETUP__selected_sdcard(void) {
	setup_selected_sdcard();
}

void __CUT__should_be_selected(void) {
	ASSERT(sdc->selected, "Selected SD card should be selected");
}

void __CUT__should_yield_no_result_on_r1_cmd(void) {
	BYTE r = sdcard_byte(sdc, 0x40);
	ASSERT(r == -1, "SD card responded with something for R1 cmd");
	ASSERT(!calledBack, "Too early to call command handler yet.");
}

void __CUT__should_ignore_leading_wait_bytes(void) {
	BYTE r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == -1, "SD card responded with something for wait cycle");
	ASSERT(sdc->cmd_index == 0, "Ignored bytes should not affect cmd index");
	ASSERT(!calledBack, "Spurious command execution discovered.");
}

void __CUT_TAKEDOWN__selected_sdcard(void) {
	sdcard_dispose(sdc);
}



void __CUT_SETUP__selected_card_with_r1_cmd(void) {
	setup_selected_sdcard();
	sdcard_byte(sdc, 0x40);
}

void __CUT__should_accumulate_parameter_bytes(void) {
	send_address(0, "SD card responded when it should have been accumulating");
	ASSERT(!calledBack, "Spurious command execution discovered.");
}

void __CUT__should_invoke_handler_after_crc(void) {
	send_address(0, "SD card responded before CRC sent");
	ASSERT(!calledBack, "Spurious command execution discovered.");
	sdcard_byte(sdc, 0x01);
	ASSERT(calledBack == 1, "Command execution after CRC expected.");
}

void __CUT_TAKEDOWN__selected_card_with_r1_cmd(void) {
	sdcard_dispose(sdc);
}



void __CUT_SETUP__selected_card_with_r1_packet(void) {
	setup_selected_sdcard();
	send_cmd0();
}

void __CUT__should_have_invoked_its_cmd_handler_once(void) {
	ASSERT(calledBack == 1, "Incorrect number of command handler invokations");
}

void __CUT__should_have_invoked_its_cmd_handler_once_per_cmd(void) {
	send_cmd0();
	ASSERT(calledBack == 2, "Incorrect number of command handler invokations");
}

void __CUT_TAKEDOWN__selected_card_with_r1_packet(void) {
	sdcard_dispose(sdc);
}




void __CUT_SETUP__r1_cmds_sends_r1_response(void) {
	setup_selected_sdcard();
	send_cmd0();
}

void __CUT__we_receive_the_response(void) {
	BYTE r = sdcard_byte(sdc, -1);
	ASSERT(r == 0x01, "Expected 0x01 response from CMD0");
	ASSERT(sdc->response_rd == sdc->response_wr, "Dequeue should have worked");
	ASSERT(sdc->response_rd == 1, "Response offset should be 1");
}

void __CUT_TAKEDOWN__r1_cmds_sends_r1_response(void) {
	sdcard_dispose(sdc);
}



void __CUT_SETUP__sd_initialization(void) {
	BYTE r;

	sdc = sdcard_new();
	sdcard_select(sdc);
	send_cmd0();
	r = sdcard_byte(sdc, 0xFF);
	ASSERT_(r == 0x01);
}

void __CUT__rejects_mmc_initialization(void) {
	BYTE r;

	send_cmd1();
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0x05, "We're emulating SD V1, not MMC V1");
}

void __CUT__accepts_sdv1_initialization(void) {
	BYTE r;

	send_cmd55();
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0x01, "ACMD prefix must be recognized.");

	send_cmd1();
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0x00, "Expect SD card to fall out of idle state.");
}

void __CUT__accepts_new_block_length(void) {
	BYTE r;

	send_cmd55();
	send_cmd1();

	send_set_block_length(512);
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0x00, "Card should accept new block length.");
}

void __CUT_TAKEDOWN__sd_initialization(void) {
	sdcard_dispose(sdc);
}



void __CUT_SETUP__sd_read_write_blocks(void) {
	BYTE r;

	sdc = sdcard_new();
	sdcard_select(sdc);
	send_cmd0();  r = sdcard_byte(sdc, 0xFF);
	send_cmd55(); r = sdcard_byte(sdc, 0xFF);
	send_cmd1();  r = sdcard_byte(sdc, 0xFF);
	send_set_block_length(512);  r = sdcard_byte(sdc, 0xFF);
}

void __CUT__read_beyond_card_capacity(void) {
	BYTE r;

	send_read_block_cmd(1024*1048576);
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0x20, "Card is only 1GB in size.");
}

void __CUT__write_beyond_card_capacity(void) {
	BYTE r;

	send_write_block_cmd(1024*1048576);
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0x20, "Card is only 1GB in size.");
}

void __CUT__read_block(void) {
	int i, n;
	BYTE r;

	send_read_block_cmd(0);
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0x00, "Card should accept read block command");

	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == -1, "Protocol says to wait at least 1 byte before data");

	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == -2, "Start data block token expected");

	n = 0;
	for(i = 0; i < 514; i++) {	// 512 bytes + 2 CRC bytes
		r = sdcard_byte(sdc, 0xFF);
		if(r != -1) n++;
	}
	ASSERT(n > 0, "Data should have been sent.");

	for(i = 0; i < 512; i++) {
		r = sdcard_byte(sdc, 0xFF);
		ASSERT(r == -1, "After packet, SD card sets MISO high");
	}
}

void __CUT__write_block(void) {
	int i, n;
	BYTE r;

	send_write_block_cmd(0);
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0x00, "Card should accept read block command");

	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == -1, "Protocol says to wait at least 1 byte before data");

	r = sdcard_byte(sdc, 0xFE);
	ASSERT(r == -1, "Start of data should illicit no response.");
	for(i = 0; i < 514; i++) {	// 512 bytes + 2 CRC bytes
		r = sdcard_byte(sdc, 0xAA);
		ASSERT(r == -1, "Card must not respond before data sent.");
	}

	/* Obviously, these are artificial timings.  Real code must be
	 * responsive to differing numbers of wait cycles, etc.
	 */
	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == (BYTE)0xE5, "Card must accept written data.");

	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == 0, "Card must take time to write the data.");

	r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == -1, "Card must finish writing data.");
}

void __CUT__verify_block(void) {
	int i, n;
	BYTE r;

	write_some_data();

	send_read_block_cmd(0);
	r = sdcard_byte(sdc, 0xFF);
	r = sdcard_byte(sdc, 0xFF);
	r = sdcard_byte(sdc, 0xFF);

	n = 0;
	for(i = 0; i < 512; i++) {	// 512 bytes + 2 CRC bytes
		r = sdcard_byte(sdc, 0xFF);
		ASSERT(r == (BYTE)0xAA, "Write should have succeeded");
	}
	r = sdcard_byte(sdc, 0xFF); ASSERT(r == 1, "CRC should not be affected.");
	r = sdcard_byte(sdc, 0xFF); ASSERT(r == 1, "CRC should not be affected.");
}

void __CUT_TAKEDOWN__sd_read_write_blocks(void) {
	sdcard_dispose(sdc);
}

