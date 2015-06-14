math_multiply:	addi	rp, rp, -40
		sd	rt, 0(rp)
		sd	t0, 8(rp)
		sd	t1, 16(rp)
		sd	t2, 24(rp)
		sd	t3, 32(rp)

		ori	t0, a1, 0		; 64-bit control multiplacand
		ori	t1, a0, 0		; 128-bit partial sum multiplacand
		srli	t2, a0, 63
		xori	t2, t2, -1
		addi	t2, t2, 1

		ori	a0, x0, 0		; Zero product
		ori	a1, x0, 0

m_m_again:
		beq	t0, x0, m_m_done	; Complete when no more 1 bits exist.
		andi	t3, t0, 1		; Multiplicand odd?
		beq	t3, x0, m_m_even
		add	a0, a0, t1		; Yes, perform 128-bit partial addition.
		add	a1, a1, t2
		bgeu	a0, t1, m_m_even
		addi	a1, a1, 1
m_m_even:
		srli	t0, t0, 1
		slli	t2, t2, 1
		bge	t1, x0, *+4
		ori	t2, t2, 1
		slli	t1, t1, 1
		jal	x0, m_m_again

m_m_done:
		ld	rt, 0(rp)
		ld	t0, 8(rp)
		ld	t1, 16(rp)
		ld	t2, 24(rp)
		ld	t3, 32(rp)
		addi	rp, rp, 40
		jalr	x0, 0(rt)
