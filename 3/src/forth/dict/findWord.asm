; Locate a word in the dictionary vocabulary pointed at by zpContext.
; If not found, return with A0=0.  Otherwise, A0 will point at the
; word header.  This may be treated as an execution token in Forth.
;
; xt = dictFindWord(sptr, slen)
; A0                 A0    A1

dictFindWord:	addi	rp, rp, -48
		sd	rt, 0(rp)
		sd	a0, 8(rp)
		sd	a1, 16(rp)
		sd	s4, 24(rp)	; pointer to current header
		sd	a2, 32(rp)
		sd	a3, 40(rp)

		ld	s4, zpContext(x0)
dfwAgain:	beq	s4, x0, dfwNotFound
		ld	a0, wh_name(s4)	; header name
		ld	a2, wh_len(s4)	; header name length
		ld	a1, 8(rp)	; key name
		ld	a3, 16(rp)	; key name length
		jal	ra, compareNames
		beq	a0, x0, dfwFound
		ld	s4, wh_next(s4)
		jal	x0, dfwAgain

dfwNotFound:	addi	a0, x0, 0
dfwExit:	ld	rt, 0(rp)
		ld	a1, 16(rp)
		ld	s4, 24(rp)
		ld	a2, 32(rp)
		ld	a3, 40(rp)
		addi	rp, rp, 48
		jalr	x0, 0(rt)

dfwFound:	addi	a0, s4, 0
		jal	x0, dfwExit
