romBase = $0FFFFFFFFFFF0000

		include "cpu/regs.i"
		include	"zp.i"
		include "con.asm"

		include "oint.asm"

		byte	"OIEL    "
testOintEmptyLine:
		sd	ra, zpTestPC(x0)
		sd	x0, zpLineLength(x0)
		sd	x0, zpError(x0)
		sd	x0, zpCalled(x0)

		jal	ra, ointInterpretLine

		ld	a0, zpError(x0)
		jal	ra, asrtIsZero

		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue

		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


ointGetAndInterpretLine:
		addi	t0, x0, 1
		sd	t0, zpCalled(x0)
		jalr	x0, 0(ra)


		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	1
		dword	romBase+testOintEmptyLine

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
