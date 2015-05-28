; Attempt to convert a word into a number.

numbTryConversion:
		addi	rp, rp, -16
		sd	rt, 0(rp)
		ld	s0, zpBase(x0)
		sd	s0, 8(rp)
		sd	x0, zpWordIndex(x0)
		sb	x0, zpSign(x0)
		jal	rt, numbEitherHexOrDecimal
		ld	s0, 8(rp)
		sd	s0, zpBase(x0)
		ld	rt, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)
