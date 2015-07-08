mathMultiply:	addi	sp, sp, -48
		sd	ra, 0(sp)
		sd	t0, 8(sp)
		sd	t1, 16(sp)
		sd	t2, 24(sp)
		sd	t3, 32(sp)
		sd	t4, 40(sp)

		ori	t0, a1, 0		; 128-bit control multiplacand
		srli	t4, a1, 63
		xori	t4, t4, -1
		addi	t4, t4, 1

		ori	t1, a0, 0		; 128-bit partial sum multiplacand
		srli	t2, a0, 63
		xori	t2, t2, -1
		addi	t2, t2, 1

		ori	a0, x0, 0		; Zero product
		ori	a1, x0, 0

m_m_again:	bne	t4, x0, *+8
		beq	t0, x0, m_m_done	; Complete when no more 1 bits exist.
		andi	t3, t0, 1		; Multiplicand odd?
		beq	t3, x0, m_m_even
		add	a0, a0, t1		; Yes, perform 128-bit partial addition.
		add	a1, a1, t2
		bgeu	a0, t1, m_m_even
		addi	a1, a1, 1

m_m_even:	srli	t0, t0, 1
		slli	t3, t4, 63
		or	t0, t0, t3
		srli	t4, t4, 1

		slli	t2, t2, 1
		srli	t3, t1, 63
		or	t2, t2, t3
		slli	t1, t1, 1

		jal	x0, m_m_again

m_m_done:	ld	ra, 0(sp)
		ld	t0, 8(sp)
		ld	t1, 16(sp)
		ld	t2, 24(sp)
		ld	t3, 32(sp)
		ld	t4, 40(sp)
		addi	sp, sp, 48
		jalr	x0, 0(ra)


mathUDivMod:	addi	sp, sp, -48
		sd	ra, 0(sp)
		sd	a2, 8(sp)
		sd	t0, 16(sp)
		sd	t1, 24(sp)
		sd	t2, 32(sp)
		sd	t3, 40(sp)

		addi	t0, x0, 0		; Quotient
		addi	t1, x0, 0		; Remainder
		addi	t3, x0, 128		; Our input (A1:A0) has 128 bits
mUDM0:		beq	t3, x0, mUDM1		; While we have bits to process...

		slli	t1, t1, 1		;   Shift R:N as a 192-bit quantity left 1 bit
		srli	t2, a1, 63
		or	t1, t1, t2
		slli	a1, a1, 1
		srli	t2, a0, 63
		or	a1, a1, t2
		slli	a0, a0, 1

		slli	t0, t0, 1		;  Shift quotient left by 1 too.
		bltu	t1, a2, mUDM2		;  If we can subtract, then
		sub	t1, t1, a2		;    Perform subtraction off of remainder.
		ori	t0, t0, 1		;    Account for it in the quotient.

mUDM2:		addi	t3, t3, -1		;  Repeat for all bits.
		jal	x0, mUDM0

mUDM1:		ori	a0, t0, 0
		ori	a1, t1, 0
		ld	ra, 0(sp)
		ld	a2, 8(sp)
		ld	t0, 16(sp)
		ld	t1, 24(sp)
		ld	t2, 32(sp)
		ld	t3, 40(sp)
		addi	sp, sp, 48
		jalr	x0, 0(ra)


mathSDivMod:	addi	sp, sp, -32
		sd	ra, 0(sp)
		sd	a1, 8(sp)		; preserve sign of numerator
		sd	a2, 16(sp)		; preserve sign of denominator

		bge	a1, x0, mSDM_a1pos	; Take absolute value of A1:A0
		xori	a1, a1, -1
		xori	a0, a0, -1
		addi	a0, a0, 1
		bgeu	a0, x0, mSDM_a1pos
		addi	a1, a1, 1

mSDM_a1pos:	bge	a2, x0, mSDM_a2pos	; Take absolute value of A2
		xori	a2, a2, -1
		addi	a2, a2, 1

mSDM_a2pos:	jal	ra, mathUDivMod		; perform the core division

		ld	t0, 16(sp)
		bge	t0, x0, mSDM_dpos
		xori	a1, a1, -1
		addi	a1, a1, 1

mSDM_dpos:
		ld	ra, 0(sp)
		ld	a2, 16(sp)
		addi	sp, sp, 32
		jalr	x0, 0(ra)

