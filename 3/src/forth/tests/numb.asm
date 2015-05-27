setvecs:	sd	a0, zpV(x0)
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

