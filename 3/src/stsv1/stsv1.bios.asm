emit:		addi	rsp, rsp, -32
		sd	ra, 0(rsp)
		sd	a0, 8(rsp)
		sd	a1, 16(rsp)
		sd	a2, 24(rsp)

		addi	a0, x0, 0
		ld	a1, 0(dsp)
		addi	dsp, dsp, 8
		ld	a2, bd_jumptab(x0)
		jalr	ra, BIOS_CHROUT(a2)

		ld	ra, 0(rsp)
		ld	a0, 8(rsp)
		ld	a1, 16(rsp)
		ld	a2, 24(rsp)
		addi	rsp, rsp, 32
		jalr	x0, 0(ra)

caninp:		addi	rsp, rsp, -24
		sd	ra, 0(rsp)
		sd	a0, 8(rsp)
		sd	a1, 16(rsp)

		addi	a0, x0, 2
		ld	a1, bd_jumptab(x0)
		jalr	ra, BIOS_CANINP(a1)
		addi	dsp, dsp, -8
		sd	a0, 0(dsp)

		ld	ra, 0(rsp)
		ld	a0, 8(rsp)
		ld	a1, 16(rsp)
		addi	rsp, rsp, 24
		jalr	x0, 0(ra)

chrinp:		addi	rsp, rsp, -24
		sd	ra, 0(rsp)
		sd	a0, 8(rsp)
		sd	a1, 16(rsp)

		addi	a0, x0, 2
		ld	a1, bd_jumptab(x0)
		jalr	ra, BIOS_CHRINP(a1)
		addi	dsp, dsp, -8
		sd	a0, 0(dsp)

		ld	ra, 0(rsp)
		ld	a0, 8(rsp)
		ld	a1, 16(rsp)
		addi	rsp, rsp, 24
		jalr	x0, 0(ra)
