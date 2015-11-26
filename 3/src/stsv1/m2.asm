; Milestone-2 port for Kestrel-3 ROM Filesystem.
;
; Since this code is sharing space with other ROM-resident firmware,
; all symbols defined for Milestone-2 are prefixed with 'm2'.  Sorry.
; I think my next assembler will have actual namespace support.


rombase = $FFFFFFFFFFF00000

	include	"stsapi.inc"

; Data offsets.  Call m2data to get pointer to this structure in X15.

m2stsBase	= 0
m2dstack	= 8
m2rstack	= 16
m2gvp		= 24
m2tailptr	= 32	; Pointer into command tail buffer.
m2taillen	= 40	; Length of command tail.
m2segptr	= 48	; Our place in memory.

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

	jal	ra, m2cls
	jal	ra, m2plotch

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

; Plot a character to the screen.

	align	8
m2fb:	dword	$FF0000
m2font:	dword	__m2_font-start_m2+67
m2plotch:
	auipc	gp, 0
	addi	rsp, rsp, -8
	sd	ra, 0(rsp)

	jal	ra, m2data			; X15 -> global data
	ld	x15, m2segptr(x15)		; X15 -> base address for our image
	ld	x16, m2fb-m2plotch(gp)		; X16 -> framebuffer
	ld	x17, m2font-m2plotch(gp)	; X17 -> character tile
	add	x17, x17, x15
	addi	x18, x0, 8

m2L200:	lb	x19, 0(x17)
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

end_m2:
