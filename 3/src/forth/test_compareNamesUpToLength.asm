		include "asrt.i"
		include "dict.asm"
		include "tests/dict/compareNamesUpToLength.asm"
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
		include "asrt.asm"
