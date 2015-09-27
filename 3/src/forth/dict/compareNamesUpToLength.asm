; Synopsis:
;	result = compareNamesUpToLength(strA, strB, length)
;	  A0                             A0    A1     A2
;
; Compare two memory buffers.  As soon as one discrepency exists, return a
; signed integer, to be interpreted as follows:
;
; < 0 -- string pointed to by A0 collates ahead of string pointed to by A1
; = 0 -- both strings match byte for byte
; > 0 -- string pointed to by A0 collages after string pointed to by A1

compareNamesUpToLength:
		addi	t0, x0, 0
cNUTL0:		bge	t0, a2, cNUTL1
		add	t1, a0, t0		; T1, T2 -> bytes in strings
		add	t2, a1, t0
		lb	t1, 0(t1)		; T1, T2 = bytes in strings
		lb	t2, 0(t2)
		sub	t1, t1, t2		; T1 = difference
		beq	t1, x0, cNUTL2
		addi	a0, t1, 0		; T1 != 0, just return it.
		jalr	x0, 0(ra)
cNUTL2:		addi	t0, t0, 1		; T1 = 0, move to next byte
		jal	x0, cNUTL0
cNUTL1:		addi	a0, x0, 0		; No more chars, must be equal
		jalr	x0, 0(ra)
