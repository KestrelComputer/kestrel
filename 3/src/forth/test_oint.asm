romBase = $0FFFFFFFFFFF0000

		include "cpu/regs.i"
		include	"zp.i"
		include "con.asm"

		include "oint.asm"
		include "scan.asm"
		include "char.asm"

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

		ld	a0, zpScanIndex(x0)
		jal	ra, asrtIsZero

		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


		byte	"OIBL    "
testOintBlankLine:
		sd	ra, zpTestPC(x0)

		addi	t0, x0, blanks8len
		sd	t0, zpLineLength(x0)
		auipc	t0, 0
tOBL0:		addi	t0, t0, blanks8-tOBL0
		sd	t0, zpLineBuffer(x0)
		sd	x0, zpError(x0)
		sd	x0, zpCalled(x0)

		jal	ra, ointInterpretLine

		ld	a0, zpError(x0)
		jal	ra, asrtIsZero

		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue

		ld	a0, zpScanIndex(x0)
		addi	a1, x0, blanks8len
		jal	ra, asrtEquals

		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

blanks8:	byte	"        "
blanks8len = * - blanks8
		align	4


ointGetAndInterpretLine:
		addi	t0, x0, 1
		sd	t0, zpCalled(x0)
		jalr	x0, 0(ra)


dictLocateWord:	sd	x0, zpWordFound(x0)
		jalr	x0, 0(ra)

dictIsWordFound:
		ld	a0, zpWordFound(x0)
		jalr	x0, 0(a0)

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	2
		dword	romBase+testOintEmptyLine
		dword	romBase+testOintBlankLine

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
