; Interpret a full line of text.  Under ideal circumstances, this procedure
; never returns, as this is Forth's main "loop."  Since we're running in an
; evented environment, however, it will return, but only to the event-driven
; main loop in the kernel.  Thus, we "loop" by rescheduling ourselves, which
; ointGetAndInterpretLine handles.

ointInterpretLine:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		jal	rt, scanStartLine
oIL3:		ld	t0, zpError(x0)
		bne	t0, x0, oIL0
		jal	rt, scanSkipWhitespace
		jal	rt, scanIsLineExhausted
		bne	a0, x0, oIL0
		jal	rt, scanTakeNextWord	; scanIndex < lineLength AND points to start of lexeme
		jal	rt, dictLocateWord
		jal	rt, dictIsWordFound
		beq	a0, x0, oIL1
		ld	t0, zpWordBody(x0)	; word in dictionary
		jalr	rt, 0(t0)
		jal	x0, oIL2		; dstack in unknown state
oIL1:		jal	ra, numbTryConversion	; word not in dictionary; perhaps a number.
		ld	t0, zpError(x0)
		addi	t1, x0, ErrNotNumeric
		bne	t0, t1, oIL5
		addi	t0, x0, ErrWordNotFound	; Not a number either; definitely unknown word.
		sd	t0, zpError(x0)
		jal	x0, oIL2
oIL5:		addi	dp, dp, -8		; Number confirmed; push onto data stack.
		sd	dt, 0(dp)
		ld	dt, zpValue(x0)
oIL2:		jal	rt, dstkCheckBounds	; dstack in unknown state
		jal	x0, oIL3
oIL0:		ld	t0, zpError(x0)		; error != ErrNone OR scanIndex = lineLength
		beq	t0, x0, oIL4
		jal	rt, dstkReset
		jal	rt, errReport
		sd	x0, zpError(x0)
oIL4:		ld	rt, 0(rp)		; scanIndex = lineLength AND no error AND dstack good
		addi	rp, rp, 8
		jal	x0, ointGetAndInterpretLine

