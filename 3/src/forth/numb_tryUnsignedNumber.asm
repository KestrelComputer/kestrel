numbTryUnsignedNumber:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		sd	x0, zpValue(x0)

nTUN2:		ld	a0, zpWordIndex(x0)
		ld	a1, zpWordLength(x0)
		bge	a0, a1, nTUN0

		jal	rt, numbNextChar
		ori	t1, a0, 0
		jal	rt, numbEatChar

		addi	t1, t1, -48
		ld	a1, zpBase(x0)
		bltu	t1, a1, nTUN1

		ld	a0, zpWordIndex(x0)
		addi	a0, a0, -1
		sd	a0, zpWordIndex(x0)
		jal	x0, nTUN0

nTUN1:		ld	a0, zpValue(x0)
		jal	rt, math_multiply
		add	a0, a0, t1
		sd	a0, zpValue(x0)
		jal	x0, nTUN2

nTUN0:		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

