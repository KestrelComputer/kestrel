		include "asrt.i"
		include "oint.asm"
		include "scan.asm"
		include "char.asm"

; Dependencies required by oint module.

epv_ointGetAndInterpretLine	= 0
epv_dictLocateWord		= epv_ointGetAndInterpretLine+8

ointGetAndInterpretLine:
		ld	t0, zpV(x0)
		jalr	x0, 0(t0)

dictLocateWord:
		ld	t0, zpV(x0)
		jalr	x0, epv_dictLocateWord(t0)

dictIsWordFound:
		ld	a0, zpWordFound(x0)
		jalr	x0, 0(rt)

; The interpreter should be able to handle a zero-length line of input.

setup_emptyLine:
		sd	x0, zpLineLength(x0)
		sd	x0, zpError(x0)
		sd	x0, zpCalled(x0)
		auipc	t0, 0
s_eL0:		addi	t0, t0, s_eL__epv-s_eL0
		sd	t0, zpV(x0)
		jalr	x0, 0(ra)

s_eL__epv:	jal	x0, ep_emptyLine_ointGetAndInterpretLine
		jal	x0, ep_emptyLine_dictLocateWord

ep_emptyLine_ointGetAndInterpretLine:
		addi	t0, x0, 1
		sd	t0, zpCalled(x0)
		jalr	x0, 0(rt)

ep_emptyLine_dictLocateWord:
		sd	x0, zpWordFound(x0)
		jalr	x0, 0(rt)


		byte	"OIEL    "
testOintEmptyLine:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_emptyLine

		jal	ra, ointInterpretLine

		ld	a0, zpError(x0)
		jal	ra, asrtIsZero

		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue

		ld	a0, zpScanIndex(x0)
		jal	ra, asrtIsZero

		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; The interpreter should be able to handle a line consisting of just
; whitespace.

		byte	"OIBL    "
testOintBlankLine:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_emptyLine

		addi	t0, x0, blanks8len
		sd	t0, zpLineLength(x0)
		auipc	t0, 0
tOBL0:		addi	t0, t0, blanks8-tOBL0
		sd	t0, zpLineBuffer(x0)

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

; The interpreter, upon finding a word, should try to look it up in the
; dictionary.

setup_OIWIL:	auipc	t0, 0
s_OIWIL0:	add	t1, t0, s_OIWIL_epv - s_OIWIL0
		sd	t1, zpV(x0)
		add	t1, t0, s_OIWIL_line - s_OIWIL0
		sd	t1, zpLineBuffer(x0)
		addi	t1, x0, s_OIWIL_linelen
		sd	t1, zpLineLength(x0)
		jalr	x0, 0(ra)

s_OIWIL_epv:	jal	x0, ep_OIWIL_ointGetAndInterpretLine
		jal	x0, ep_OIWIL_dictLocateWord

ep_OIWIL_ointGetAndInterpretLine:
		jalr	x0,0(rt)

ep_OIWIL_dictLocateWord:
		addi	t0,x0,1
		sd	t0,zpCalled(x0)
		sd	x0,zpWordFound(x0)
		jalr	x0,0(rt)


		byte	"OIWIL   "
testOintWordInLine:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_OIWIL

		jal	ra, ointInterpretLine

		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue

		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

s_OIWIL_line:	byte	"    word    "
s_OIWIL_linelen = *-s_OIWIL_line
		align	4

;
; Suite Definition
;

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	3
		dword	romBase+testOintEmptyLine
		dword	romBase+testOintBlankLine
		dword	romBase+testOintWordInLine

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
