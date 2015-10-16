		include "../asrt.i"
		include "../err.asm"
		include "../dstk.asm"

; Data stack underflow check.

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


; Data stack overflow check.

		byte	"DSTKCBO "
testCheckStackBoundsOverflow:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		ld	dp, zpDPL(x0)
		addi	dp, dp, -1
		sd	x0, zpError(x0)
		jal	rt, dstkCheckBounds

		ld	a0, zpError(x0)
		jal	rt, asrtIsTrue

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0,0(rt)

; Reset data stack pointer.

		byte	"DSTK0000"
testDstkReset:	addi	rp, rp, -8
		sd	rt, 0(rp)
		auipc	dp, 0
		jal	rt, dstkReset
		or	a0, dp, x0
		ld	a1, zpDP0(x0)
		jal	rt, asrtEquals
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	3
		dword	romBase+testCheckStackBoundsUnderflow
		dword	romBase+testCheckStackBoundsOverflow
		dword	romBase+testDstkReset

		; Must be the very last thing in the ROM image.
		include "../asrt.asm"
