		include "asrt.i"

		include "tests/char.asm"
		include "char.asm"

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	6
		dword	testCharIsWhitespace+romBase
		dword	testCharIsNotWhitespace+romBase
		dword	testCharIsLowercasePositive+romBase
		dword	testCharIsLowercaseNegativeLow+romBase
		dword	testCharIsLowercaseNegativeHigh+romBase
		dword	testCharUpper+romBase

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
