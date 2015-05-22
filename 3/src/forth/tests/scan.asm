; When scanning a new line of text, we want to start at the 0th character
; offset of the input buffer.

		byte	"scanStrt"
testScanStart:	sd	ra, zpTestPC(x0)
		addi	a0, x0, $AAA
		sd	a0, zpScanIndex(x0)
		jal	ra, scanStartLine
		ld	a0, zpScanIndex(x0)
		jal	ra, asrtIsZero
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; We want to break out of the interpreter's scanning loop once we reach
; the end of the input buffer.  This test checks that we properly detect
; when we hit the end of the buffer.

		byte	"scnExLnP"
testScanLineExhausted:
		sd	ra, zpTestPC(x0)
		addi	a0, x0, 63
		sd	a0, zpLineLength(x0)
		sd	a0, zpScanIndex(x0)
		jal	ra, scanIsLineExhausted
		jal	ra, asrtIsTrue
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; We don't want to break out of the interpreter's scanning loop until we
; know we're at the end of the input buffer.  This test checks that we
; properly detect when we have more characters to process.

		byte	"scnExLnN"
testScanLineNotExhausted:
		sd	ra, zpTestPC(x0)
		addi	a0, x0, 63
		sd	a0, zpLineLength(x0)
		addi	a0, x0, 62
		sd	a0, zpScanIndex(x0)
		jal	ra, scanIsLineExhausted
		jal	ra, asrtIsFalse
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

