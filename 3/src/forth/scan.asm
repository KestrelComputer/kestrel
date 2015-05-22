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


; Skip whitespace.

scanSkipWhitespace:
		sd	ra, zpScanSkipWSPC(x0)
sSW1:		ld	a0, zpScanIndex(x0)	; si <= ll
		ld	a1, zpLineLength(x0)
		bgeu	a0, a1, sSW0

		ld	a1, zpLineBuffer(x0)	; si < ll
		add	a0, a0, a1
		lb	a0, 0(a0)		; ch e. {WS, nonWS}
		jal	ra, charIsWhitespace
		beq	a0, x0, sSW0

		ld	a0, zpScanIndex(x0)	; ch e. {WS}
		addi	a0, a0, 1
		sd	a0, zpScanIndex(x0)
		jal	x0, sSW1

sSW0:		ld	ra, zpScanSkipWSPC(x0)	; ch e. {nonWS}
		jalr	x0, 0(ra)

