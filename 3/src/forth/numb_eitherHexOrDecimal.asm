numbEitherHexOrDecimal:
		addi	rp, rp, -16
		sd	rt, 0(rp)
		ld	a0, zpBase(x0)
		sd	a0, 8(rp)

		jal	ra, numbNextChar
		addi	a1, x0, 36
		bne	a0, a1, nEHOD_assumeDec
		addi	a0, x0, 16
		sd	a0, zpBase(x0)
nEHOD_assumeDec:
		jal	rt, numbTryUnsignedNumber
		ld	a0, 8(rp)
		sd	a0, zpBase(x0)
		ld	rt, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)

