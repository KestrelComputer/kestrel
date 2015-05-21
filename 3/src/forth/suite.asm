		include "cpu/regs.i"
		include	"zp.i"

		include "con.asm"

		align	8
start_tests:	or	x0, x0, x0
		jal	ra, L1

		dword	$0E00000000000000

L1:		ld	t0, 0(ra)
		sd	t0, zpUartBase(x0)

		addi	a0, x0, 65
		jal	ra, conEmit
		jal	x0, *

		adv	$FF00, $CC
		jal	x0, start_tests

