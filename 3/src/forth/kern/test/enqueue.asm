		include "../../asrt.i"
		include "../../kern.asm"

; The event-driven kernel works by keeping track of all the execution steps
; that have yet to be completed.  A queue keeps track of not only what needs
; to get done, but as well, in what order.  Things are completed in the
; order they're submitted.

		align	8
		byte	"KINIT   "
testK_init:	addi	rp, rp, -8
		sd	rt, 0(rp)
		jal	rt, kernInit
		jal	rt, kernStepsPending
		jal	rt, asrtIsZero
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; It'd be nice to inspect if the step queue is full.  We actually need it for
; proper operation inside the kernel itself, but sometimes an application can
; make more intelligent scheduling decisions if it can detect a full queue
; ahead of time.

		align	8
		byte	"KQFULL  "
testK_queueFull:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		jal	rt, kernInit
		jal	rt, kernStepQFull
		jal	rt, asrtIsFalse
		addi	a0, x0, 127
		sh	a0, zpStepTail(x0)
		jal	rt, kernStepQFull
		jal	rt, asrtIsTrue

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; To this end, we need a method of submitting a step to perform at some point
; in the future.  The kernel does not guarantee when this step will be
; completed, only that it will eventually do so (assuming it's not cancelled
; and we don't crash along the way).

		align	8
testK_enq_cba:	dword	romBase+testK_enqueue_cb
		byte	"KTODO   "
testK_todo:	addi	rp, rp, -8
		sd	rt, 0(rp)
		sd	x0, zpCalled(x0)
		jal	rt, kernInit

tK_t0:		auipc	gp, 0
		ld	a0, testK_enq_cba-tK_t0(gp)
		addi	a1, x0, $CC
		jal	rt, kernToDo
		jal	rt, asrtIsTrue
		jal	rt, kernStepsPending
		addi	a1, x0, 1
		jal	rt, asrtEquals

		ld	a0, testK_enq_cba-tK_t0(gp)
		addi	a1, x0, $DD
		jal	rt, kernToDo
		jal	rt, asrtIsTrue
		jal	rt, kernStepsPending
		addi	a1, x0, 2
		jal	rt, asrtEquals

		ld	a0, zpCalled(x0)
		jal	rt, asrtIsFalse
		jal	rt, kernEventCycle
		ld	a0, zpCalled(x0)
		addi	a1, x0, $CC
		jal	rt, asrtEquals
		jal	rt, kernStepsPending
		addi	a1, x0, 1
		jal	rt, asrtEquals

		jal	rt, kernEventCycle
		ld	a0, zpCalled(x0)
		addi	a1, x0, $DD
		jal	rt, asrtEquals

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

testK_enqueue_cb:
		sd	a1, zpCalled(x0)
		jalr	x0, 0(rt)
		

; To determine if the queue is empty, you'd use kernStepsPending.
; If zero is returned, you know the queue is empty.  Otherwise, the value
; may be used, e.g., for performance graphing purposes.

		align	8
		byte	"KSPEND  "
testK_stepsPending:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		jal	rt, kernInit
		jal	rt, kernStepsPending
		jal	rt, asrtIsZero

		addi	a0, x0, 3
		sh	a0, zpStepHead(x0)
		sh	a0, zpStepTail(x0)
		jal	rt, kernStepsPending
		jal	rt, asrtIsZero

		sh	x0, zpStepHead(x0)
		jal	rt, kernStepsPending
		addi	a1, x0, 3
		jal	rt, asrtEquals

		addi	a0, x0, 126
		sh	a0, zpStepHead(x0)
		sh	x0, zpStepTail(x0)
		jal	rt, kernStepsPending
		addi	a1, x0, 2
		jal	rt, asrtEquals

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

;
; Suite Definition
;

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	4
		dword	romBase+testK_init
		dword	romBase+testK_queueFull
		dword	romBase+testK_stepsPending
		dword	romBase+testK_todo

		; Must be the very last thing in the ROM image.
		include "../../asrt.asm"
