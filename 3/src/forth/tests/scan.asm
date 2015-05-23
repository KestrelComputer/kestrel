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

; Common setup code for scanning whitespace tests.

setup_skipWS:	or	s7, ra, x0
		jal	a0, s_sW1
s_sW0:		byte	"      whitespace"
s_sW0_len = * - s_sW0
		align	4
s_sW1:		sd	a0, zpLineBuffer(x0)
		addi	a0, x0, s_sW0_len
		sd	a0, zpLineLength(x0)
		jal	ra, scanStartLine
		jalr	x0, 0(s7)

; Common setup code for scanning whitespace tests.

setup_skipAllWS:
		or	s7, ra, x0
		jal	a0, s_sW1
s_sAW0:		byte	"                "
s_sAW0_len = * - s_sAW0
		byte	"    "
		align	4
s_sW1:		sd	a0, zpLineBuffer(x0)
		addi	a0, x0, s_sAW0_len
		sd	a0, zpLineLength(x0)
		jal	ra, scanStartLine
		jalr	x0, 0(s7)

; When looking for words, we want to skip over any whitespace that might
; prefix it.

		byte	"scnSkpWS"
testScanSkipWhitespace:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_skipWS
		jal	ra, scanSkipWhitespace
		ld	a0, zpScanIndex(x0)
		addi	a1, x0, 6
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; When looking for words, we want to skip over any whitespace that might
; prefix it.  However, we don't want to exceed our line buffer boundary.

		byte	"scSkpAWS"
testScanSkipAllWhitespace:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_skipAllWS
		jal	ra, scanSkipWhitespace
		ld	a0, zpScanIndex(x0)
		addi	a1, x0, 16
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; When scanning for words, we need to remember where a word starts.

		byte	"scanMWS "
testScanMarkWordStart:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_skipWS
		addi	a0, x0, 6
		sd	a0, zpScanIndex(x0)
		jal	ra, scanMarkWordStart
		ld	a0, zpWordStart(x0)
		ld	a1, zpLineBuffer(x0)
		addi	a1, a1, 6
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; When looking for words, we want to skip over non-whitespace characters
; once we know we're at a word boundary.

		byte	"scnSkpNW"
testScanSkipNonSpace:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_skipWS
		addi	a0, x0, 6
		sd	a0, zpScanIndex(x0)
		jal	ra, scanSkipNonSpace
		ld	a0, zpScanIndex(x0)
		addi	a1, x0, 16
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; When scanning for words, we need to remember where a word ends.

		byte	"scanMWE "
testScanMarkWordEnd:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_skipWS
		addi	a0, x0, 6
		sd	a0, zpScanIndex(x0)
		jal	ra, scanMarkWordStart
		addi	a0, x0, 16
		sd	a0, zpScanIndex(x0)
		jal	ra, scanMarkWordEnd
		ld	a0, zpWordLength(x0)
		addi	a1, x0, 10
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; Taking the next word means scanning input until we have a whitespace or we
; reach the end of the input buffer.

		byte	"scanTNW "
testScanTakeNextWord:
		sd	ra, zpTestPC(x0)
		jal	ra, setup_skipWS
		jal	ra, scanSkipWhitespace
		jal	ra, scanTakeNextWord
		ld	a0, zpScanIndex(x0)
		addi	a1, x0, 16
		jal	ra, asrtEquals
		ld	a0, zpWordStart(x0)
		auipc	a1, 0
tSTNW0:		addi	a1, a1, (s_sW0+6)-tSTNW0
		jal	ra, asrtEquals
		ld	a0, zpWordLength(x0)
		addi	a1, x0, 10
		jal	ra, asrtEquals
		jal	ra, scanIsLineExhausted
		jal	ra, asrtIsTrue
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

