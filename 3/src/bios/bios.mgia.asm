; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;
; MGIA Driver

; SYNOPSIS
; form = mgia_sysfntadr()
;  a0
;
; FUNCTION
; Return the base address of the 2KB bitmap containing the system font.
;
; The system font is an 8x8 fixed-width font laid out in big-endian format,
; matching the MGIA's display layout.  The address of any character's tile
; is computed by simply adding the character index to the base address.
; Each row of the tile is computed by adding 256.
;
; RETURNS
; Base address of the system font.

		align	4
mgia_sysfntadr:	jalr	a0, 0(ra)
		include	"bios.mgia.font"

		align	4

; SYNOPSIS
; mgia_init()
;
; FUNCTION
;
; Initialize the BIOS Data Area members relevant to driving the MGIA.
; You cannot invoke bios_chrout() or bios_qchout() on the display
; devices until this procedure runs.

mgia_init:	addi	sp, sp, -8
		sd	ra, 0(sp)

		addi	a0, x0, 255		; Framebuffer at $FF0000.
		slli	a0, a0, 16
		sd	a0, bd_bitplane(x0)

_mi100:		auipc	gp, 0			; Framebuffer is $9600 bytes.
		lw	a0, _ih_9600 - _mi100(gp)
		sd	a0, bd_planesz(x0)

		addi	a0, x0, 80		; Plane is 80 bytes wide.
		sh	a0, bd_planebw(x0)
		sh	a0, bd_maxcol(x0)	; Right margin

		addi	a0, a0, 400		; Plane is 480px tall.
		sh	a0, bd_planeh(x0)

		srli	a0, a0, 3		; Bottom margin
		sh	a0, bd_maxrow(x0)

		sh	x0, bd_cx(x0)		; Cursor is home by default.
		sh	x0, bd_cy(x0)

		jal	ra, mgia_sysfntadr	; Get font address
		sd	a0, bd_fontform(x0)

		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)

_ih_9600:	word	$9600


; SYNOPSIS
;
; mgia_chrout(dev, ch)
;             a0   a1.b
;
; INPUTS
;    dev	Device ID (ignored).
;    ch		Character. 0 <= ch < 256.
;
; FUNCTION
;
; Writes a character to the emulated console.  This procedure does not emulate
; a character matrix in memory; it only emulates one on the display.
;
; ASCII-specified formatting codes are emulated:
;
; $07		If the Kestrel supports audio, a bell sound is generated.
;		No other output occurs.
; $08		Moves the cursor back one position.
; $09		Moves the cursor to the next tab position.  By default, tab-
;		stops exist every 8 characters.
; $0A		New Line; moves the cursor down one line, scrolling if needed.
; $0B		Vertical tab; currently the same behavior as $0A.
; $0C		Form Feed; clears the MGIA screen and vertically homes the
;		cursor.  Follow with $0D to home the cursor horizontally.
; $0D		Moves the cursor to the left side of the screen.
;
; No other control codes have any effect, and none produce any output.

mgia_chrout:	addi	sp, sp, -8
		sd	ra, 0(sp)

		; If a character is printable, then dispatch to the
		; typesetter.  Otherwise, perform the appropriate ASCII
		; control function.

		andi	a1, a1, 255		; Ignore bits 8..XLEN-1
		addi	a5, x0, 32
		bgeu	a1, a5, _mg100

		slli	a1, a1, 1
		jal	ra, _mg900		; A5 -> dispatch table
		add	a1, a1, a5		; A1 -> hword displacement
		lh	a1, 0(a1)		; A1 = displacement
		add	a1, a1, a5		; A1 = addr of procedure
		jalr	ra, 0(a1)		; Do it!
		jal	x0, _mg899

		; Plot the character by locating the character's tile in
		; the system font, computing the framebuffer address for
		; the character's final location, then copying the tile.
_mg100:		jal	ra, mgia_tilechr
		jal	ra, mgia_right

_mg899:		ld	ra, 0(sp)
		addi	sp, sp, 8
_mg_nop:	jalr	x0, 0(ra)

_mg900:		jalr	a5, 0(ra)
_mg901:		hword	_mg_nop - _mg901	; 00
		hword	_mg_nop - _mg901	; 01
		hword	_mg_nop - _mg901	; 02
		hword	_mg_nop - _mg901	; 03
		hword	_mg_nop - _mg901	; 04
		hword	_mg_nop - _mg901	; 05
		hword	_mg_nop - _mg901	; 06
		hword	_mg_nop - _mg901	; 07	Bell
		hword	_mg_nop - _mg901	; 08	Backspace
		hword	_mg_nop - _mg901	; 09	Tab
		hword	_mg_nop - _mg901	; 0A	Line Feed
		hword	_mg_nop - _mg901	; 0B	Vertical Tab
		hword	_mg_cls - _mg901	; 0C	Form Feed
		hword	_mg_cr  - _mg901	; 0D	Carriage Return
		hword	_mg_nop - _mg901	; 0E
		hword	_mg_nop - _mg901	; 0F
		hword	_mg_nop - _mg901	; 10
		hword	_mg_nop - _mg901	; 11
		hword	_mg_nop - _mg901	; 12
		hword	_mg_nop - _mg901	; 13
		hword	_mg_nop - _mg901	; 14
		hword	_mg_nop - _mg901	; 15
		hword	_mg_nop - _mg901	; 16
		hword	_mg_nop - _mg901	; 17
		hword	_mg_nop - _mg901	; 18
		hword	_mg_nop - _mg901	; 19
		hword	_mg_nop - _mg901	; 1A
		hword	_mg_nop - _mg901	; 1B
		hword	_mg_nop - _mg901	; 1C
		hword	_mg_nop - _mg901	; 1D
		hword	_mg_nop - _mg901	; 1E
		hword	_mg_nop - _mg901	; 1F

; Per https://www.cs.tut.fi/~jkorpela/chars/c0.html, the form-feed
; function is ...
;
; A format effector which advances the active position to the same
; character position on a pre-determined line of the next form or page.
;
; I interpret this to mean clearing the display, and moving the curor's
; Y location to 0.  However, the X position remains intact.
;
; This procedure runs in the context of mgia_chrout.

_mg_cls:	ld	a5, bd_bitplane(x0)	; A5 -> MGIA framebuffer
		ld	a4, bd_planesz(x0)	; A4 = size of bitplane (bytes)
		add	a4, a4, a5
		addi	a3, x0, 0

_mg200:		sd	a3, 0(a5)		; Clear the bitmap
		addi	a5, a5, 8
		bltu	a5, a4, _mg200

		sh	x0, bd_cy(x0)		; Home line.
		jalr	x0, 0(ra)

; Per https://www.cs.tut.fi/~jkorpela/chars/c0.html, the
; carriage-return function is ...
;
; A format effector which moves the active position to the first
; character position on the same line.
;
; This procedure runs in the context of mgia_chrout.

_mg_cr:		sh	x0, bd_cx(x0)		; Home column.
		jalr	x0, 0(ra)


; SYNOPSIS
; mgia_right()
;
; FUNCTION
; Moves the cursor to the right one character position.

mgia_right:	addi	sp, sp, -8
		sd	ra, 0(sp)

		lh	a0, bd_cx(x0)
		addi	a0, a0, 1
		sh	a0, bd_cx(x0)

		lh	a1, bd_maxcol(x0)
		blt	a0, a1, _mg400

		sh	x0, bd_cx(x0)
		lh	a0, bd_cy(x0)
		addi	a0, a0, 1
		sh	a0, bd_cy(x0)

		lh	a1, bd_maxrow(x0)
		blt	a0, a1, _mg400
		addi	a1, a1, -1
		sh	a1, bd_cy(x0)
		jal	ra, mgia_scrup
		jal	ra, mgia_blankb

_mg400:		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)


; SYNOPSIS
; mgia_blankb()
;
; FUNCTION
; Clears the bottom-most line in the display window.

mgia_blankb:	addi	sp, sp, -8
		sd	ra, 0(sp)

		; Assumes an 8-pixel high font on a 640x480 bitplane.
		; Further assumes maxcol=80, maxrow=60.

		addi	a0, x0, 0
		addi	a1, x0, 472
		jal	ra, mgia_addr
		addi	a1, x0, 640

_mg600:		sd	x0, 0(a0)
		addi	a0, a0, 8
		addi	a1, a1, -8
		bne	a1, x0, _mg600

		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)


; SYNOPSIS
; mgia_scrup()
;
; FUNCTION
; Scroll a rectangular region defined by the left, top, right, and bottom
; margins (currently, hardwired to 0, 0, 80, and 60, respectively) up one
; line.

mgia_scrup:	addi	sp, sp, -16
		sd	ra, 0(sp)
		sd	s0, 8(sp)

		; First, we copy the data in the frame buffer up one line.
		; The following code assumes an 8-pixel tall font on a
		; 640x480 screen.  We also assume maxcol, maxrow = 80, 60.
		; We'll need a more general purpose blitter to support
		; subwindows.

		addi	a0, x0, 0
		addi	a1, x0, 0
		jal	ra, mgia_addr
		addi	s0, a0, 0

		addi	a0, x0, 0
		addi	a1, x0, 8
		jal	ra, mgia_addr

		ld	a1, bd_planesz(x0)
		addi	a1, a1, -640		; Assuming 8px tall font

_mg500:		ld	a2, 0(a0)
		sd	a2, 0(s0)
		addi	s0, s0, 8
		addi	a0, a0, 8
		addi	a1, a1, -8
		bne	a1, x0, _mg500

		; Next, we have to blank the bottom line, preparing it for
		; the next line of text to be displayed.

		ld	ra, 0(sp)
		ld	s0, 8(sp)
		addi	sp, sp, 16
		jalr	x0, 0(ra)


; SYNOPSIS
; mgia_tilechr(dev, ch)
;              a0   a1.b
;
; INPUTS
;    dev	Unused.
;    ch		Character to display at the current cursor position.
;
; FUNCTION
; Places the image of the desired character into the cell identified by
; the (cx, cy) coordinates.

mgia_tilechr:	addi	sp, sp, -16
		sd	ra, 0(sp)
		sd	s0, 8(sp)

		; Calculate the frame buffer address.

		addi	s0, a1, 0
		lh	a0, bd_cx(x0)
		lh	a1, bd_cy(x0)
		slli	a1, a1, 3
		jal	ra, mgia_addr

		ld	a1, bd_fontform(x0)
		add	a1, a1, s0	; A1 -> tile

		; Replace the tile on the screen with the intended tile from
		; the font.

		lh	a3, bd_planebw(x0)
		addi	a4, x0, 8	; 8px tall font

_mg300:		lb	a2, 0(a1)
		sb	a2, 0(a0)
		add	a0, a0, a3
		addi	a1, a1, 256
		addi	a4, a4, -1
		bne	a4, x0, _mg300

		ld	ra, 0(sp)
		ld	s0, 8(sp)
		addi	sp, sp, 16
		jalr	x0, 0(ra)


; SYNOPSIS
; a = mgia_addr(x,   y)
; a0            a0.h a1.h
;
; INPUTS
; x	Horizontal column coordinate, expressed in characters.
;	(0 <= x < bd_planebw)
; y	Vertical row coordinate, expressed in pixels.
;	(0 <= y < bd_planeh)
;
; FUNCTION
; Computes the byte address of any pixel addressible by the MGIA.  The
; horizontal coordinate is expressed in octets (groups of 8 pixels).
; For example, to find the address of pixel (12, 16), you'll need to
; set x = floor(12/8) = 1, y = 16.
;
; RETURNS
; A byte address.

mgia_addr:	addi	sp, sp, -16
		sd	ra, 0(sp)
		sd	s0, 8(sp)

		; Compute form+X+Y*80

		addi	s0, a0, 0
		lh	a0, bd_planebw(x0)
		jal	ra, mathMultiply
		add	a0, a0, s0
		ld	a1, bd_bitplane(x0)
		add	a0, a0, a1

		ld	ra, 0(sp)
		ld	s0, 8(sp)
		addi	sp, sp, 16
		jalr	x0, 0(ra)

