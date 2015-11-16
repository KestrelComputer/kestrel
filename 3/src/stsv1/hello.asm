; Hello sample application (ROM-resident).

rombase = $FFFFFFFFFFF00000

	include	"stsapi.inc"

; The meat of the demo.  The initial JAL X0, 0(X1) instruction
; is never actually executed; it merely tells "loadseg" that this is
; a real executable program.

	align	8
start_hello:
	jalr	x0, 0(x1)
	word	0		; Padding to preserve 64-bit alignment
run_hello:
	auipc	gp, 0
	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	addi	dsp, dsp, -16
	addi	x16, gp, msg_hello-run_hello
	sd	x16, 8(dsp)
	addi	x16, x0, len_hello
	sd	x16, 0(dsp)
	ld	x16, 16(dsp)	; X16->STS VTable
	jalr	ra, STS_TYPE(x16)
	ld	x16, 0(dsp)	; X16->STS VTable again
	jalr	ra, STS_CR(x16)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)

	align	8
x_type:	dword	rombase + type
x_cr:	dword	rombase + cr

msg_hello:	byte	"Hello world from STS V1.5!"
len_hello = *-msg_hello

; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_hello:
	dword	rombase+start_hello
prg_hello_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_hello-prg_hello_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

prg_hello_len:
	addi	dsp, dsp, -8
	addi	x16, x0, end_hello-start_hello
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

; If we were to look for multiple romtags, we'd pick up here.

end_hello:
