		align	8
start_prg_testblit:
		jalr	x0, 0(x1)
		word	0
		jal	x0, testBlit

;== DATA ==

		align	8
tbimm_FF00FF00FF00FF00: dword	$FF00FF00FF00FF00
tbimm_00005555AAAAFFFF: dword	$00005555AAAAFFFF

tbfailmsg:	byte	"0: value mismatch"
tbfailmsglen = *-tbfailmsg

;== CODE ==

		align	8

testBlit:	addi	rsp, rsp, -8
		sd	ra, 0(rsp)

		jal	ra, tbdata
		ld	x16, 0(dsp)	; preserve STS jump table
		sd	x16, tb_stsBase(x15)

tb0:		auipc	gp, 0
		addi	x16, gp, tbtann-tb0
		addi	x17, x0, tbtannlen
		jal	ra, tbtype
		jal	ra, tbcr

		jal	ra, tbf0
		jal	ra, tbf1
		jal	ra, tbf2
		jal	ra, tbf3
		jal	ra, tbf4
		jal	ra, tbf5
		jal	ra, tbf6
		jal	ra, tbf7
		jal	ra, tbf8
		jal	ra, tbf9
		jal	ra, tbfA
		jal	ra, tbfB
		jal	ra, tbfC
		jal	ra, tbfD
		jal	ra, tbfE
		jal	ra, tbfF

		jal	ra, tbShiftLeft
		jal	ra, tbShiftRight

		jal	ra, tbMouse

tb1:		auipc	gp, 0
		addi	x16, gp, tbtok-tb1
		addi	x17, x0, tbtoklen
		jal	ra, tbtype
		jal	ra, tbcr

		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

; == MOUSE DISPLAY ==

tbMouse:	addi	rsp, rsp, -8
		sd	ra, 0(rsp)

tbm110:		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)


		include "blitter-dword.asm"
		include	"blitter-rasterops.asm"

; Console I/O.

		align	8
tbfail:		auipc	gp, 0
		addi	x16, gp, tbfailmsg-tbfail
		addi	x17, x0, tbfailmsglen
		jal	ra, tbtype
		jal	ra, tbcr
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

tb_i_print:	addi	rsp, rsp, -8
tb3:		lbu	x16, 0(ra)
		addi	ra, ra, 1
		beq	x16, x0, tb6

		sd	ra, 0(rsp)
		addi	dsp, dsp, -8
		sd	x16, 0(dsp)
		jal	ra, tbdata
		ld	x16, tb_stsBase(x15)
		jalr	ra, STS_EMIT(x16)
		ld	ra, 0(rsp)
		jal	x0, tb3

tb6:		addi	ra, ra, 3
		andi	ra, ra, -4
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

tbtype:		addi	rsp, rsp, -8
		sd	ra, 0(rsp)
		addi	dsp, dsp, -16
		sd	x16, 8(dsp)
		sd	x17, 0(dsp)
		jal	ra, tbdata
		ld	x16, tb_stsBase(x15)
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, STS_TYPE(x16)

tbcr:		addi	rsp, rsp, -8
		sd	ra, 0(rsp)
		jal	ra, tbdata
		ld	x16, tb_stsBase(x15)
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, STS_CR(x16)

; These data are the sprite image and mask.
; They are in host-native format (little-endian).

mousArrw:	dword	$0000 
		dword	$6000 
		dword	$7800 
		dword	$3E00 
		dword	$3F80 
		dword	$1FE0 
		dword	$1FC0 
		dword	$0F80 
		dword	$0FC0 
		dword	$06E0 
		dword	$0470 
		dword	$0038 
		dword	$0018 
		dword	$0000 
		dword	$0000 
		dword	$0000 

mousMask:	dword	$E00A 
		dword	$F800 
		dword	$FE00 
		dword	$7F80 
		dword	$7FE0 
		dword	$3FF0 
		dword	$3FE0 
		dword	$1FC0 
		dword	$1FE0 
		dword	$0FF0 
		dword	$0EF8 
		dword	$047C 
		dword	$003C 
		dword	$0018 
		dword	$0000
		dword	$0000

; Diagnostics

tbtann:		byte	"LIB.blitter:"
tbtannlen = *-tbtann

tbtok:		byte	"ok"
tbtoklen = *-tbtok

; Load X15 with the base address of testBlit's global data.

		align	8
		addi	x0, x0, 0
tbdata:		jalr	x15, 0(ra)
tb__data = *
tb__stsBase:	dword	0

tb_stsBase = tb__stsBase-tb__data

end_prg_testblit:

; Linkage stubs for STS's benefit.  Not part of the application per se.

		align	8
prg_testblit_start:
		auipc	gp, 0
		addi	dsp, dsp, -8
		ld	x16, i_start_testblit-prg_testblit_start(gp)
		sd	x16, 0(dsp)
		jalr	x0, 0(ra)

prg_testblit_len:
		auipc	gp, 0
		addi	dsp, dsp, -8
		ld	x16, i_len_testblit-prg_testblit_len(gp)
		sd	x16, 0(dsp)
		jalr	x0, 0(ra)

		align	8
i_start_testblit:
		dword	rombase+start_prg_testblit
i_len_testblit:	dword	end_prg_testblit-start_prg_testblit

