	include	"stsapi.inc"

	align	8
start_lbutest:
	jalr	x0, 0(x1)
	word	0		; Padding to preserve 64-bit alignment
	jal	x0, run_lbutest

lbudata:
	jalr	x15, 0(ra)
	dword	$80

lbusgn:	byte	"LBU instruction seems to sign-extend."
lbusgnlen = *-lbusgn

lbuuns: byte	"LBU instruction is unsigned."
lbuunslen = *-lbuuns

	align	4
run_lbutest:
	addi	rsp, rsp, -8
	sd	ra, 0(rsp)

	jal	ra, lbudata
	lbu	x16, 0(x15)
	blt	x16, x0, lbu100

lbu50:	auipc	gp, 0
	addi	x16, gp, lbuuns-lbu50
	addi	x17, x0, lbuunslen
lbu70:	addi	dsp, dsp, -16
	sd	x16, 8(dsp)
	sd	x17, 0(dsp)
	ld	x16, 16(dsp)
	jalr	ra, STS_TYPE(x16)
	ld	x16, 0(dsp)
	jalr	ra, STS_CR(x16)

	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)
	
lbu100:	jal	x0, lbu50
	auipc	gp, 0
	addi	x16, gp, lbusgn-lbu100
	addi	x17, x0, lbusgnlen
	jal	x0, lbu70


	align	8
i_start_lbutest:
	dword	rombase+start_lbutest
prg_lbutest_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_lbutest-prg_lbutest_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

prg_lbutest_len:
	addi	dsp, dsp, -8
	addi	x16, x0, end_lbutest-start_lbutest
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

; If we were to look for multiple romtags, we'd pick up here.

end_lbutest:
