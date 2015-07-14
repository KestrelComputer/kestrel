#include <cut/2.7/cut.h>

#include "types.h"
#include "sdcard.h"


SDCard *sdc;
int calledBack;


void __CUT_SETUP__fresh_sdcard(void) {
	sdc = sdcard_new();
}

void __CUT__ignores_command_bytes(void) {
	BYTE r = sdcard_byte(sdc, 0x40);
	ASSERT(r == -1, "Fresh card must ignore R1 commands");
	ASSERT_(!sdc->selected);
}

void __CUT__ignores_wait_bytes(void) {
	BYTE r = sdcard_byte(sdc, 0xFF);
	ASSERT(r == -1, "Fresh card takes no action for idle cycles");
	ASSERT_(!sdc->selected);
}

void __CUT_TAKEDOWN__fresh_sdcard(void) {
	sdcard_dispose(sdc);
}


void
my_cmd_handler(void) {
	calledBack++;
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
	ASSERT(!calledBack, "Spurious command execution discovered.");
}

void __CUT_TAKEDOWN__selected_sdcard(void) {
	sdcard_dispose(sdc);
}




void __CUT_SETUP__selected_card_with_r1_cmd(void) {
	setup_selected_sdcard();
	sdcard_byte(sdc, 0x40);
}

void
send_address(char *msg) {
	BYTE r;

	r = sdcard_byte(sdc, 0x11);
	ASSERT(r == -1, msg);

	r = sdcard_byte(sdc, 0x22);
	ASSERT(r == -1, msg);

	r = sdcard_byte(sdc, 0x33);
	ASSERT(r == -1, msg);

	r = sdcard_byte(sdc, 0x44);
	ASSERT(r == -1, msg);
}

void __CUT__should_accumulate_parameter_bytes(void) {
	send_address("SD card responded when it should have been accumulating");
	ASSERT(!calledBack, "Spurious command execution discovered.");
}

void __CUT__should_invoke_handler_after_crc(void) {
	send_address("SD card responded before CRC sent");
	ASSERT(!calledBack, "Spurious command execution discovered.");
	sdcard_byte(sdc, 0x01);
	ASSERT(calledBack == 1, "Command execution after CRC expected.");
}

void __CUT_TAKEDOWN__selected_card_with_r1_cmd(void) {
	sdcard_dispose(sdc);
}



void
send_cmd0(void) {
	sdcard_byte(sdc, 0x40);
	sdcard_byte(sdc, 0x11);
	sdcard_byte(sdc, 0x22);
	sdcard_byte(sdc, 0x33);
	sdcard_byte(sdc, 0x44);
	sdcard_byte(sdc, 0x55);
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

