		include "asrt.i"

		include "tests/numb/tryConversion.asm"
		include "tests/numb/nextChar.asm"
		include "numb_tryConversion.asm"
		include "numb_nextChar.asm"


epv_numbEitherHexOrDecimal = 0


numbEitherHexOrDecimal:
		ld	t0, zpV(x0)
		jalr	x0, epv_numbEitherHexOrDecimal(t0)


		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	5
		dword	romBase+testNumbBasePreserved
		dword	romBase+testNumbWordStart
		dword	romBase+testNumbPositiveStart
		dword	romBase+testNumbNegativeStart
		dword	romBase+testNumbNextChar

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
