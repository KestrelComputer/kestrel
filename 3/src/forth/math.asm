math_multiply:	addi	rp, rp, -48
		sd	rt, 0(rp)
		sd	t0, 8(rp)
		sd	t1, 16(rp)
		sd	t2, 24(rp)
		sd	t3, 32(rp)
		sd	t4, 40(rp)

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

m_m_done:	ld	rt, 0(rp)
		ld	t0, 8(rp)
		ld	t1, 16(rp)
		ld	t2, 24(rp)
		ld	t3, 32(rp)
		ld	t4, 40(rp)
		addi	rp, rp, 48
		jalr	x0, 0(rt)
