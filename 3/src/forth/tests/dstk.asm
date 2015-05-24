		byte	"DSTKCBU "
testCheckStackBoundsUnderflow:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		addi	dp, dp, 1
		sd	x0, zpError(x0)
		jal	rt, dstkCheckBounds

		ld	a0, zpError(x0)
		jal	rt, asrtIsTrue

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0,0(rt)

