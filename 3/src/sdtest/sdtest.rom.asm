x0	= 0
ra	= 1
dsp	= 2
rsp	= 3
gp	= 4
gvp	= 5
x16	= 16
x17	= 17
x18	= 18

	include	"sdtest.asm"

	; exit the emulator.

emu_exit:
	andi	x16, x16, 255
	slli	x16, x16, 8
	addi	rsp, rsp, -8
	sd	x16, 0(rsp)
	csrrw	x0, rsp, $780
	jal	x0, *

	; Initialize the BSPL runtime environment.
	; Then, kick off our tests.

_cold:	addi	rsp, x0, $400
	add	dsp, rsp, rsp
	add	gvp, dsp, dsp
	jal	x0, _

	; CPU cold boots here.

	adv	$FFF00, $CC
	jal	x0, _cold
