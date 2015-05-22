; Is a character whitespace?  We define whitespace as any character c that
; satisfies the inequality 0 <= c < 33.  This definition is obviously ASCII-
; specific, and completely ignores Unicode concerns.

		byte	"charIsWS"
testCharIsWhitespace:
		sd	ra, zpTestPC(x0)
		or	s6, x0, x0
tIW1:		addi	s7, x0, 33
		beq	s6, s7, tIW0
		or	a0, s6, x0
		jal	ra, charIsWhitespace
		jal	ra, asrtIsTrue
		addi	s6, s6, 1
		jal	x0, tIW1
tIW0:		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)


; Is a character NOT a whitespace?

		byte	"charNoWS"
testCharIsNotWhitespace:
		sd	ra, zpTestPC(x0)
		addi	s6, x0, 33
tINW1:		beq	s6, x0, tINW0
		or	a0, s6, x0
		jal	ra, charIsWhitespace
		jal	ra, asrtIsFalse
		addi	s6, s6, 1
		andi	s6, s6, 255
		jal	x0, tINW1
tINW0:		ld	ra, zpTestPC(x0)
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)
