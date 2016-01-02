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
