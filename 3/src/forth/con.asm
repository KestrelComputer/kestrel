; Emit a character to the console.
; conEmit(ch)
;         a0

conEmit:	ld	t0, zpUartBase(x0)
		sb	a0, 0(t0)
		jalr	x0, 0(ra)

; Type a counted string to the console.
; conType(msg, len)
;         a0   a1

conType:	or	t1, a0, x0
		or	t2, ra, x0
cT1:		beq	a1, x0, cT2	; len >= 0
		lb	a0, 0(t1)	; len > 0
		jal	ra, conEmit
		addi	t1, t1, 1
		addi	a1, a1, -1	; len > 0 ==> len-1 >= 0
		jal	x0, cT1		; len >= 0 (matches loop invariant)
cT2:		jalr	x0, 0(t2)	; len = 0

