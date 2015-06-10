		byte	"NUMBDEC "
testNumbDecimal:
		sd	ra, zpTestPC(x0)
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)
