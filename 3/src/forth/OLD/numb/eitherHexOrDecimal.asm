; Sets zpValue(x0) to the binary representation of the number.
; If the number starts with a '$', it's treated as if it were
; a hexadecimal value, regardless of the current base setting.
;
; If an illegal character appears in the input string, an
; ErrNotNumeric error condition is recorded.  This typically
; is used by the interpreter or compiler.
;
; Requirements:
;	zpWordStart(x0)		Points to string to convert.
;	zpWordIndex(x0)		Where to begin numeric conversion from.
;				zpWordIndex <= zpWordLength.
;				Typically set to 0.
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
;	zpValue(x0)		Contains the (64-bit) unsigned value
;				obtained from the input.

numbEitherHexOrDecimal:
		addi	rp, rp, -16
		sd	rt, 0(rp)
		ld	a0, zpBase(x0)
		sd	a0, 8(rp)

		jal	ra, numbNextChar
		addi	a1, x0, 36
		bne	a0, a1, nEHOD_assumeDec
		jal	ra, numbEatChar
		addi	a0, x0, 16
		sd	a0, zpBase(x0)
nEHOD_assumeDec:
		jal	rt, numbTryUnsignedNumber

		ld	a0, zpWordIndex(x0)
		ld	a1, zpWordLength(x0)
		bge	a0, a1, nEHOD_isnumber
		addi	a0, x0, ErrNotNumeric
		sd	a0, zpError(x0)

nEHOD_isnumber: ld	a0, 8(rp)
		sd	a0, zpBase(x0)
		ld	rt, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)
