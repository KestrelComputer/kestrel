; The interpreter should be able to handle a zero-length line of input.

setup_emptyLine:
		sd	x0, zpLineLength(x0)
		sd	x0, zpError(x0)
		sd	x0, zpCalled(x0)
		sd	x0, zpWordFound(x0)
		auipc	t0, 0
s_eL0:		addi	t0, t0, s_eL__epv-s_eL0
		sd	t0, zpV(x0)
		jalr	x0, 0(ra)

s_eL__epv:	jal	x0, ep_emptyLine_ointGetAndInterpretLine
		jal	x0, ep_emptyLine_dictLocateWord
		jal	x0, asrtFail
		jal	x0, asrtFail

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
s_OIWIL0:	addi	t1, t0, s_OIWIL_epv - s_OIWIL0
		sd	t1, zpV(x0)
		addi	t1, t0, s_OIWIL_line - s_OIWIL0
		sd	t1, zpLineBuffer(x0)
		addi	t1, x0, s_OIWIL_linelen
		sd	t1, zpLineLength(x0)
		sd	x0, zpCalled(x0)
		sd	x0, zpWordFound(x0)
		jalr	x0, 0(ra)

s_OIWIL_epv:	jal	x0, ep_OIWIL_ointGetAndInterpretLine
		jal	x0, ep_OIWIL_dictLocateWord
		jalr	x0, 0(rt)		; null errReport
		jalr	x0, 0(rt)		; null numbTryConversion

ep_OIWIL_ointGetAndInterpretLine:
		jalr	x0, 0(rt)

ep_OIWIL_dictLocateWord:
		or	s7, rt, x0

		ld	a0, zpScanIndex(x0)
		addi	a1, x0, 8
		jal	ra, asrtEquals

		addi	t0, x0, 1
		sd	t0, zpCalled(x0)
		sd	x0, zpWordFound(x0)

		jalr	x0, 0(s7)


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


; Upon finding a word in the dictionary, the interpreter needs to invoke its
; definition.

s_OIWILF_epv:	jal	x0, ep_OIWIL_ointGetAndInterpretLine
		jal	x0, ep_OIWILF_dictLocateWord
		jal	x0, asrtFail
		jal	x0, asrtFail

ep_OIWILF_dictLocateWord:
		addi	t0, x0, 1
		sd	t0, zpWordFound(x0)
		auipc	t0, 0
epOIWILFd0:	addi	t0, t0, tOIWILF_cb - epOIWILFd0
		sd	t0, zpWordBody(x0)
		jalr	x0, 0(rt)

tOIWILF_cb:	addi	t0, x0, 1
		sd	t0, zpCalled(x0)
		jalr	x0, 0(rt)

		byte	"OIWILF  "
testOintWordInLineFound:
		sd	ra, zpTestPC(x0)

		jal	ra, setup_OIWIL
		auipc	t0, 0
tOIWILF0:	addi	t0, t0, s_OIWILF_epv - tOIWILF0
		sd	t0, zpV(x0)

		jal	rt, ointInterpretLine

		ld	a0, zpCalled(x0)
		jal	rt, asrtIsTrue

		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; When we fire off a word, it could underflow the stack.  The interpreter
; needs to gracefully recover from this condition.

setup_OIDSU:	auipc	t0, 0
s_OIDSU0:	addi	t1, t0, s_OIDSU_epv-s_OIDSU0
		sd	t1, zpV(x0)
		addi	t1, t0, s_OIDSU_line-s_OIDSU0
		sd	t1, zpLineBuffer(x0)
		addi	t1, x0, s_OIDSU_lineLen
		sd	t1, zpLineLength(x0)
		ld	dp, zpDP0(x0)
		sd	x0, zpError(x0)
		jalr	x0, 0(ra)

s_OIDSU_epv:	jal	x0, ep_OIWIL_ointGetAndInterpretLine
		jal	x0, ep_OIDSU_dictLocateWord
		jal	x0, ep_OIDSU_errReport
		jal	x0, asrtFail

ep_OIDSU_dictLocateWord:
		auipc	t0, 0
		addi	t0, t0, ep_OIDSU_errorHandler - *
		sd	t0, zpWordBody(x0)
		sd	t0, zpWordFound(x0)
		jalr	x0, 0(rt)

ep_OIDSU_errorHandler:
		addi	dp, dp, 2047
		jalr	x0, 0(rt)

ep_OIDSU_errReport:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		addi	t0, x0, 1
		sd	t0, zpCalled(x0)

		ld	a0, zpError(x0)
		addi	a1, x0, ErrDataStackUnderflow
		jal	rt, asrtEquals

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


		byte	"OIDSU   "
testOintDataStackUnderflow:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_OIDSU
		jal	ra, ointInterpretLine
		ld	a0, zpScanIndex(x0)
		addi	a1, x0, 5
		jal	ra, asrtEquals
		ld	a0, zpError(x0)
		jal	ra, asrtIsZero
		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue
		or	a0, dp, x0
		ld	a1, zpDP0(x0)
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

s_OIDSU_line:	byte	"error error"
s_OIDSU_lineLen = *-s_OIDSU_line
		align	4

; When we fire off a word, it could overflow the stack.  The interpreter
; needs to gracefully recover from this condition, too.

setup_OIDSO:	auipc	t0, 0
s_OIDSO0:	addi	t1, t0, s_OIDSO_epv-s_OIDSO0
		sd	t1, zpV(x0)
		addi	t1, t0, s_OIDSU_line-s_OIDSO0
		sd	t1, zpLineBuffer(x0)
		addi	t1, x0, s_OIDSU_lineLen
		sd	t1, zpLineLength(x0)
		ld	dp, zpDP0(x0)
		sd	x0, zpError(x0)
		jalr	x0, 0(ra)

s_OIDSO_epv:	jal	x0, ep_OIWIL_ointGetAndInterpretLine
		jal	x0, ep_OIDSO_dictLocateWord
		jal	x0, ep_OIDSO_errReport
		jal	x0, asrtFail

ep_OIDSO_dictLocateWord:
		auipc	t0, 0
		addi	t0, t0, ep_OIDSO_errorHandler - *
		sd	t0, zpWordBody(x0)
		sd	t0, zpWordFound(x0)
		jalr	x0, 0(rt)

ep_OIDSO_errorHandler:
		ld	dp, zpDPL(x0)
		addi	dp, dp, -1
		jalr	x0, 0(rt)

ep_OIDSO_errReport:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		addi	t0, x0, 1
		sd	t0, zpCalled(x0)

		ld	a0, zpError(x0)
		addi	a1, x0, ErrDataStackOverflow
		jal	rt, asrtEquals

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


		byte	"OIDSO   "
testOintDataStackOverflow:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_OIDSO
		jal	ra, ointInterpretLine
		ld	a0, zpScanIndex(x0)
		addi	a1, x0, 5
		jal	ra, asrtEquals
		ld	a0, zpError(x0)
		jal	ra, asrtIsZero
		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue
		or	a0, dp, x0
		ld	a1, zpDP0(x0)
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; When looking for a word, and that word isn't found in the dictionary, then
; the outer interpreter should attempt to convert it to a number.

setup_OIACVT:	auipc	t0, 0
s_OIACVT0:	addi	t1, t0, s_OIDSU_line-s_OIACVT0
		sd	t1, zpLineBuffer(x0)
		addi	t1, x0, s_OIDSU_lineLen
		sd	t1, zpLineLength(x0)
		addi	t1, t0, s_OIACVT_epv-s_OIACVT0
		sd	t1, zpV(x0)
		sd	x0, zpCalled(x0)
		sd	x0, zpError(x0)
		jalr	x0, 0(ra)

s_OIACVT_epv:	jalr	x0, 0(rt)		; get and interpret line
		jal	x0, ep_OIACVT_dictLocateWord
		jal	x0, ep_OIACVT_errReport
		jal	x0, ep_OIACVT_numbTryConversion

ep_OIACVT_dictLocateWord:
		sd	x0, zpWordFound(x0)
		jalr	x0, 0(rt)

ep_OIACVT_errReport:
		ld	a0, zpError(x0)
		addi	a1, x0, ErrNotNumeric
		jal	x0, asrtEquals

ep_OIACVT_numbTryConversion:
		ori	t0, x0, 1
		sd	t0, zpCalled(x0)
		addi	t0, x0, ErrNotNumeric
		sd	t0, zpError(x0)
		jalr	x0, 0(rt)

		byte	"OIACVT  "
testOintAttemptConversion:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_OIACVT
		jal	ra, ointInterpretLine
		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

