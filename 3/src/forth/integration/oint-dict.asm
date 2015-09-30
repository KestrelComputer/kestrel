		include	"../asrt.i"

		align	8
		byte	"OINTDICT"
testOintDict:	jalr	x0, 0(ra)

		align	4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	1
		dword	romBase+testOintDict

		include	"../asrt.asm"
