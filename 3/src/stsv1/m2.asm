; Milestone-2 port for Kestrel-3 ROM Filesystem.
;
; Since this code is sharing space with other ROM-resident firmware,
; all symbols defined for Milestone-2 are prefixed with 'm2'.  Sorry.
; I think my next assembler will have actual namespace support.


rombase = $FFFFFFFFFFF00000

	include	"stsapi.inc"

; Foreign code requires we dedicate some registers for its use.

t1	= x7
t2	= x8
t3	= x9
t4	= x10
a0	= x11
a1	= x12
a2	= x13
a3	= x14
sp	= dsp

; Data offsets.  Call m2data to get pointer to this structure in X15.

m2stsBase	= 0
m2dstack	= 8
m2rstack	= 16
m2gvp		= 24

m2tailptr	= 32	; Pointer into command tail buffer.
m2taillen	= 40	; Length of command tail.
m2segptr	= 48	; Our place in memory.
m2cx		=   56	; Cursor X position.
m2cy		=   58	; Cursor Y position.
m2nslides	=   60	; Number of slides in the current slide deck.
m2cslide	=   62	; Current slide (1 <= cslide <= nslides)
m2ip		= 64	; Current instruction pointer

; Start of Milestone-2 port.

	align	8
start_m2:
	jalr	x0, 0(x1)
	word	0		; Padding to preserve 64-bit alignment
run_m2: addi	rsp, rsp, -8
	sd	ra, 0(rsp)

	; Save our startup state, so that if we call exit, we can just return,
	; regardless of our data and return stack state.

	jal	ra, m2data
	sd	rsp, m2rstack(x15)
	sd	dsp, m2dstack(x15)
	sd	gvp, m2gvp(x15)
	ld	x16, 0(dsp)
	sd	x16, m2stsBase(x15)
	ld	x16, 16(dsp)
	sd	x16, m2segptr(x15)

	; We want to open the file specified on the command tail.  However,
	; before we attempt this, we want to strip spaces first.

	ld	x16, 40(dsp)	; length
	ld	x17, 48(dsp)	; pointer
m2L110:	beq	x16, x0, m2L100	; Stop scanning if no more text
	lbu	x18, 0(x17)
	addi	x19, x0, 32
	bne	x18, x19, m2L100 ; Stop scanning if non-space
	addi	x17, x17, 1
	addi	x16, x16, -1
	jal	x0, m2L110
m2L100:	sd	x17, m2tailptr(x15)
	sd	x16, m2taillen(x15)

	; m2tailptr/len refers to a filename that we can open and process.
	; Let's attempt to open the file.  STS doesn't track resources, so
	; with luck, we won't crash while the file is open.

	addi	dsp, dsp, -16
	sd	x17, 8(dsp)
	sd	x16, 0(dsp)
	jal	ra, m2open
	ld	x16, 0(dsp)
	bne	x16, x0, m2L120

	; Bytes 0-1 of the file contains a count of the number of slides
	; to display.  Bytes 2-1023 contain *byte* offsets to the slide
	; display lists.
	;
	; Attempt to discover how many slides exist.

	addi	dsp, dsp, -24
	ld	x16, 32(dsp)
	sd	x16, 0(dsp)	; Read using SCB
	addi	x16, x0, 2	; of length 2 bytes
	sd	x16, 8(dsp)
	jal	ra, m2data	; into m2nslides
	addi	x16, x15, m2nslides
	sd	x16, 16(dsp)
	jal	ra, m2read
	ld	x16, 0(dsp)	; error during read?
	bne	x16, x0, m2L130
	ld	x16, 8(dsp)
	addi	x17, x0, 2
	bne	x16, x17, m2L130
	addi	dsp, dsp, 16

	; Always start out with the first slide.

	jal	ra, m2data
	addi	x16, x0, 1
	sh	x16, m2cslide(x15)
	jal	ra, m2repaint
	jal	ra, m2eventloop

	addi	dsp, dsp, 8
	jal	ra, m2close
	jal	x0, m2exit

	; If we're here, that means the attempt to read has failed.
m2L130:	jal	ra, m2nslidesfailedmsg
	jal	x0, m2L120+4

	; If we're here, that means the attempt to open the slides file
	; failed.  Print an error message and return to the OS.
m2L120:	jal	ra, m2openfailedmsg
	sd	x16, 0(dsp)
	sd	x17, 8(dsp)
	jal	ra, m2type
	jal	ra, m2cr

m2exit: jal	ra, m2data
	ld	gvp, m2gvp(x15)
	ld	dsp, m2dstack(x15)
	ld	rsp, m2rstack(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)

m2_jumptab:
	jal	x0, m2L610
	jal	x0, m2first
	jal	x0, m2prev
	jal	x0, m2next
	jal	x0, m2last
m2eventloop:
	addi	rsp, rsp, -8
	sd	ra, 0(rsp)

m2L600:	jal	ra, m2repaint
	jal	ra, m2getkey
	lbu	x16, 0(dsp)
	addi	dsp, dsp, 8
	addi	x16, x16, -48
	blt	x16, x0, m2L600	; < 0? Ignore.
	addi	x17, x0, 5
	bge	x16, x17, m2L600 ; >= 5? Ignore too.

	; 0 <= x16 < 5; index into a jump table.
	slli	x16, x16, 2
m2L620:	auipc	gp, 0
	add	x16, x16, gp
	addi	x16, x16, m2_jumptab-m2L620
	jalr	x0, 0(x16)

m2first:
	addi	x16, x0, 1
	jal	ra, m2data
	sh	x16, m2cslide(x15)
	jal	x0, m2L600

m2last:
	jal	ra, m2data
	lh	x16, m2nslides(x15)
	sh	x16, m2cslide(x15)
	jal	x0, m2L600

m2prev: jal	ra, m2data
	lh	x16, m2cslide(x15)
	addi	x16, x16, -1
	beq	x16, x0, m2L600
	sh	x16, m2cslide(x15)
	jal	x0, m2L600

m2next:	jal	ra, m2data
	lh	x16, m2cslide(x15)
	lh	x17, m2nslides(x15)
	beq	x16, x17, m2L600
	addi	x16, x16, 1
	sh	x16, m2cslide(x15)
	jal	x0, m2L600

m2L610:	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)

	; Repaint the frame buffer for the current slide.
	; Requires a data stack frame like so:
	; DSP+8 = An open SCB of slide deck file.
	; DSP+0 = 0 (free for use)
	;
	; Returns with the same stack frame.
m2repaint:
	addi	rsp, rsp, -8
	sd	ra, 0(rsp)

	; seek to 0.

	addi	dsp, dsp, -16
	ld	x16, 24(dsp)
	sd	x16, 0(dsp)
	sd	x0, 8(dsp)
	jal	ra, m2seek

	; read in slide index.

	addi	dsp, dsp, -8
	ld	x16, 32(dsp)
	sd	x16, 0(dsp)
	addi	x16, x0, 1024
	sd	x16, 8(dsp)
	jal	ra, m2blockbuf
	sd	x16, 16(dsp)
	jal	ra, m2read

	; seek to appropriate slide offset.

	jal	ra, m2data
	lh	x17, m2cslide(x15)
	slli	x17, x17, 1
	jal	ra, m2blockbuf
	add	x16, x16, x17
	lh	x16, 0(x16)
	sd	x16, 8(dsp)
	ld	x16, 24(dsp)
	sd	x16, 0(dsp)
	jal	ra, m2seek

	; read in slide data.

	addi	dsp, dsp, -8
	ld	x16, 32(dsp)
	sd	x16, 0(dsp)
	addi	x16, x0, 1024
	sd	x16, 8(dsp)
	jal	ra, m2blockbuf
	sd	x16, 16(dsp)
	jal	ra, m2read
	addi	dsp, dsp, 16	; don't care about status or actual length read.

	; interpret data.
	jal	ra, m2blockbuf
	jal	ra, m2data
	sd	x16, m2ip(x15)
	jal	ra, m2cls
	jal	ra, m2draw

	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)
	
	; interprets a graphics string located at m2ip.
	; The string MUST end with an END opcode ($01).
m2draw: addi	rsp, rsp, -8
	sd	ra, 0(rsp)

m2L500: jal	ra, m2data
	ld	x16, m2ip(x15)
	lbu	x17, 0(x16)

	addi	x18, x0, $00		; NOP?
	beq	x17, x18, m2nop

	addi	x18, x0, $01		; END?
	beq	x17, x18, m2L510

	addi	x18, x0, $10		; TEXT?
	beq	x17, x18, m2text

m2nop:	addi	x16, x16, 2
	sd	x16, m2ip(x15)
	jal	x0, m2L500
	
m2text:	lbu	x17, 1(x16)
	jal	ra, m2data
	sh	x17, m2cy(x15)
	lbu	x17, 2(x16)
	sh	x17, m2cx(x15)
	lbu	x17, 3(x16)
	addi	x16, x16, 4
	jal	ra, m2write

	jal	ra, m2data
	ld	x16, m2ip(x15)
	lbu	x17, 3(x16)
	addi	x17, x17, 1
	andi	x17, x17, -2
	addi	x17, x17, 4
	add	x16, x16, x17
	sd	x16, m2ip(x15)
	jal	x0, m2L500

m2L510: ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)


	align	8
m2openfailedmsg:
	addi	x16, x0, m2__openfailedlen
	jalr	x17, 0(ra)
m2__openfailedmsg:
	byte	"File open failed."
m2__openfailedlen = *-m2__openfailedmsg

	align	8
m2nslidesfailedmsg:
	addi	x16, x0, m2__nslidesfailedlen
	jalr	x17, 0(ra)
m2__nslidesfailedmsg:
	byte	"Cannot read number of slides."
m2__nslidesfailedlen = *-m2__nslidesfailedmsg

	align	4
m2_64:	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	ld	x16, m2stsBase(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, STS_HEX64(x16)

m2type:	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	ld	x16, m2stsBase(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, STS_TYPE(x16)

m2cr:	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	ld	x16, m2stsBase(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, STS_CR(x16)

m2open:	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	ld	x16, m2stsBase(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, STS_OPEN(x16)

m2seek:	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	ld	x16, m2stsBase(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, STS_SEEK(x16)

m2read:	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	ld	x16, m2stsBase(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, STS_READ(x16)

m2close:
	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	ld	x16, m2stsBase(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, STS_CLOSE(x16)

m2getkey:
	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	ld	x16, m2stsBase(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, STS_GETKEY(x16)

; Positions the text cursor.  Only bits 15-0 are significant for each
; coordinate.  At present, for an 8x8 font, (0, 0) <= (x, y) < (80, 60).
; Precise limits will depend on font height.
;
; m2at(cx, cy)
;      X16 X17

m2at:	addi	rsp, rsp, -8
	sd	ra, 0(rsp)
	jal	ra, m2data
	sh	x16, m2cx(x15)
	sh	x17, m2cy(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)

; Clears the screen.

	align	8
m2cls_fb:
	dword	$FF0000
m2cls_fbsz:
	dword	$9600	; 640x480 monochrome bitmap

m2cls:	auipc	gp, 0
	ld	x16, m2cls_fb-m2cls(gp)
	ld	x17, m2cls_fbsz-m2cls(gp)
m2L300:	sd	x0, 0(x16)
	addi	x16, x16, 8
	addi	x17, x17, -8
	bne	x17, x0, m2L300
	jalr	x0, 0(ra)

; m2write writes a string to the screen, starting at the current cursor
; position.
;
; m2write(adr, len)
;         X16  X17

	align	8
m2write:
	addi	rsp, rsp, -24
	sd	ra, 0(rsp)
	sd	x16, 8(rsp)
	sd	x17, 16(rsp)
	
m2L400:	ld	x16, 16(rsp)
	beq	x16, x0, m2L410
	ld	x16, 8(rsp)
	lb	x16, 0(x16)
	jal	ra, m2plotch
	jal	ra, m2data
	lh	x16, m2cx(x15)
	addi	x16, x16, 1
	sh	x16, m2cx(x15)
	ld	x16, 8(rsp)
	addi	x16, x16, 1
	sd	x16, 8(rsp)
	ld	x16, 16(rsp)
	addi	x16, x16, -1
	sd	x16, 16(rsp)
	jal	x0, m2L400

m2L410:	ld	ra, 0(rsp)
	ld	x16, 8(rsp)
	ld	x17, 16(rsp)
	addi	rsp, rsp, 24
	jalr	x0, 0(ra)

; Plot a character to the screen.  Only the low 8-bits of the parameter
; are considered.  The character is plotted at the coordinate last set
; by a call to m2at.  The coordinate is NOT incremented; subsequent
; calls to m2plotch will cause the previously plotted character to be
; overwritten.
;
; m2plotch(chr)
;          X16

	align	8
m2fb:	dword	$FF0000
m2font:	dword	__m2_font-start_m2
m2640:	dword	1760
m2plotch:
	auipc	gp, 0
	addi	rsp, rsp, -8
	sd	ra, 0(rsp)

	jal	ra, m2data			; X15 -> global data
	ld	x17, m2segptr(x15)		; X15 -> base address for our image
	ld	x18, m2font-m2plotch(gp)	; X17 -> character tile.
	add	x17, x17, x18
	andi	x16, x16, 255
	add	x17, x17, x16

	lh	a0, m2cy(x15)			; Calculate frame buffer address
	ld	a1, m2640-m2plotch(gp)
	jal	ra, mathMultiply		; A0 = BYTES_PER_ROW*y
	jal	ra, m2data
	lh	a1, m2cx(x15)
	add	a0, a0, a1			; A0 = BYTES_PER_ROW*y + x
	ld	a1, m2fb-m2plotch(gp)
	add	x16, a0, a1			; X16 = FBBASE + B_P_R*y + x

	addi	x18, x0, 8			; Font height, pixels.

m2L200:	lb	x19, 0(x17)			; Copy the character tile.
	sb	x19, 0(x16)
	addi	x16, x16, 160
	addi	x17, x17, 256
	addi	x18, x18, -1
	bne	x18, x0, m2L200

	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)

; Global Milestone-2 data.

	align	8
	addi	x0, x0, 0
m2data:	jalr	x15, 0(ra)
	dword	0, 0, 0, 0
	dword	0, 0, 0, 0
	dword	0, 0, 0, 0
	dword	0, 0, 0, 0

; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_m2:
	dword	rombase+start_m2
prg_m2_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_m2-prg_m2_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

	align	8
i_len_m2:
	dword	end_m2-start_m2
prg_m2_len:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_len_m2-prg_m2_len(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

; Block buffer; a 1024-byte I/O scratch pad.
; Easier than using getmem.

	align	8
m2blockbuf:
	addi	x0, x0, 0
	jalr	x16, 0(ra)
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0
	dword	0, 0, 0, 0, 0, 0, 0, 0

; Font bitmap.

	align	8
__m2_font:
	include	"m2font.asm"

; Math library.

	include "math.asm"

end_m2:
