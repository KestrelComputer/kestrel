; Emit a character to the console.
conEmit:	ld	t0, zpUartBase(x0)
		sb	a0, 0(t0)
		jalr	x0, 0(ra)

