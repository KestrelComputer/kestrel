		include "asrt.i"

		include "err.asm"
		include "numb.asm"
		include "tests/numb/eitherHexOrDecimal.asm"


epv_numbTryUnsignedNumber = 0


numbTryUnsignedNumber:
		ld	t0, zpV(x0)
		jalr	x0, epv_numbTryUnsignedNumber(t0)

math_multiply:
charUpper:	jalr	x0, 0(ra)


		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	4
		dword	romBase+testNumbDecimal
		dword	romBase+testNumbHex
		dword	romBase+testNumbErr
		dword	romBase+testNumbNoErr

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
