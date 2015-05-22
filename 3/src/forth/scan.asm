; scanStartLine prepares for interpreting a line of input word by word.

scanStartLine:	sd	x0, zpScanIndex(x0)
		jalr	x0, 0(ra)


; scanIsLineExhausted returns true if we've exhausted our input buffer.

scanIsLineExhausted:
		ld	a0, zpLineLength(x0)
		ld	a1, zpScanIndex(x0)
		sltu	a0, a1, a0
		addi	a0, a0, -1
		jalr	x0, 0(ra)

		blt	a1, a0, sILE1
		ori	a0, x0, -1
		jalr	x0, 0(ra)
sILE1:		ori	a0, x0, 0
		jalr	x0, 0(ra)

