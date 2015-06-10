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
		lb	a0, zpSign(x0)
		beq	a0, x0, nTC1
		ld	a0, zpValue(x0)
		xori	a0, a0, -1
		addi	a0, a0, 1
		sd	a0, zpValue(x0)
nTC1:		ld	s0, 8(rp)
		sd	s0, zpBase(x0)
		ld	rt, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)
