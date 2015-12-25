		align	8
start_prg_testblit:
		jalr	x0, 0(x1)
		word	0
		jal	x0, testBlit

;== REGISTERS ==
;
; The blitter logic is optimized to use a lot of registers,
; to ensure best balance of performance versus convenient
; interface.  These equations will help readability.

bsrcdat	= x16	; data dword from source bitmap
bdstdat	= x17	; data dword from destination bitmap
bsrcprv	= x18	; previous dword from source bitmap
bropfn	= x19	; pointer to raster op function
bshiftl	= x20	; distance to shift left (0 <= bshiftl <= 64)
bshiftr	= x21	; distance to shift right (0 <= bshiftl <= 64)
bcache	= x22	; work register
bsrcadr	= x23	; pointer to next source dword
bdstadr	= x24	; pointer to next destination dword


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

tb1:		auipc	gp, 0
		addi	x16, gp, tbtok-tb1
		addi	x17, x0, tbtoklen
		jal	ra, tbtype
		jal	ra, tbcr

		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

; Test shifting logic.

tbShiftLeft:	jal	x31, tb_i_shltest
		align	8
tbsldata:	dword	$AA000000000000FC	; source data
		dword	$0000000000AAAAAA	; computed destination data
		dword	$5000000000AAAFEA	; expected destination data
		dword	$0000000000000005	; expected previous source value
		dword	tbFn7-tbsldata		; D=D OR S		

tb_i_shltest:	addi	rsp, rsp, -8
		sd	ra, 0(rsp)

		addi	x31, x31, 7		; Ensure X31 points to our control block
		andi	x31, x31, -8

		addi	bsrcadr, x31, 0		; BSRCADR -> source "bitmap" dword
		addi	bdstadr, x31, 8		; BDSTADR -> destination "bitmap" dword
		addi	bsrcprv, x0, 0		; Always initialize to 0.
		addi	bshiftr, x0, 61		; shift 3 bits left; 64-3=61
		addi	bshiftl, x0, 3		; shift 3 bits left
		ld	bropfn, 32(x31)		; compute address of ROP procedure
		add	bropfn, bropfn, x31
		jal	ra, tbDWord		; blit a single dword.

		addi	dsp, dsp, -8
		sd	x31, 0(dsp)

		add	bcache, x31, 0
		beq	bdstadr, bcache, tbdstok
		jal	ra, tb_i_print
		byte	"   shltest: BDSTADR has unexpected value", 13, 10, 0

		align	4
tbdstok:	ld	x31, 0(dsp)
		addi	bcache, x31, -8
		beq	bsrcadr, bcache, tbsrcok
		jal	ra, tb_i_print
		byte	"   shltest: BSRCADR has unexpected value", 13, 10, 0

		align	4
tbsrcok:	ld	x31, 0(dsp)
		ld	bcache, 24(x31)
		beq	bsrcprv, bcache, tbprvok
		jal	ra, tb_i_print
		byte	"   shltest: BSRCPRV has unexpected value", 13, 10, 0

		align	4
tbprvok:	ld	x31, 0(dsp)
		ld	bcache, 8(x31)
		ld	bsrcprv, 16(x31)
		beq	bcache, bsrcprv, tbdatok
		jal	ra, tb_i_print
		byte	"   shltest: Blitted word has unexpected value", 13, 10, 0

		align	4
tbdatok:	addi	dsp, dsp, 8
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

tbDWord:	addi	rsp, rsp, -8
		sd	ra, 0(rsp)

		ld	bcache, 0(bsrcadr)
		addi	bsrcadr, bsrcadr, -8
		sll	bsrcdat, bcache, bshiftl
		or	bsrcdat, bsrcdat, bsrcprv
		srl	bsrcprv, bcache, bshiftr
		ld	bdstdat, 0(bdstadr)
		jalr	ra, 0(bropfn)
		sd	bsrcdat, 0(bdstadr)
		addi	bdstadr, bdstadr, -8

		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

; Test individual raster operations.

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
; They are in MGIA format (big-endian).

mousArrw:	byte	$00, $00 
		byte	$60, $00 
		byte	$78, $00 
		byte	$3E, $00 
		byte	$3F, $80 
		byte	$1F, $E0 
		byte	$1F, $C0 
		byte	$0F, $80 
		byte	$0F, $C0 
		byte	$06, $E0 
		byte	$04, $70 
		byte	$00, $38 
		byte	$00, $18 
		byte	$00, $00 
		byte	$00, $00 
		byte	$00, $00 

mousMask:	byte	$E0, $0A 
		byte	$F8, $00 
		byte	$FE, $00 
		byte	$7F, $80 
		byte	$7F, $E0 
		byte	$3F, $F0 
		byte	$3F, $E0 
		byte	$1F, $C0 
		byte	$1F, $E0 
		byte	$0F, $F0 
		byte	$0E, $F8 
		byte	$04, $7C 
		byte	$00, $3C 
		byte	$00, $18 
		byte	$00, $00
		byte	$00, $00

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

