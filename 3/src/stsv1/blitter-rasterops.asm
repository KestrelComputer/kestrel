tbfF:		jal	x31, tb_i_fntest
		align	8
tbfFdata:	dword	$FFFFFFFFFFFFFFFF
		hword	tbFnF-tbfFdata, $46

tbfE:		jal	x31, tb_i_fntest
		align	8
tbfEdata:	dword	$FFFFAAFF55FF00FF
		hword	tbFnE-tbfEdata, $45

tbfD:		jal	x31, tb_i_fntest
		align	8
tbfDdata:	dword	$00FF55FFAAFFFFFF
		hword	tbFnD-tbfDdata, $44

tbfC:		jal	x31, tb_i_fntest
		align	8
tbfCdata:	dword	$00FF00FF00FF00FF
		hword	tbFnC-tbfCdata, $43

tbfB:		jal	x31, tb_i_fntest
		align	8
tbfBdata:	dword	$FFFFFFAAFF55FF00
		hword	tbFnB-tbfBdata, $42

tbfA:		jal	x31, tb_i_fntest
		align	8
tbfAdata:	dword	$FFFFAAAA55550000
		hword	tbFnA-tbfAdata, $41

tbf9:		jal	x31, tb_i_fntest
		align	8
tbf9data:	dword	$00FF55AAAA55FF00
		hword	tbFn9-tbf9data, $39

tbf8:		jal	x31, tb_i_fntest
		align	8
tbf8data:	dword	$00FF00AA00550000
		hword	tbFn8-tbf8data, $38

tbf7:		jal	x31, tb_i_fntest
		align	8
tbf7data:	dword	$FF00FF55FFAAFFFF
		hword	tbFn7-tbf7data, $37

tbf6:		jal	x31, tb_i_fntest
		align	8
tbf6data:	dword	$FF00AA5555AA00FF
		hword	tbFn6-tbf6data, $36

tbf5:		jal	x31, tb_i_fntest
		align	8
tbf5data:	dword	$00005555AAAAFFFF
		hword	tbFn5-tbf5data, $35

tbf4:		jal	x31, tb_i_fntest
		align	8
tbf4data:	dword	$0000005500AA00FF
		hword	tbFn4-tbf4data, $34

tbf3:		jal	x31, tb_i_fntest
		align	8
tbf3data:	dword	$FF00FF00FF00FF00
		hword	tbFn3-tbf3data, $33

tbf2:		jal	x31, tb_i_fntest
		align	8
tbf2data:	dword	$FF00AA0055000000
		hword	tbFn2-tbf2data, $32

tbf1:		jal	x31, tb_i_fntest
		align	8
tbf1data:	dword	$00005500AA00FF00
		hword	tbFn1-tbf1data, $31

tbf0:		jal	x31, tb_i_fntest
		align	8
tbf0data:	dword	$0000000000000000
		hword	tbFn0-tbf0data, $30

; Perform a raster op test.  Print a diagnostic if the test fails.

tb_i_fntest:	addi	x31, x31, 7		; Point X31 to inline test descriptor.
		andi	x31, x31, -8

		addi	rsp, rsp, -8
		sd	ra, 0(rsp)

tb4:		auipc	gp, 0			; Load standard arguments for function.
		ld	bsrcdat, tbimm_FF00FF00FF00FF00-tb4(gp)
		ld	bdstdat, tbimm_00005555AAAAFFFF-tb4(gp)

		lh	x30, 8(x31)		; Invoke raster op function.
		add	x30, x30, x31
		jalr	ra, 0(x30)

		ld	bdstdat, 0(x31)		; Check for expected result.
		beq	bsrcdat, bdstdat, tbfnok

		lh	x17, 10(x31)		; No match; print diagnostic.
tb5:		auipc	gp, 0
		addi	x16, gp, tbfailmsg-tb5
		sb	x17, 0(x16)
		addi	x17, x0, tbfailmsglen
		jal	ra, tbtype
		jal	ra, tbcr

tbfnok:		ld	ra, 0(rsp)		; Match; return.
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)


; == BLITTER FUNCTIONS ==
; Inputs:	X16	Source image
;		X17	Destination image
; Outputs:	X16	New destination image
;
; NOTE: If you manipulate any other register, you MUST
;	preserve it; this INCLUDES GP.  This is for
;	performance reasons, as to save time, the blitter
;	core will not save registers that it can trust
;	to remain constant.

; D = 0
tbFn0:		addi	bsrcdat, x0, 0
		jalr	x0, 0(ra)

; D = D & S
tbFn1:		and	bsrcdat, bsrcdat, bdstdat
		jalr	x0, 0(ra)

; D = ~D & S
tbFn2:		xori	bdstdat, bdstdat, -1
		and	bsrcdat, bsrcdat, bdstdat
		jalr	x0, 0(ra)

; D = S
tbFn3:		jalr	x0, 0(ra)

; D = D & ~S
tbFn4:		xori	bsrcdat, bsrcdat, -1
		and	bsrcdat, bsrcdat, bdstdat
		jalr	x0, 0(ra)

; D = D
tbFn5:		addi	bsrcdat, bdstdat, 0
		jalr	x0, 0(ra)

; D = D XOR S
tbFn6:		xor	bsrcdat, bsrcdat, bdstdat
		jalr	x0, 0(ra)

; D = S OR D
tbFn7:		or	bsrcdat, bsrcdat, bdstdat
		jalr	x0, 0(ra)

; D = S NOR D
tbFn8:		or	bsrcdat, bsrcdat, bdstdat
		xori	bsrcdat, bsrcdat, -1
		jalr	x0, 0(ra)

; D = S XNOR D
tbFn9:		xor	bsrcdat, bsrcdat, bdstdat
		xori	bsrcdat, bsrcdat, -1
		jalr	x0, 0(ra)

; D = NOT D
tbFnA:		xori	bsrcdat, bdstdat, -1
		jalr	x0, 0(ra)

; D = S OR (NOT D)
tbFnB:		xori	bdstdat, bdstdat, -1
		or	bsrcdat, bsrcdat, bdstdat
		jalr	x0, 0(ra)

; D = NOT S
tbFnC:		xori	bsrcdat, bsrcdat, -1
		jalr	x0, 0(ra)

; D = D OR (NOT S)
tbFnD:		xori	bsrcdat, bsrcdat, -1
		or	bsrcdat, bsrcdat, bdstdat
		jalr	x0, 0(ra)

; D = S NAND D
tbFnE:		and	bsrcdat, bsrcdat, bdstdat
		xori	bsrcdat, bsrcdat, -1
		jalr	x0, 0(ra)

; D = 1
tbFnF:		addi	bsrcdat, x0, -1
		jalr	x0, 0(ra)


