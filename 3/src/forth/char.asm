; Return true if, and only if, a character is considered whitespace.

charIsWhitespace:
	addi	t0, x0, 32
	sltu	a0, a0, t0
	jalr	x0, 0(ra)

