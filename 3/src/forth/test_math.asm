		include "asrt.i"

		include "tests/math.asm"
		include "math.asm"

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	4
		dword	romBase+testMathMultiplyNN
		dword	romBase+testMathMultiplyNP
		dword	romBase+testMathMultiplyPN
		dword	romBase+testMathMultiplyPP

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
