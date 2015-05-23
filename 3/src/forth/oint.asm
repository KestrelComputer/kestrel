; Interpret a full line of text.  Under ideal circumstances, this procedure
; never returns, as this is Forth's main "loop."  Since we're running in an
; evented environment, however, it will return, but only to the event-driven
; main loop in the kernel.  Thus, we "loop" by rescheduling ourselves, which
; ointGetAndInterpretLine handles.

ointInterpretLine:
		addi	rp, rp, -8
		sd	rt, 0(rp)
oIL3:		jal	rt, scanSkipWhitespace
		jal	rt, scanIsLineExhausted
		bne	a0, x0, oIL0
		jal	rt, scanTakeNextWord
		jal	rt, dictLocateWord
		jal	rt, dictIsWordFound
		beq	a0, x0, oIL1
		; word is found; call it here.
		jal	x0, oIL2
oIL1:		; word is not found; try converting it to a number here.
oIL2:		; perform data stack check here.
		jal	x0, oIL3

oIL0:		ld	rt, 0(rp)
		addi	rp, rp, 8
		jal	x0, ointGetAndInterpretLine

