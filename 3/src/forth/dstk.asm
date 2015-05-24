dstkCheckBounds:
		ld	t0, zpDP0(x0)
		bltu	t0, dp, dCB0
		jalr	x0, 0(rt)

dCB0:		addi	t0, x0, ErrDataStackUnderflow
		sd	t0, zpError(x0)
		jalr	x0, 0(rt)


