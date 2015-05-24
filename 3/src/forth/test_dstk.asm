		include "asrt.i"

		include "tests/dstk.asm"
		include "dstk.asm"
		include "err.asm"

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	3
		dword	romBase+testCheckStackBoundsUnderflow
		dword	romBase+testCheckStackBoundsOverflow
		dword	romBase+testDstkReset

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
