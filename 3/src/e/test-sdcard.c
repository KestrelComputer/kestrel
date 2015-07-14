#include <cut/2.7/cut.h>

#include "types.h"
#include "sdcard.h"


SDCard *sdc;
int calledBack;


void __CUT_BRINGUP__fresh_sdcard(void) {
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
	calledBack = 1;
}

void __CUT_BRINGUP__selected_sdcard(void) {
	sdc = sdcard_new();
	sdcard_select(sdc);
}

void __CUT__should_be_selected(void) {
	ASSERT(sdc->selected, "Selected SD card should be selected");
}

void __CUT__should_yield_no_result_on_r1_cmd(void) {
	BYTE r;

	calledBack = 0;
	sdc->cmd_handler = &my_cmd_handler;
	r = sdcard_byte(sdc, 0x40);
	ASSERT(r == -1, "SD card responded with something for R1 cmd");
	ASSERT(!calledBack, "Too early to call command handler yet.");
}

void __CUT_TAKEDOWN__selected_sdcard(void) {
	sdcard_dispose(sdc);
}

