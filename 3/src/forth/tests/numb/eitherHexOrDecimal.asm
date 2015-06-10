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
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


		byte	"NUMBDEC "
testNumbDecimal:
		sd	ra, zpTestPC(x0)
		sd	x0, zpCalled(x0)
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
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


		byte	"NUMBHEX "
testNumbHex:
		sd	ra, zpTestPC(x0)
		sd	x0, zpCalled(x0)
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
