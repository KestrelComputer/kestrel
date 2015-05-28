		include "asrt.i"

		include "tests/numb.asm"
		include "numb.asm"


epv_numbEitherHexOrDecimal = 0


numbEitherHexOrDecimal:
		ld	t0,zpV(x0)
		jalr	x0, epv_numbEitherHexOrDecimal(t0)


		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	4
		dword	romBase+testNumbBasePreserved
		dword	romBase+testNumbWordStart
		dword	romBase+testNumbPositiveStart
		dword	romBase+testNumbNegativeStart

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
