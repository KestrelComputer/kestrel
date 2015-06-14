; Attempt to convert a number in string form into binary form.
; Sets zpValue(x0) to the binary representation of the number.
;
; If any characters appear in the input which cannot be converted,
; the conversion process will abort early, leaving zpWordIndex(x0)
; less than zpWordLength(x0).  Additionally, zpValue(x0) will be
; set to the value of the number converted up to that point.
;
; Except for Forth VM registers, consider all registers destroyed
; after this procedure returns.
;
; Requirements:
;	zpWordStart(x0)		Points to string to convert.
;	zpWordIndex(x0)		Where to begin numeric conversion from.
;				zpWordIndex <= zpWordLength.
;	zpWordLength(x0)	The length of the string to convert.
;				Zero is OK.
;	zpBase(x0)		The base of the number to convert.
;				Decimal is 10, hexadecimal is 16, etc.
;
; Results:
;	zpWordIndex(x0)		Equal to zpWordLength if conversion OK.
;				Otherwise, an illegal character exists
;				in the input.  zpWordStart+zpWordIndex
;				points to the bad character.
;
;	zpValue(x0)		Contains the (64-bit) unsigned value
;				obtained from the input.

numbTryUnsignedNumber:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		sd	x0, zpValue(x0)

nTUN2:		ld	a0, zpWordIndex(x0)
		ld	a1, zpWordLength(x0)
		bge	a0, a1, nTUN0

		jal	rt, numbNextChar
		ori	t1, a0, 0
		jal	rt, numbEatChar

		addi	t1, t1, -48
		ld	a1, zpBase(x0)
		bltu	t1, a1, nTUN1

		ld	a0, zpWordIndex(x0)
		addi	a0, a0, -1
		sd	a0, zpWordIndex(x0)
		jal	x0, nTUN0

nTUN1:		ld	a0, zpValue(x0)
		jal	rt, math_multiply
		add	a0, a0, t1
		sd	a0, zpValue(x0)
		jal	x0, nTUN2

nTUN0:		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

