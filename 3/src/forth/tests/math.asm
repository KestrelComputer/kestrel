		byte	"MATHmNN "
testMathMultiplyNN:
		addi	rp, rp, -16
		sd	ra, 0(rp)

		addi	a0, x0, -5
		addi	a1, x0, -3
		jal	ra, math_multiply
		
		sd	a1, 8(rp)
		ori	a1, x0, 15
		jal	ra, asrtEquals

		; 64-bit GForth gets this totally wrong.
		; It thinks the high dword ought to be -8.
		; But, the result of multiplying two negative numbers
		; is definitely positive.  Zero is the correct
		; value to expect here.

		ld	a0, 8(rp)
		jal	ra, asrtIsZero

		ld	ra, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(ra)


		byte	"MATHmNP "
testMathMultiplyNP:
		addi	rp, rp, -16
		sd	ra, 0(rp)

		addi	a0, x0, -5
		addi	a1, x0, 3
		jal	ra, math_multiply
		
		sd	a1, 8(rp)
		ori	a1, x0, -15
		jal	ra, asrtEquals

		ld	a0, 8(rp)
		ori	a1, x0, -1
		jal	ra, asrtEquals

		ld	ra, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(ra)


		byte	"MATHmPN "
testMathMultiplyPN:
		addi	rp, rp, -16
		sd	ra, 0(rp)

		addi	a0, x0, 5
		addi	a1, x0, -3
		jal	ra, math_multiply
		
		sd	a1, 8(rp)
		ori	a1, x0, -15
		jal	ra, asrtEquals

		ld	a0, 8(rp)
		ori	a1, x0, -1
		jal	ra, asrtEquals

		ld	ra, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(ra)


		byte	"MATHmPP "
testMathMultiplyPP:
		addi	rp, rp, -16
		sd	ra, 0(rp)

		addi	a0, x0, 5
		addi	a1, x0, 3
		jal	ra, math_multiply
		
		sd	a1, 8(rp)
		ori	a1, x0, 15
		jal	ra, asrtEquals

		ld	a0, 8(rp)
		jal	ra, asrtIsZero

		ld	ra, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(ra)
