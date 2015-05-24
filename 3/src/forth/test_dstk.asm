		include "asrt.i"

		include "tests/dstk.asm"
		include "dstk.asm"
		include "err.asm"

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	1
		dword	romBase+testCheckStackBoundsUnderflow

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
