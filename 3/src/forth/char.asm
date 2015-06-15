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


