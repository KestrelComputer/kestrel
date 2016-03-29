		include "../../asrt.i"
		include "../../dict.asm"

; We expect two zero-length strings to be considered equal, regardless of
; where the string pointers point.

		byte	"CNUTLE  "
testCNUTL_empty:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		auipc	a0, 0		; A0 = non-nil pointer
		auipc	a1, 0		; A1 = different non-nil pointer
		addi	a2, x0, 0	; but both of length 0.
		jal	rt, compareNamesUpToLength
		jal	rt, asrtIsFalse

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


; We expect string 0 to be "less than" string 1 if string 0 collates ahead
; of string 1 in a dictionary, per USA conventions.

		byte	"CNUTLA  "
testCNUTL_above:
		addi	rp, rp, -8
		sd	rt, 0(rp)

testCNUTL_L0:	auipc	a1, 0		; A0 = strA, A1 = strB
		addi	a0, a1, testCNUTL_strA - testCNUTL_L0
		addi	a1, a1, testCNUTL_strB - testCNUTL_L0
		addi	a2, x0, 8	; Both strings are at least 8 chars
		jal	rt, compareNamesUpToLength
		jal	rt, asrtLTZero

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

		align	8
testCNUTL_strA:	byte	"AAAAAAAB"
testCNUTL_strB:	byte	"AAAAAAAC"


; We expect string 0 to be "greater than" string 1 if string 0 collates after
; or, "behind", string 1 in a dictionary, per USA conventions.

		byte	"CNUTLB  "
testCNUTL_behind:
		addi	rp, rp, -8
		sd	rt, 0(rp)

testCNUTL_L1:	auipc	a0, 0		; A1 = strA, A0 = strB
		addi	a1, a0, testCNUTL_strA - testCNUTL_L1
		addi	a0, a0, testCNUTL_strB - testCNUTL_L1
		addi	a2, x0, 8	; Both strings are at least 8 chars
		jal	rt, compareNamesUpToLength
		jal	rt, asrtGTZero

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; We expect string 0 to be "equal to" string 1 if string 0 collates to the
; same place as string 1 in a dictionary.

		byte	"CNUTLC  "
testCNUTL_common:
		addi	rp, rp, -8
		sd	rt, 0(rp)

testCNUTL_L2:	auipc	a0, 0		; A1 = strA, A0 = strB
		addi	a1, a0, testCNUTL_strA - testCNUTL_L2
		addi	a0, a0, testCNUTL_strB - testCNUTL_L2
		addi	a2, x0, 7	; Both strings common up to 7 chars.
		jal	rt, compareNamesUpToLength
		jal	rt, asrtIsZero

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
		dword	romBase+testCNUTL_empty
		dword	romBase+testCNUTL_above
		dword	romBase+testCNUTL_behind
		dword	romBase+testCNUTL_common

		; Must be the very last thing in the ROM image.
		include "../../asrt.asm"
