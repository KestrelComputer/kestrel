		include "../../asrt.i"
		include "../../err.asm"
		include "../../numb.asm"

setvecs:	sd	a0, zpV(x0)
		jalr	x0, 0(ra)

setword:	sd	a0, zpWordStart(x0)
		sd	a1, zpWordLength(x0)
		jalr	x0, 0(ra)

; If a number doesn't begin with $, we assume it's decimal.

numbdec_setWord:
		addi	a1, x0, numbdec_wordlen
		jal	a0, setword
numbdec_word:	byte	"13579"
numbdec_wordlen = *-numbdec_word
		align	4

numbdec_setvecs:
		jal	a0, setvecs
		jal	x0, ep_numbdec_tryUnsigned

ep_numbdec_tryUnsigned:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		ld	a0, zpBase(x0)
		addi	a1, x0, 10
		sd	a1, zpCalled(x0)
		jal	ra, asrtEquals
		ld	a0, zpWordIndex(x0)
		jal	ra, asrtIsFalse
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


		byte	"NUMBDEC "
testNumbDecimal:
		sd	ra, zpTestPC(x0)
		sd	x0, zpCalled(x0)
		sd	x0, zpWordIndex(x0)
		addi	a0, x0, 10
		sd	a0, zpBase(x0)
		jal	ra, numbdec_setWord
		jal	ra, numbdec_setvecs
		jal	ra, numbEitherHexOrDecimal
		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue
		ld	a0, zpBase(x0)
		addi	a1, x0, 10
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; If a number does begin with $, we assume it's hexadecimal.

numbhex_setWord:
		addi	a1, x0, numbhex_wordlen
		jal	a0, setword
numbhex_word:	byte	"$13579"
numbhex_wordlen = *-numbhex_word
		align	4

numbhex_setvecs:
		jal	a0, setvecs
		jal	x0, ep_numbhex_tryUnsigned

ep_numbhex_tryUnsigned:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		ld	a0, zpBase(x0)
		addi	a1, x0, 16
		sd	a1, zpCalled(x0)
		jal	ra, asrtEquals
		ld	a0, zpWordIndex(x0)
		addi	a1, x0, 1
		jal	ra, asrtEquals
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


		byte	"NUMBHEX "
testNumbHex:
		sd	ra, zpTestPC(x0)
		sd	x0, zpCalled(x0)
		sd	x0, zpWordIndex(x0)
		addi	a0, x0, 10
		sd	a0, zpBase(x0)
		jal	ra, numbhex_setWord
		jal	ra, numbhex_setvecs
		jal	ra, numbEitherHexOrDecimal
		ld	a0, zpCalled(x0)
		jal	ra, asrtIsTrue
		ld	a0, zpBase(x0)
		addi	a1, x0, 10
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; A word with non-numeric characters in it should not convert all the way.
; When we discover this condition, we should set an error condition.

numberr_setvecs:
		jal	a0, setvecs
		jal	x0, ep_numberr_tryUnsigned

ep_numberr_tryUnsigned:
		jalr	x0, 0(rt)

		addi	rp, rp, -8
		byte	"NUMBERR "
testNumbErr:
		sd	ra, zpTestPC(x0)
		sd	x0, zpError(x0)
		jal	ra, numbhex_setWord
		jal	ra, numberr_setvecs
		jal	ra, numbEitherHexOrDecimal
		ld	a0, zpError(x0)
		addi	a1, x0, ErrNotNumeric
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; A word with all numeric characters in it should convert all the way.

numbnerr_setvecs:
		jal	a0, setvecs
		jal	x0, ep_numbnerr_tryUnsigned

ep_numbnerr_tryUnsigned:
		ld	a0, zpWordLength(x0)
		sd	a0, zpWordIndex(x0)
		jalr	x0, 0(rt)

		addi	rp, rp, -8
		byte	"NUMBNERR"
testNumbNoErr:
		sd	ra, zpTestPC(x0)
		sd	x0, zpError(x0)
		jal	ra, numbhex_setWord
		jal	ra, numbnerr_setvecs
		jal	ra, numbEitherHexOrDecimal
		ld	a0, zpError(x0)
		jal	ra, asrtIsFalse
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)




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
		include "../../asrt.asm"
