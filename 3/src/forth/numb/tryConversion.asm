; Attempt to convert a word into a number.  If the number starts with
; a minus sign, it's taken to be a negative number.
; 
; If an illegal character appears in the input string, an
; ErrNotNumeric error condition is recorded.  This typically
; is used by the interpreter or compiler.
;
; Requirements:
;	zpWordStart(x0)		Points to string to convert.
;	zpWordLength(x0)	The length of the string to convert.
;				Zero is OK.
;	zpBase(x0)		The base of the number to convert.
;				Decimal is 10, hexadecimal is 16, etc.
;				Ignored if the number is prefixed with
;				"$".
;
; Results:
;	zpWordIndex(x0)		Equal to zpWordLength if conversion OK.
;				Otherwise, an illegal character exists
;				in the input.  zpWordStart+zpWordIndex
;				points to the bad character.
;
;	zpValue(x0)		Contains the (64-bit) signed value
;				obtained from the input.


numbTryConversion:
		addi	rp, rp, -16
		sd	rt, 0(rp)
		ld	s0, zpBase(x0)
		sd	s0, 8(rp)
		sd	x0, zpWordIndex(x0)
		sb	x0, zpSign(x0)
		jal	rt, numbNextChar
		ori	a1, x0, 45
		bne	a0, a1, nTC0
		sb	a1, zpSign(x0)
		jal	rt, numbEatChar
nTC0:		jal	rt, numbEitherHexOrDecimal
		lb	a0, zpSign(x0)
		beq	a0, x0, nTC1
		ld	a0, zpValue(x0)
		xori	a0, a0, -1
		addi	a0, a0, 1
		sd	a0, zpValue(x0)
nTC1:		ld	s0, 8(rp)
		sd	s0, zpBase(x0)
		ld	rt, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)
