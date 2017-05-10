; A valid, if bogus, RomTag

rt1fmsg:	byte	"   rt1"
rt1flen		= *-rt1fmsg

		align	8
validrt:	word	$c0de0000, $0000da7a, 1, $FFFFFFFF-($c0de0000+$da7a+9)
		word	1, 1, 1, 1
		word	1, 1, 1, 1

; Given an address to a valid RomTag, isromtag should yield true.

		align	4
rt1:		auipc	gp, 0
		addi	rsp, rsp, -8
		sd	ra, 0(rsp)
		addi	dsp, dsp, -8		; addr of romtag
		addi	x16, gp, validrt-rt1
		sd	x16, 0(dsp)
		jal	ra, isromtag		; check
		ld	x16, 0(dsp)		; zero if failed
		beq	x16, x0, rt1fail
		addi	dsp, dsp, 8		; pass
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

rt1fail:	auipc	gp, 4
		addi	dsp, dsp, -8		; print failure msg
		addi	x16, gp, rt1fmsg-rt1fail
		sd	x16, 8(dsp)
		addi	x16, x0, rt1flen
		sd	x16, 0(dsp)
		jal	ra, type
		jal	ra, cr
		jal	x0, bye

; Given an address to a RomTag with a bad checksum, isromtag should
; yield false.

rt2fmsg:	byte	"   rt2"
rt2flen		= *-rt2fmsg

		align	8
invalidrt:	word	$c0de0000, $0000da7a, 0, $FFFFFFFF-($c0de0000+$da7a+9)
		word	1, 1, 1, 1
		word	1, 1, 1, 1

		align	4
rt2:		auipc	gp, 0
		addi	rsp, rsp, -8
		sd	ra, 0(rsp)
		addi	dsp, dsp, -8
		addi	x16, gp, invalidrt-rt2
		sd	x16, 0(dsp)
		jal	ra, isromtag
		ld	x16, 0(dsp)
		bne	x16, x0, rt2fail
		addi	dsp, dsp, 8
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)
rt2fail:	auipc	gp, 0
		addi	dsp, dsp, -8
		addi	x16, gp, rt2fmsg-rt2fail
		sd	x16, 8(dsp)
		addi	x16, x0, rt2flen
		sd	x16, 0(dsp)
		jal	ra, type
		jal	ra, cr
		jal	x0, bye

; Given an address to a RomTag with a bad matchword, isromtag should
; yield false.

rt3fmsg:	byte	"   rt3"
rt3flen		= *-rt3fmsg

		align	8
invalidrt2:	word	$c0de0001, $0000da7a, 0, $FFFFFFFF-($c0de0000+$da7a+9)
		word	1, 1, 1, 1
		word	1, 1, 1, 1

		align	4
rt3:		auipc	gp, 0
		addi	rsp, rsp, -8
		sd	ra, 0(rsp)
		addi	dsp, dsp, -8
		addi	x16, gp, invalidrt2-rt3
		sd	x16, 0(dsp)
		jal	ra, isromtag
		ld	x16, 0(dsp)
		bne	x16, x0, rt3fail
		addi	dsp, dsp, 8
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)
rt3fail:	auipc	gp, 0
		addi	dsp, dsp, -8
		addi	x16, gp, rt3fmsg-rt3fail
		sd	x16, 8(dsp)
		addi	x16, x0, rt3flen
		sd	x16, 0(dsp)
		jal	ra, type
		jal	ra, cr
		jal	x0, bye

; Given an address to a RomTag with a bad matchword, isromtag should
; yield false.

rt4fmsg:	byte	"   rt4"
rt4flen		= *-rt4fmsg

		align	8
invalidrt3:	word	$c0de0000, $0001da7a, 0, $FFFFFFFF-($c0de0000+$da7a+9)
		word	1, 1, 1, 1
		word	1, 1, 1, 1

		align	4
rt4:		auipc	gp, 0
		addi	rsp, rsp, -8
		sd	ra, 0(rsp)
		addi	dsp, dsp, -8
		addi	x16, gp, invalidrt3-rt4
		sd	x16, 0(dsp)
		jal	ra, isromtag
		ld	x16, 0(dsp)
		bne	x16, x0, rt4fail
		addi	dsp, dsp, 8
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)
rt4fail:	auipc	gp, 0
		addi	dsp, dsp, -8
		addi	x16, gp, rt4fmsg-rt4fail
		sd	x16, 8(dsp)
		addi	x16, x0, rt4flen
		sd	x16, 0(dsp)
		jal	ra, type
		jal	ra, cr
		jal	x0, bye

; Given an address to a RomTag with a poor alignment, isromtag should
; yield false.

rt5fmsg:	byte	"   rt5"
rt5flen		= *-rt5fmsg

		align	8
		word	0
invalidrt4:	word	$c0de0000, $0000da7a, 1, $FFFFFFFF-($c0de0000+$da7a+9)
		word	1, 1, 1, 1
		word	1, 1, 1, 1

		align	4
rt5:		auipc	gp, 0
		addi	rsp, rsp, -8
		sd	ra, 0(rsp)
		addi	dsp, dsp, -8
		addi	x16, gp, invalidrt4-rt5
		sd	x16, 0(dsp)
		jal	ra, isromtag
		ld	x16, 0(dsp)
		bne	x16, x0, rt5fail
		addi	dsp, dsp, 8
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)
rt5fail:	auipc	gp, 0
		addi	dsp, dsp, -8
		addi	x16, gp, rt5fmsg-rt5fail
		sd	x16, 8(dsp)
		addi	x16, x0, rt5flen
		sd	x16, 0(dsp)
		jal	ra, type
		jal	ra, cr
		jal	x0, bye

; The following RomTag exists purely to satisfy the rt6 test in stsv1.bs.

		align	8
		word	$c0de0000, $0000da7a, 0, $FFFFFFFF-($c0de0000+$da7a+8)
		word	1, 1, 1, 1, 1, 1, 1, 1

;
; Answers true if the specified RomTag is valid.
;
; isromtag ( a -- -1|0 )
;

		align	4
isrtm1:		word	$c0de0000
isrtm2:		word	$0000da7a
isromtag:	auipc	gp, 0
		ld	t0, 0(dsp)	; T0 -> RomTag

		andi	t1, t0, 7	; Verify alignment
		bne	t1, x0, isrtn

		lw	t1, 0(t0)	; Check first matchword
		lw	t2, isrtm1-isromtag(gp)
		bne	t1, t2, isrtn

		lw	t1, 4(t0)	; Check second matchword
		lw	t2, isrtm2-isromtag(gp)
		bne	t1, t2, isrtn

		addi	t1, x0, 0	; T1 = checksum
		lw	t2,  0(t0)	; Calculate checksum of 48-byte RomTag
		add	t1, t1, t2
		lw	t2,  4(t0)
		add	t1, t1, t2
		lw	t2,  8(t0)
		add	t1, t1, t2
		lw	t2, 12(t0)
		add	t1, t1, t2
		lw	t2, 16(t0)
		add	t1, t1, t2
		lw	t2, 20(t0)
		add	t1, t1, t2
		lw	t2, 24(t0)
		add	t1, t1, t2
		lw	t2, 28(t0)
		add	t1, t1, t2
		lw	t2, 32(t0)
		add	t1, t1, t2
		lw	t2, 36(t0)
		add	t1, t1, t2
		lw	t2, 40(t0)
		add	t1, t1, t2
		lw	t2, 44(t0)
		add	t1, t1, t2
		addi	t2, x0, -1	; Checksum must match -1
		beq	t1, t2, isrty
isrtn:		sd	x0, 0(dsp)	; No, return false.
		jalr	x0, 0(ra)
isrty:		sd	t2, 0(dsp)	; Yes, return true.
		jalr	x0, 0(ra)

