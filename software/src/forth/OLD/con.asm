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

; Type a hexadecimal 64-bit number
; conPutHex64(n)
;             a0

conPutHex64:	or	s0, ra, x0
		or	t1, a0, x0
		srli	a0, a0, 32
		jal	ra, conPutHex32
		or	a0, t1, x0
		jal	ra, conPutHex32
		or	ra, s0, x0
		jalr	x0, 0(ra)

conPutHex32:	or	s1, ra, x0
		or	t2, a0, x0
		srli	a0, a0, 16
		jal	ra, conPutHex16
		or	a0, t2, x0
		jal	ra, conPutHex16
		or	ra, s1, x0
		jalr	x0, 0(ra)

conPutHex16:	or	s2, ra, x0
		or	t3, a0, x0
		srli	a0, a0, 8
		jal	ra, conPutHex8
		or	a0, t3, x0
		jal	ra, conPutHex8
		or	ra, s2, x0
		jalr	x0, 0(ra)

conPutHex8:	or	s3, ra, x0
		or	t4, a0, x0
		srli	a0, a0, 4
		jal	ra, conPutHex4
		or	a0, t4, x0
		jal	ra, conPutHex4
		or	ra, s3, x0
		jalr	x0, 0(ra)

conPutHex4:	andi	a0, a0, 15
		jal	a1, cPH0
		byte	"0123456789ABCDEF"
cPH0:		add	a0, a0, a1
		lb	a0, 0(a0)
		jal	x0, conEmit

