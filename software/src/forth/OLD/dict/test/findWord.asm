		include "../../asrt.i"
		include "../../dict.asm"

; All the tests below will use the same chain of "words".

testFW_name2:	byte	"foo"
testFW_len2	= *-testFW_name2

testFW_name1:	byte	"bar"
testFW_len1	= *-testFW_name1

		align	8
testFW_hdr2:	dword	0, romBase+testFW_name2, testFW_len2

testFW_setContext_:
		sd	a0, zpContext(x0)
		jalr	x0, 0(ra)
testFW_setContext:
		addi	x0, x0, 0
		jal	a0, testFW_setContext_

testFW_hdr1:	dword	romBase+testFW_hdr2, romBase+testFW_name1, testFW_len1

; When looking for a word that is not in the current vocabulary,
; we expect to get nothing back.

testFW_badName:	byte	"blort   "
		byte	"FWNEXIST"
testFW_notExist:
		addi	rp, rp, -8
		sd	rt, 0(rp)
		jal	rt, testFW_setContext
testFW_LGP0:	auipc	a0, 0
		addi	a0, a0, testFW_badName-testFW_LGP0
		addi	a1, x0, 5
		jal	rt, dictFindWord
		jal	rt, asrtIsFalse
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; We should be able to find the word currently being pointed at by the context
; pointer.

testFW_firstName:
		byte	"bar     "
		byte	"FWEXIST1"
testFW_exist1:	addi	rp, rp, -8
		sd	rt, 0(rp)
		jal	rt, testFW_setContext
testFW_LGP1:	auipc	a0, 0
		addi	a0, a0, testFW_firstName-testFW_LGP1
		addi	a1, x0, 3
		jal	rt, dictFindWord
testFW_LGP2:	auipc	a1, 0
		addi	a1, a1, testFW_hdr1-testFW_LGP2
		jal	rt, asrtEquals
		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)

; We should be able to find the word anywhere in the vocabulary chain.

testFW_anyName:
		byte	"foo     "
		byte	"FWEXISTN"
testFW_existN:	addi	rp, rp, -8
		sd	rt, 0(rp)
		jal	rt, testFW_setContext
testFW_LGP3:	auipc	a0, 0
		addi	a0, a0, testFW_anyName-testFW_LGP3
		addi	a1, x0, 3
		jal	rt, dictFindWord
testFW_LGP4:	auipc	a1, 0
		addi	a1, a1, testFW_hdr2-testFW_LGP4
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
		dword	3
		dword	romBase+testFW_notExist
		dword	romBase+testFW_exist1
		dword	romBase+testFW_existN
;		dword	romBase+testCN_common
;		dword	romBase+testCN_shorter
;		dword	romBase+testCN_longer

		; Must be the very last thing in the ROM image.
		include "../../asrt.asm"
