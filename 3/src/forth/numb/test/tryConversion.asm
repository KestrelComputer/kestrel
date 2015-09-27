		include "../../asrt.i"
		include	"../../err.asm"
		include	"../../math.asm"
		include "../../numb/nextChar.asm"
		include "../../numb/tryConversion.asm"

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

; Always assume a positive number by default when attempting to convert a number.

numbpos_setv:	jal	a0, setvecs
		jalr	x0, 0(rt)	; null eitherHexOrDecimal

		byte	"NUMBPOS "
testNumbPositiveStart:
		sd	ra, zpTestPC(x0)
		jal	ra, numbpos_setv
		jal	ra, numbbgn_setword
		ori	a0, x0, 1
		sb	a0, zpSign(x0)
		jal	ra, numbTryConversion
		lb	a0, zpSign(x0)
		jal	ra, asrtIsZero
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; If attempting to convert a negative number, we expect the sign flag to be set.

numbneg_setv:	jal	a0, setvecs
		jal	x0, ep_numbneg_eitherHexOrDecimal

ep_numbneg_eitherHexOrDecimal:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		lb	a0, zpSign(x0)
		jal	ra, asrtIsTrue
		ld	a0, zpWordIndex(x0)
		ori	a1, x0, 1
		jal	ra, asrtEquals
		addi	a0, x0, 1234
		sd	a0, zpValue(x0)
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

numbneg_setword:
		addi	a1, x0, numbneg_wordlen
		jal	a0, setword
numbneg0:	byte	"-1234"
numbneg_wordlen = *-numbneg0
		align	4

		byte	"NUMBNEG "
testNumbNegativeStart:
		addi	rp, rp, -8
		sd	ra, 0(rp)
		jal	ra, numbneg_setv
		jal	ra, numbneg_setword
		sb	x0, zpSign(x0)
		jal	ra, numbTryConversion
		ld	a0, zpValue(x0)
		addi	a1, x0, -1234
		jal	ra, asrtEquals
		ld	ra, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(ra)



epv_numbEitherHexOrDecimal = 0


numbEitherHexOrDecimal:
		ld	t0, zpV(x0)
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
		include "../../asrt.asm"
