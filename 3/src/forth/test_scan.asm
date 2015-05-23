romBase = $0FFFFFFFFFFF0000

		include "cpu/regs.i"
		include	"zp.i"
		include "con.asm"

		include "tests/scan.asm"
		include "scan.asm"

		include "tests/char.asm"
		include "char.asm"

		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	9
		dword	testScanStart+romBase
		dword	testScanLineExhausted+romBase
		dword	testScanLineNotExhausted+romBase
		dword	testScanSkipWhitespace+romBase
		dword	testScanMarkWordStart+romBase
		dword	testScanSkipNonSpace+romBase
		dword	testScanMarkWordEnd+romBase
		dword	testScanTakeNextWord+romBase
		dword	testScanSkipAllWhitespace+romBase

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
