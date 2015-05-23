romBase = $0FFFFFFFFFFF0000

		include "cpu/regs.i"
		include	"zp.i"
		include "con.asm"

		include "tests/char.asm"
		include "char.asm"

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	2
		dword	testCharIsWhitespace+romBase
		dword	testCharIsNotWhitespace+romBase

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
