zero	= 0
ra	= 1
dsp     = 2    ; Data stack pointer.
rsp     = 3    ; Return stack pointer.
gvp     = 4    ; Global variables pointer.
gp	= 13

dr16	= 5
dr17	= 6
dr18	= 7
dr19	= 8
dr20	= 9
dr21	= 10
dr22	= 11
dr23	= 12

x0	= 0
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
