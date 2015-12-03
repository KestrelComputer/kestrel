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
m2__1		=   60	; reserved.
m2__2		=   62	; reserved.

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
	; Bytes 0-1 of the file contains a count of the number of slides
	; to display.  Bytes 2-1023 contain *byte* offsets to the slide
	; display lists.

	; For now, though I want to do something else, since I'm on a flight
	; to PHL.  I'd like to get whatever comes out of m2type to appear
	; in the MGIA frame buffer.

	; First, let's plot the letter "A" at (0,0) on the screen.  Something
	; really basic.  Right?

	addi	x16, x0, 0
	addi	x17, x0, 0
	jal	ra, m2at
	jal	ra, m2cls

	jal	ra, m2data
	ld	x16, m2tailptr(x15)
	ld	x17, m2taillen(x15)
	jal	ra, m2write

	; Main program drops through to m2exit, which terminates the program
	; safely.  Only resource leaks that could happen are open files.

m2exit: jal	ra, m2data
	ld	gvp, m2gvp(x15)
	ld	dsp, m2dstack(x15)
	ld	rsp, m2rstack(x15)
	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)

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
; are considered.
;
; m2plotch(chr)
;          X16

	align	8
m2fb:	dword	$FF0000
m2font:	dword	__m2_font-start_m2
m2640:	dword	640
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

	ld	a0, m2cy(x15)			; Calculate frame buffer address
	ld	a1, m2640-m2plotch(gp)
	jal	ra, mathMultiply		; A0 = 640*y
	jal	ra, m2data
	ld	a1, m2cx(x15)
	add	a0, a0, a1			; A0 = 640*y + x
	ld	a1, m2fb-m2plotch(gp)
	add	x16, a0, a1			; X16 = FBBASE + 640y + x

	addi	x18, x0, 8			; Font height, pixels.

m2L200:	lb	x19, 0(x17)			; Copy the character tile.
	sb	x19, 0(x16)
	addi	x16, x16, 80
	addi	x17, x17, 256
	addi	x18, x18, -1
	bne	x18, x0, m2L200

	ld	ra, 0(rsp)
	addi	rsp, rsp, 8
	jalr	x0, 0(ra)

	align	8
	addi	x0, x0, 0
m2data:	jalr	x15, 0(ra)
	dword	0, 0, 0, 0
	dword	0, 0, 0, 0
	dword	0, 0, 0, 0
	dword	0, 0, 0, 0

	align	4
m2msgptr:
	jalr	x16, 0(ra)
	byte	"You attempted to open ``"
m2msglen = *-m2msgptr-4

	align	4
m2clquo: jalr	x16, 0(ra)
	byte	"''"
m2cllen = *-m2clquo-4

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

; Font bitmap.

	align	8
__m2_font:
	include	"m2font.asm"

; Math library.

	include "math.asm"

end_m2:
