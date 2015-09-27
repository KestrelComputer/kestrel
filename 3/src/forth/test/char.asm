		include "../asrt.i"
		include "../char.asm"

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

; Is a character a lowercase letter?

		byte	"charLCLp"
testCharIsLowercasePositive:
		sd	ra, zpTestPC(x0)
		addi	s6, x0, 97
		addi	s5, x0, 123
tCIL0:		beq	s6, s5, tCIL1
		ori	a0, s6, 0
		jal	ra, charIsLowercase
		jal	ra, asrtIsTrue
		addi	s6, s6, 1
		jal	x0, tCIL0
tCIL1:		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

		byte	"charLCnL"
testCharIsLowercaseNegativeLow:
		sd	ra, zpTestPC(x0)
		addi	s6, x0, 0
		addi	s5, x0, 97
tCIL0:		beq	s6, s5, tCIL1
		ori	a0, s6, 0
		jal	ra, charIsLowercase
		jal	ra, asrtIsFalse
		addi	s6, s6, 1
		jal	x0, tCIL0
tCIL1:		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

		byte	"charLCnH"
testCharIsLowercaseNegativeHigh:
		sd	ra, zpTestPC(x0)
		addi	s6, x0, 123
		addi	s5, x0, 256
tCIL0:		beq	s6, s5, tCIL1
		ori	a0, s6, 0
		jal	ra, charIsLowercase
		jal	ra, asrtIsFalse
		addi	s6, s6, 1
		jal	x0, tCIL0
tCIL1:		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; Map all lowercase letters to uppercase.

		byte	"charUppr"
testCharUpper:	sd	ra, zpTestPC(x0)

		addi	s5, x0, 0
		addi	s6, x0, 97
tCU0:		beq	s5, s6, tCU1
		ori	a0, s5, 0
		jal	ra, charUpper
		ori	a1, s5, 0
		jal	ra, asrtEquals
		addi	s5, s5, 1
		jal	x0, tCU0

tCU1:		addi	s6, x0, 123
		addi	s4, x0, 65
tCU2:		beq	s5, s6, tCU3
		ori	a0, s5, 0
		jal	ra, charUpper
		ori	a1, s4, 0
		jal	ra, asrtEquals
		addi	s5, s5, 1
		addi	s4, s4, 1
		jal	x0, tCU2

tCU3:		addi	s6, x0, 256
tCU4:		beq	s5, s6, tCU5
		ori	a0, s5, 0
		jal	ra, charUpper
		ori	a1, s5, 0
		jal	ra, asrtEquals
		addi	s5, s5, 1
		jal	x0, tCU4

tCU5:		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	6
		dword	testCharIsWhitespace+romBase
		dword	testCharIsNotWhitespace+romBase
		dword	testCharIsLowercasePositive+romBase
		dword	testCharIsLowercaseNegativeLow+romBase
		dword	testCharIsLowercaseNegativeHigh+romBase
		dword	testCharUpper+romBase

		; Must be the very last thing in the ROM image.
		include "../asrt.asm"
