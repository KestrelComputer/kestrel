		include "asrt.i"

		include "tests/numb/tryUnsignedNumber.asm"
		include "numb_tryUnsignedNumber.asm"
		include "numb_nextChar.asm"
		include	"char.asm"


epv_math_multiply	= 0

math_multiply:	ld	t0, zpV(x0)
		jalr	x0, epv_math_multiply(t0)


		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	5
		dword	romBase+testNumb0Length
		dword	romBase+testNumbUnconvertable
		dword	romBase+testNumbConvertable
		dword	romBase+testNumbUpperHex
		dword	romBase+testNumbLowerHex

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
