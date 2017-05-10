		include "../../asrt.i"
		include "../../dict.asm"

; We expect two zero-length strings to be considered equal, regardless of
; where the string pointers point.

		byte	"CNE     "
testCN_empty:
		addi	rp, rp, -8
		sd	rt, 0(rp)

		auipc	a0, 0		; A0 = non-nil pointer
		auipc	a1, 0		; A1 = different non-nil pointer
		addi	a2, x0, 0	; but both of length 0.
		addi	a3, x0, 0
		jal	rt, compareNames
		jal	rt, asrtIsFalse

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


; We expect string 0 to be "less than" string 1 if string 0 collates ahead
; of string 1 in a dictionary, per USA conventions.

		byte	"CNA     "
testCN_above:
		addi	rp, rp, -8
		sd	rt, 0(rp)

testCN_L0:	auipc	a1, 0		; A0 = strA, A1 = strB
		addi	a0, a1, testCN_strA - testCN_L0
		addi	a1, a1, testCN_strB - testCN_L0
		addi	a2, x0, 8	; Both strings are at least 8 chars
		addi	a3, x0, 8
		jal	rt, compareNames
		jal	rt, asrtLTZero

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

		align	8
testCN_strA:	byte	"AAAAAAAB"
testCN_strB:	byte	"AAAAAAAC"


; We expect string 0 to be "greater than" string 1 if string 0 collates after
; or, "behind", string 1 in a dictionary, per USA conventions.

		byte	"CNB     "
testCN_behind:
		addi	rp, rp, -8
		sd	rt, 0(rp)

testCN_L1:	auipc	a0, 0		; A1 = strA, A0 = strB
		addi	a1, a0, testCN_strA - testCN_L1
		addi	a0, a0, testCN_strB - testCN_L1
		addi	a2, x0, 8	; Both strings are at least 8 chars
		addi	a3, x0, 8
		jal	rt, compareNames
		jal	rt, asrtGTZero

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; We expect string 0 to be "equal to" string 1 if string 0 collates to the
; same place as string 1 in a dictionary.

		byte	"CNC     "
testCN_common:
		addi	rp, rp, -8
		sd	rt, 0(rp)

testCN_L2:	auipc	a0, 0		; A1 = strA, A0 = strB
		addi	a1, a0, testCN_strA - testCN_L2
		addi	a0, a0, testCN_strB - testCN_L2
		addi	a2, x0, 7	; Both strings common up to 7 chars.
		addi	a3, x0, 7
		jal	rt, compareNames
		jal	rt, asrtIsZero

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; We expect shorter strings to collate ahead of longer strings.

		byte	"CNS     "
testCN_shorter:
		addi	rp, rp, -8
		sd	rt, 0(rp)

testCN_L3:	auipc	a3, 0		; A0 = strA, A1 = strB
		addi	a0, a3, testCN_strA - testCN_L3
		addi	a1, a3, testCN_strA - testCN_L3
		addi	a2, x0, 6	; A2 = length A, A3 = length B
		addi	a3, x0, 7	; A2 = length A, A3 = length B
		jal	rt, compareNames
		jal	rt, asrtLTZero

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; We expect longer strings to collate ahead of shorter strings.

		byte	"CNL     "
testCN_longer:
		addi	rp, rp, -8
		sd	rt, 0(rp)

testCN_L4:	auipc	a3, 0		; A0 = strA, A1 = strB
		addi	a0, a3, testCN_strA - testCN_L4
		addi	a1, a3, testCN_strA - testCN_L4
		addi	a2, x0, 7	; A2 = length A, A3 = length B
		addi	a3, x0, 6	; A2 = length A, A3 = length B
		jal	rt, compareNames
		jal	rt, asrtGTZero

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


;
; Suite Definition
;

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	6
		dword	romBase+testCN_empty
		dword	romBase+testCN_above
		dword	romBase+testCN_behind
		dword	romBase+testCN_common
		dword	romBase+testCN_shorter
		dword	romBase+testCN_longer

		; Must be the very last thing in the ROM image.
		include "../../asrt.asm"
