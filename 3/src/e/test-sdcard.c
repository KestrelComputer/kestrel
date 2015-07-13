#include <cut/2.7/cut.h>

#include "sdcard.h"


SDCard *sdc;

void __CUT_BRINGUP__sdcard(void) {
    sdc = sdcard_new();
}

void __CUT_TAKEDOWN__sdcard(void) {
    sdcard_dispose(sdc);
}

