numbnxtc_setword:
		jal	a0, setword
numbnxtc_word0:	byte	"-1234"
numbnxtc_wordLen = *-numbnxtc_word0
		align	4

		byte	"NUMBNXTC"
testNumbNextChar:
		sd	ra, zpTestPC(x0)
		jal	ra, numbnxtc_setword
		sd	x0, zpWordIndex(x0)
		jal	ra, numbNextChar
		ori	a1, x0, 45
		jal	ra, asrtEquals
		ld	a0, zpWordIndex(x0)
		jal	ra, asrtIsZero
		ori	a0, x0, 3
		sd	a0, zpWordIndex(x0)
		jal	ra, numbNextChar
		ori	a1, x0, $33
		jal	ra, asrtEquals
		ld	a0, zpWordIndex(x0)
		ori	a1, x0, 3
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

