; Hello sample application (ROM-resident).

rombase = $FFFFFFFFFFF00000

	include	"stsapi.inc"

; This is a frame-buffer test.  Its purpose is to exercise the MGIA
; framebuffer code in the emulator, and hopefully provide a visual
; confirmation of reasonable performance.
;
; NOTE: This program never returns.

	align	8
start_fbtest:
	jalr	x0, 0(x1)
	word	0		; Padding to preserve 64-bit alignment
run_fbtest:
	auipc	gp, 0
	ld	x16, fbtest_fb-run_fbtest(gp)
	ld	x17, fbtest_fbend-run_fbtest(gp)
	addi	x18, x0, 0

fbtestL100:
	addi	x19, x16, 0
fbtestL101:
	sb	x18, 0(x19)
	addi	x19, x19, 1
	bne	x19, x17, fbtestL101
	addi	x18, x18, 1
	jal	x0, fbtestL100

fbtest_fb:	dword $FF0000
fbtest_fbend:	dword $FF9600


; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_fbtest:
	dword	rombase+start_fbtest
prg_fbtest_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_fbtest-prg_fbtest_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

prg_fbtest_len:
	addi	dsp, dsp, -8
	addi	x16, x0, end_fbtest-start_fbtest
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

; If we were to look for multiple romtags, we'd pick up here.

end_fbtest:
