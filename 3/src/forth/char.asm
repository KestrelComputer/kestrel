; Return true if, and only if, a character is considered whitespace.

charIsWhitespace:
	addi	t0, x0, 33
	sltu	a0, a0, t0
	jalr	x0, 0(rt)

; Return true if, and only if, a character is a lowercase, ASCII character.

charIsLowercase:
	addi	t0, x0, 97
	bltu	a0, t0, cIL0
	addi	t0, x0, 123
	bgeu	a0, t0, cIL0
	ori	a0, x0, 1
	jalr	x0, 0(rt)
cIL0:	ori	a0, x0, 0
	jalr	x0, 0(rt)

; Map a lowercase character to its uppercase equivalent, if any exists.
; If not, just return the character as-is.

charUpper:
	addi	rp, rp, -8
	sd	rt, 0(rp)
	ori	t1, a0, 0
	jal	ra, charIsLowercase
	beq	a0, x0, cU0
	xori	t1, t1, $20
cU0:	ori	a0, t1, 0
	ld	rt, 0(rp)
	addi	rp, rp, 8
	jalr	x0, 0(rt)

