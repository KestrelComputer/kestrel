;
; Enqueue something to do for later.  We need to provide a callback for the
; kernel to invoke, along with some callback-specific data.
;
; ok = kernToDo(proc, data)
; A0             A0    A1
;
; kernToDo returns non-zero if successful; or, zero if the step queue is full.
;
; kernToDo will not allocate memory; it's safe to call from an interrupt
; handler.
;
; The callback procedure takes two parameters in CPU registers A0 and A1,
; like so:
;
;	callback(self, data)
;		  A0    A1
;
; The callback returns nothing (or, more precisely, the kernel ignores
; whatever you may return).
;
; The callback receives a pointer to itself in register A0.  This is useful
; if you have a table of entry points, all of which refer to a common
; procedure, like so:
;
; _footab:	jal	x0, foo
;		jal	x0, foo
;		jal	x0, foo
;		jal	x0, foo
;
; footab:	dword	_footab
; foo:		; use A0 to calculate which entrypoint dispatched foo.
;		auipc	gp, 0
;		ld	a3, footab-foo(gp)
;		sub	a0, a0, a3
;		srli	a0, a0, 2
;		; 0 <= A0 < 4, providing an index into _footab.
;
; This technique most often finds use in interpreted languages where large
; jump tables are more burdensome to implement than alternative control flows.
;
; Register A1 is used to pass arbitrary data; the kernel does not interpret
; this value in any way.
;
; Destroys: A1
;

kernToDo:	addi	rp, rp, -24
		sd	rt, 0(rp)
		sd	a0, 8(rp)
		sd	a1, 16(rp)

		jal	rt, kernStepQFull
		bne	a0, x0, kTD_full

		ld	a0, zpStepQ(x0)
		lhu	a1, zpStepTail(x0)
		slli	a1, a1, 4		; 16 byte queue entry
		add	a0, a0, a1

		ld	a1, 8(rp)
		sd	a1, 0(a0)
		ld	a1, 16(rp)
		sd	a1, 8(a0)

		jal	rt, kernNextTail
		sh	a0, zpStepTail(x0)
		addi	a0, a0, 1
		jal	x0, kTD_rfs

kTD_full:	addi	a0, x0, 0
kTD_rfs:	ld	rt, 0(rp)
		addi	rp, rp, 24
		jalr	x0, 0(rt)

;
; Answer true if no further steps can be added to the kernel's queue.
;
; full = kernStepQFull()
;  A0
;
; Destroys: A1
;

kernStepQFull:	addi	rp, rp, -8
		sd	rt, 0(rp)

		jal	rt, kernNextTail
		lhu	a1, zpStepHead(x0)
		bne	a0, a1, kSQ_notFull
		addi	a0, x0, 1
kSQ_rfs:	ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

kSQ_notFull:	addi	a0, x0, 0
		jal	x0, kSQ_rfs

;
; Determine the number of steps pending in the kernel's queue.
;
; nevt = kernStepsPending()
;  A0
;
; Destroys: A1 A2
;

kernStepsPending:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		; There are two cases here.  In the most obvious case,
		; the tail exceeds the head in memory, like so:
		;
		;                   |
		; | |#|#|#|#|#| | | |
		;    H         T    |
		;
		; In this case, the number of items in the queue is
		; obviously T-H.  When the reverse is true, however,
		; we have the following situation:
		;
		;                   |
		; |#| | | | | |#|#|#|
		;    T         H    |
		;
		; The easiest way to fix this is to "pretend" that
		; our queue is twice its actual size, and that the tail
		; is actually residing in the 2nd half.
		;
		;                   |
		; |#| | | | | |#|#|#|#| | | | | |#|#|#| 
		;    T         H    |  T'
		;
		; In this case, the number of items in the queue is
		; T'-H.  Note that T'-T = queue max size always.
		;
		; The code below performs a check to see which situation
		; applies, and makes appropriate adjustments.

		jal	rt, kernNextTail	; head < tail+1 ==>
		lhu	a1, zpStepHead(x0)	; head <= tail.
		blt	a1, a0, kSP_nowrap
		ld	a2, zpStepQSize(x0)	; else, head >= tail+1 ==>
		add	a0, a0, a2		; head < tail+qsize+1
kSP_nowrap:	addi	a0, a0, -1		; head < tail(+qsize)
		sub	a0, a0, a1

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; Answer the next tail index.  Note that it does NOT bump the tail.
;
; next = kernNextTail()
;  A0

kernNextTail:	addi	rp, rp, -8
		sd	a1, 0(rp)
		lhu	a0, zpStepTail(x0)
		addi	a0, a0, 1
		lhu	a1, zpStepQSize(x0)
		addi	a1, a1, -1
		and	a0, a0, a1
		ld	a1, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; Answer the next head index.  Note that it does NOT bump the head.
;
; next = kernNextHead()
;  A0

kernNextHead:	addi	rp, rp, -8
		sd	a1, 0(rp)
		lhu	a0, zpStepHead(x0)
		addi	a0, a0, 1
		lhu	a1, zpStepQSize(x0)
		addi	a1, a1, -1
		and	a0, a0, a1
		ld	a1, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

