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
bmask	= x25	; destination writeback mask


; == SHIFT LEFT LOGIC ==

tbShiftLeft:	jal	x31, tb_i_shltest
		align	8
tbsldata:	dword	$AA000000000000FC	; source data
		dword	$0000000000AAAAAA	; computed destination data
		dword	$0000000000AAAFEA	; expected destination data
		dword	$0000000000000005	; expected previous source value
		dword	tbFn7-tbsldata		; D=D OR S		
		dword	$0000000000FFFFFF	; writeback mask

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
		ld	bmask, 40(x31)		; get writeback mask.
		jal	ra, tbDWordL		; blit a single dword.

		addi	dsp, dsp, -8
		sd	x31, 0(dsp)

		addi	bcache, x31, 0
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

tbDWordL:	addi	rsp, rsp, -8
		sd	ra, 0(rsp)

		ld	bcache, 0(bsrcadr)
		addi	bsrcadr, bsrcadr, -8
		sll	bsrcdat, bcache, bshiftl
		or	bsrcdat, bsrcdat, bsrcprv
		srl	bsrcprv, bcache, bshiftr
		ld	bdstdat, 0(bdstadr)
		xori	bcache, bmask, -1
		and	bcache, bcache, bdstdat
		jalr	ra, 0(bropfn)
		and	bsrcdat, bsrcdat, bmask
		or	bsrcdat, bsrcdat, bcache
		sd	bsrcdat, 0(bdstadr)
		addi	bdstadr, bdstadr, -8

		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

; == SHIFT RIGHT LOGIC ==

tbShiftRight:	jal	x31, tb_i_shrtest
		align	8
tbsldata:	dword	$00000000000000FE	; source data
		dword	$AA00000000AAAAAA	; computed destination data
		dword	$AA00000000AAAA95	; expected destination data
		dword	$8000000000000000	; expected previous source value
		dword	tbFn6-tbsldata		; D=D XOR S		
		dword	$000000000000003F	; writeback mask

tb_i_shrtest:	addi	rsp, rsp, -8
		sd	ra, 0(rsp)

		addi	x31, x31, 7		; Ensure X31 points to our control block
		andi	x31, x31, -8

		addi	bsrcadr, x31, 0		; BSRCADR -> source "bitmap" dword
		addi	bdstadr, x31, 8		; BDSTADR -> destination "bitmap" dword
		addi	bsrcprv, x0, 0		; Always initialize to 0.
		addi	bshiftr, x0, 2		; shift 2 bits right
		addi	bshiftl, x0, 62		; shift 2 bits right; 64-2 = 62
		ld	bropfn, 32(x31)		; compute address of ROP procedure
		add	bropfn, bropfn, x31
		ld	bmask, 40(x31)		; get writeback mask
		jal	ra, tbDwordR		; blit a single dword.

		addi	dsp, dsp, -8
		sd	x31, 0(dsp)

		addi	bcache, x31, 16
		beq	bdstadr, bcache, tbdstok2
		jal	ra, tb_i_print
		byte	"   shrtest: BDSTADR has unexpected value", 13, 10, 0

		align	4
tbdstok2:	ld	x31, 0(dsp)
		addi	bcache, x31, 8
		beq	bsrcadr, bcache, tbsrcok2
		jal	ra, tb_i_print
		byte	"   shrtest: BSRCADR has unexpected value", 13, 10, 0

		align	4
tbsrcok2:	ld	x31, 0(dsp)
		ld	bcache, 24(x31)
		beq	bsrcprv, bcache, tbprvok2
		jal	ra, tb_i_print
		byte	"   shrtest: BSRCPRV has unexpected value", 13, 10, 0

		align	4
tbprvok2:	ld	x31, 0(dsp)
		ld	bcache, 8(x31)
		ld	bsrcprv, 16(x31)
		beq	bcache, bsrcprv, tbdatok2
		jal	ra, tb_i_print
		byte	"   shrtest: Blitted word has unexpected value", 13, 10, 0

		align	4
tbdatok2:	addi	dsp, dsp, 8
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

tbDwordR:	addi	rsp, rsp, -8
		sd	ra, 0(rsp)

		ld	bcache, 0(bsrcadr)
		addi	bsrcadr, bsrcadr, 8
		srl	bsrcdat, bcache, bshiftr
		or	bsrcdat, bsrcdat, bsrcprv
		sll	bsrcprv, bcache, bshiftl
		ld	bdstdat, 0(bdstadr)
		xori	bcache, bmask, -1
		and	bcache, bcache, bdstdat
		jalr	ra, 0(bropfn)
		and	bsrcdat, bsrcdat, bmask
		or	bsrcdat, bsrcdat, bcache
		sd	bsrcdat, 0(bdstadr)
		addi	bdstadr, bdstadr, 8

		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

