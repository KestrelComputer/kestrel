; BEGIN BLOCK I/O ============================================
;
; 4KiB of block I/O buffers sits at $1AE00 in this version.
; This base address is answered by the word FIRST.
;
; Each buffer has a corresponding flag byte which indicates
; whether the buffer has been assigned to a block, and/or
; whether the buffer has been modified since it was assigned
; last.  The private word FLAGS gives the address of the first
; byte.
;
; Finally, each buffer has a corresponding block mapping.
; The word BNS returns the address of the 4-vector of Block
; Numbers.
;
; To help implement a crude approximation of a least-recently-
; used algorithm, we need two additional variables.
;
; LAST refers to the last referenced buffer entry (0 <= LAST
; < 4).  This is so UPDATE knows which buffer to mark as dirty.
;
; USED just cycles from buffer to buffer.  This round-robin
; selection of buffers is not a true LRU, but for 99% of the
; use-cases for using blocks, it gives a good enough facsimile.
;
; EMPTY-BUFFERS ( -- ) resets the block I/O system to its
; power-on default state.  All buffers are marked unused.
; Any data which has been modified is lost.
;
; NOTE: in this version of Forth, due to word length
; limitations, you can get away with just EMPTY-BU.  Please
; don't -- use the full name.  You'll thank me later when
; more characters becomes significant in the future.
;
; BUFFER is identical to BLOCK in every way, except that it
; does not fill the buffer from secondary storage.  The
; assumption is that you'll just copy over the entire contents
; of the buffer anyway (e.g., as when copying blocks around),
; so why waste time filling the buffer contents when it's not
; going to be used?
;
; FLUSH will flush all dirty buffers back to storage, and
; mark them clean again.  However, it will not affect the
; state of the cache as a whole (vs. EMPTY-BUFFERS).


	; We use only four bytes of the space reserved for
	; the flags "variable".  Each byte has the following
	; bit meanings:
	;
	; .... ...1	Buffer has been assigned to a block.
	; .... ..1.	Buffer has been modified since filled.
	; 0000 00..	Must be zero.

	align	4
_flags:	jal	W,_dovar
	align	8
	dword	0

	align	4
_bns:	jal	W,_dovar
	align	8
	dword	0,0,0,0

	align	4
last1 = _last1 - _start
_last1:	jal	W,_dovar
	align	8
	dword	3

	align	4
_used:	jal	W,_dovar
	align	8
__used:	dword	0

	align	4
_empty_bufs:
	jal	W,_docol
	hword	lit16, 0, flags, store
	hword	bns, lit16, 4, cells, lit16, 0, fill
	hword	lit16, 3, last1, store, exit

	align	4
_fbic:	jal	W,_docol
	hword	lit16, 0
_fbic_0:
	hword	dup, lit16, 4, is_ge, zgo, _fbic_1
	hword	drop, lit16, 0, exit
_fbic_1:
	hword	dup, flags, plus, cfetch, zgo, _fbic_2
	hword	twodup, cells, bns, plus, fetch, is_eq
	hword	zgo, _fbic_3
	hword	nip, lit16, -1, exit
_fbic_3:
_fbic_2:
	hword	_1plus, go, _fbic_0

	align	4
_ba:	jal	W,_docol
	hword	lit16, 1024, mult, first, plus, exit

	align	4
_snb:	jal	W,_docol
	hword	used, fetch, _1plus, lit16, 3, _and
	hword	used, store, exit

	align	4
_wsect:	; ( n a - erc )  Writes sector 'n' using buffer at 'a'.
	addi	S,S,-8
	sd	T,0(S)
	ld	a0,8(S)
	ld	a1,0(S)
	ld	W,bs_bi-_start(D)
	ld	W,bi_sdmmc_writeblock(W)
	jalr	ra,0(W)
	addi	S,S,16
	jal	x0,next

	align	4
_remount:
	addi	S,S,-8
	sd	T,0(S)
	ld	W,bs_bi-_start(D)
	ld	W,bi_sdmmc_idle(W)
	jalr	ra,0(W)
	ld	T,0(S)
	addi	S,S,8
	jal	x0,next

	align	4
_wb:	jal	W,_docol
	hword	used, fetch, cells, bns, plus, fetch, _2star
	hword	used, fetch, ba, twodup, _wsect, remount, drop
	hword	lit16, 512, plus, swap, _1plus, swap, _wsect, remount, drop
	hword	exit

	align	4
_fb:	jal	W,_docol
	hword	used, fetch, flags, plus, cfetch
	hword	lit16, 2, _and, zgo, _fb_1
	hword	wb, lit16, 2, used, fetch, flags, plus, bclr
_fb_1:	hword	exit

	align	4
_cb:	jal	W,_docol
	hword	lit16, 1, used, fetch, flags, plus, cstore
	hword	used, fetch, cells, bns, plus, store, exit

	align	4
_rsect:	; ( n a - )  Reads sector 'n' into buffer at 'a'.
	addi	S,S,-8
	sd	T,0(S)
	ld	a0,8(S)
	ld	a1,0(S)
	ld	W,bs_bi-_start(D)
	ld	W,bi_sdmmc_readblock(W)
	jalr	ra,0(W)
	addi	S,S,16
	jal	x0,next

	align	4
_lob:	jal	W,_docol
	hword	used, fetch, cells, bns, plus, fetch, _2star
	hword	used, fetch, ba, twodup, _rsect, drop
	hword	lit16, 512, plus, swap, _1plus, swap, _rsect, drop
	hword	exit

	align	4
_block:	jal	W,_docol
	hword	fbic, zgo, _block_1
	hword	dup, last1, store, ba, exit
_block_1:
	hword	snb, fb, cb, lob
	hword	used, fetch, dup, last1, store, ba, exit

	align	4
_buffer:
	jal	W,_docol
	hword	fbic, zgo, _buffer_1
	hword	dup, last1, store, ba, exit
_buffer_1:
	hword	snb, fb, cb
	hword	used, fetch, dup, last1, store, ba, exit

	align	4
_update:
	jal	W,_docol
	hword	lit16, 2, last1, fetch, flags, plus, bset, exit

	align	4
_flush:	jal	W,_docol
	hword	lit16, 0, used, store
	hword	snb, fb, snb, fb, snb, fb, snb, fb, snb, fb, exit

; END BLOCK I/O

