		include "asrt.i"
		include "oint.asm"
		include "scan.asm"
		include "char.asm"
		include "err.asm"
		include "dstk.asm"

; Dependencies required by oint module.
;
; These add a layer of indirection to make testing on a case-by-case basis
; easier.

epv_ointGetAndInterpretLine	= 0
epv_dictLocateWord		= epv_ointGetAndInterpretLine+4
epv_errReport			= epv_dictLocateWord+4
epv_numbTryConversion		= epv_errReport+4

ointGetAndInterpretLine:
		ld	t0, zpV(x0)
		jalr	x0, 0(t0)

dictLocateWord:
		ld	t0, zpV(x0)
		jalr	x0, epv_dictLocateWord(t0)

dictIsWordFound:
		ld	a0, zpWordFound(x0)
		jalr	x0, 0(rt)

errReport:	ld	t0, zpV(x0)
		jalr	x0, epv_errReport(t0)

numbTryConversion:
		ld	t0, zpV(x0)
		jalr	x0, epv_numbTryConversion(t0)

		include "tests/oint.asm"

;
; Suite Definition
;

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	7
		dword	romBase+testOintEmptyLine
		dword	romBase+testOintBlankLine
		dword	romBase+testOintWordInLine
		dword	romBase+testOintWordInLineFound
		dword	romBase+testOintDataStackUnderflow
		dword	romBase+testOintDataStackOverflow
		dword	romBase+testOintAttemptConversion

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
