;
; Initialize the kernel's runtime state.  We have no execution steps to
; complete, and we are working with a statically allocated step queue of
; 128 elements.  Base address is configured in the file "forth-config.i".
;
; kernInit()
;
		align 8
stpqbase:	dword	stepQueue
kernInit:	auipc	gp, 0
		ld	a0, stpqbase-kernInit(gp)
		sd	a0, zpStepQ(x0)
		sh	x0, zpStepHead(x0)
		sh	x0, zpStepTail(x0)
		addi	a0, x0, 128
		sh	a0, zpStepQSize(x0)
		jalr	x0, 0(rt)

kernEventCycle:
kernStepsPending:
		addi	a0, x0, 0
		jalr	x0, 0(rt)

;
; Enqueue something to do for later.  We need to provide a callback for the
; kernel to invoke, along with some callback-specific data.
;
; ok = kernToDo(proc, data)
; A0             A0    A1
;
; kernToDo returns non-zero if successful; or, zero if the step queue is full.
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
; Register A1 is used to pass arbitrary data; the kernel does not interpret
; this value in any way.

kernToDo:	addi	rp, rp, -8
		sd	rt, 0(rp)

		addi	a0, x0, 1

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

;
; Answer true if no further steps can be added to the kernel's queue.
;
; full = kernStepQFull()
;  A0
;

kernStepQFull:	addi	rp, rp, -8
		sd	rt, 0(rp)

		lhu	a0, zpStepTail(x0)
		addi	a0, a0, 1
		lhu	a1, zpStepQSize(x0)
		addi	a1, a1, -1
		and	a0, a0, a1
		lhu	a1, zpStepHead(x0)

		bne	a0, a1, kSQ_notFull
		addi	a0, x0, 1
kSQ_rfs:	ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

kSQ_notFull:	addi	a0, x0, 0
		jal	x0, kSQ_rfs
