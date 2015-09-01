		include "asrt.i"
		include "compareNames.asm"
		include "tests/dict/compareNames.asm"

;
; Dependencies
;

		include "compareNamesUpToLength.asm"

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
		include "asrt.asm"
