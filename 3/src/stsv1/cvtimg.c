#include <stdio.h>

// Convert a file exported from Gimp in ".h" format into a raw binary file
// suitable for direct consumption by the Kestrel-2 or Kestrel-3.
//
// 1) Export your black and white (indexed, 2 color) image as "file.h".
// 2) Change #include below to read "file.h".
// 3) Recompile using GCC or CLang.
// 4) Run a.out >img.file
// 5) Include the img.file file into the ROM filesystem as any other file.
//
// This program inverts the sense of pixels; Gimp insists that pen 0 is
// white for some reason, instead of black.  This is not configurable.

#include "kestrel-logo-4c.h"

int main(int argc, char *argv[]) {
	int i, j, k, b;
	char *pc = header_data;

	for(j = 0; j < 480; j++) {
		for(i = 0; i < 80; i++) {
			b = 0;
			for(k = 0; k < 8; k++) {
				b <<= 1;
				if(!(*pc++)) b |= 0x01;
			}
			printf("%c", b);
		}
	}

	return 0;
}
