;
; Perform a single iteration of the kernel's main event loop.
;
; If the step queue is not empty, pop the queue and invoke the
; callback with its associated context.  Otherwise, take no action.
;
; kernEventCycle()
;
; Destroys: A0, A1, plus any registers destroyed by the callback.
;

kernEventCycle:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		jal	rt, kernStepsPending
		beq	a0, x0, kEC_bored

		ld	a1, zpStepQ(x0)
		lhu	a0, zpStepHead(x0)
		slli	a0, a0, 4		; 16 byte queue entry
		add	a1, a1, a0
		jal	rt, kernNextHead
		sh	a0, zpStepHead(x0)
		ld	a0, 0(a1)
		ld	a1, 8(a1)
		jalr	rt, 0(a0)

kEC_bored:	ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

