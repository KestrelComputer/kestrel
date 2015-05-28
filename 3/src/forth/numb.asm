; Attempt to convert a word into a number.

numbTryConversion:
		addi	rp, rp, -16
		sd	rt, 0(rp)
		ld	s0, zpBase(x0)
		sd	s0, 8(rp)
		sd	x0, zpWordIndex(x0)
		sb	x0, zpSign(x0)
		jal	rt, numbNextChar
		ori	a1, x0, 45
		bne	a0, a1, nTC0
		sb	a1, zpSign(x0)
		jal	rt, numbEatChar
nTC0:		jal	rt, numbEitherHexOrDecimal
		ld	s0, 8(rp)
		sd	s0, zpBase(x0)
		ld	rt, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)

; Get the next character in the word to convert.

numbNextChar:	ld	a0, zpWordStart(x0)
		ld	a1, zpWordIndex(x0)
		add	a0, a0, a1
		lb	a0, 0(a0)
		jalr	x0, 0(rt)

; Advance to the next character in the word.

numbEatChar:	ld	a0, zpWordIndex(x0)
		ld	a1, zpWordLength(x0)
		bgeu	a0, a1, nEC0
		addi	a0, a0, 1
		sd	a0, zpWordIndex(x0)
nEC0:		jalr	x0, 0(rt)

