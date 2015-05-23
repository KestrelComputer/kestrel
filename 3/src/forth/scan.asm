; scanStartLine prepares for interpreting a line of input word by word.

scanStartLine:	sd	x0, zpScanIndex(x0)
		jalr	x0, 0(rt)


; scanIsLineExhausted returns true if we've exhausted our input buffer.

scanIsLineExhausted:
		ld	a0, zpLineLength(x0)
		ld	a1, zpScanIndex(x0)
		sltu	a0, a1, a0
		addi	a0, a0, -1
		jalr	x0, 0(rt)


; Skip non-whitespace.

scanSkipNonSpace:
		addi	rp, rp, -8
		sd	rt, 0(rp)
sSNW1:		ld	a0, zpScanIndex(x0)	; si <= ll
		ld	a1, zpLineLength(x0)
		bgeu	a0, a1, sSNW0

		ld	a1, zpLineBuffer(x0)	; si < ll
		add	a0, a0, a1
		lb	a0, 0(a0)		; ch e. {WS, nonWS}
		jal	ra, charIsWhitespace
		bne	a0, x0, sSNW0

		ld	a0, zpScanIndex(x0)	; ch e. {nonWS}
		addi	a0, a0, 1
		sd	a0, zpScanIndex(x0)
		jal	x0, sSNW1

sSNW0:		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; Skip whitespace.

scanSkipWhitespace:
		addi	rp, rp, -8
		sd	rt, 0(rp)
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

sSW0:		ld	rt, 0(rp)		; ch e. {nonWS}
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; Mark the start of a word.

scanMarkWordStart:
		ld	a0, zpLineBuffer(x0)
		ld	a1, zpScanIndex(x0)
		add	a0, a0, a1
		sd	a0, zpWordStart(x0)
		jalr	x0, 0(rt)

; Mark the end of a word.  Note that the beginning of the word must have been
; marked first.

scanMarkWordEnd:
		ld	a0, zpLineBuffer(x0)
		ld	a1, zpScanIndex(x0)
		add	a0, a0, a1
		ld	a1, zpWordStart(x0)
		sub	a0, a0, a1
		sd	a0, zpWordLength(x0)
		jalr	x0, 0(rt)

; Take the next word from the input stream.  Skip leading whitespace before
; calling this procedure!

scanTakeNextWord:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		jal	rt, scanMarkWordStart
		jal	rt, scanSkipNonSpace
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jal	x0, scanMarkWordEnd
