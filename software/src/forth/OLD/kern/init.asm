;
; Initialize the kernel's runtime state.  We have no execution steps to
; complete, and we are working with a statically allocated step queue of
; 128 elements.  Base address is configured in the file "forth-config.i".
;
; kernInit()
;
; Destroys: A0
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

