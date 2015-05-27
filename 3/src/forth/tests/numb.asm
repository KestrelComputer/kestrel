setvecs:	sd	a0, zpV(x0)
		jalr	x0, 0(ra)

setword:	sd	a0, zpWordStart(x0)
		sd	a1, zpWordLength(x0)
		jalr	x0, 0(ra)

; When attempting to convert a word into a number we expect the current base to
; be preserved.

numbbase_setv:	jal	a0, setvecs
		jal	x0, ep_numbbase_eitherHexOrDecimal

ep_numbbase_eitherHexOrDecimal:
		ori	a0, x0, 20
		sd	a0, zpBase(x0)
		jalr	x0, 0(rt)

		byte	"NUMBBASE"
testNumbBasePreserved:
		sd	ra, zpTestPC(x0)
		jal	ra, numbbase_setv
		addi	a0, x0, 10
		sd	a0, zpBase(x0)
		jal	ra, numbTryConversion
		ld	a0, zpBase(x0)
		ori	a1, x0, 10
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; When converting a word into a number, we must start at the beginning of the word.

numbbgn_setv:	jal	a0, setvecs
		jal	x0, ep_numbbgn_eitherHexOrDecimal

numbbgn_setword:
		addi	a1, x0, numbbgn_wordlen
		jal	a0, setword
numbbgn0:	byte	"aword"
numbbgn_wordlen = *-numbbgn0
		align	4

ep_numbbgn_eitherHexOrDecimal:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		ld	a0, zpWordIndex(x0)
		jal	rt, asrtIsFalse
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)
		

		byte	"NUMBBGN "
testNumbWordStart:
		sd	ra, zpTestPC(x0)
		jal	ra, numbbgn_setv
		jal	ra, numbbgn_setword
		addi	a0, x0, 4
		sd	a0, zpWordIndex(x0)
		jal	ra, numbTryConversion
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)
