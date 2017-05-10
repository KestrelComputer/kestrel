; Compare two names.  Return < 0 if string 1 collates ahead of string 2,
; 0 if they're equal, or > 0 if string 1 collates after string 2.
;
; result = compareNames(str1, str2, len1, len2)
;   A0                   A0    A1    A2    A3

compareNames:	addi	rp, rp, -16
		sd	rt, 0(rp)
		sd	a2, 8(rp)

		; Compare strings up to the shorter of their two lengths.
		blt	a2, a3, cN_L1
		addi	a2, a3, 0
cN_L1:		jal	rt, compareNamesUpToLength

		; If not equal, we just return the results immediately.
		; Otherwise, all we know is that they have a common prefix.
		bne	a0, x0, cN_L2

		; The strings are truly equal if, and only if, they have
		; common lengths.  Otherwise, the shorter string must collate
		; ahead of the longer.
		ld	a0, 8(rp)
		sub	a0, a0, a3
		
cN_L2:		ld	rt, 0(rp)
		ld	a2, 8(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)
