; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

		include	"bios.inc.asm"
		include "bios.data.asm"

		include "math.asm"
		include "bios.mgia.asm"

; BIOS low memory map
;
; $000000-$0007FF	BIOS Data Area
; $000800-$000FFF	Stack
; $001000-$FEFFFF	Available
; $FF0000-$FFFFFF	MGIA Frame Buffer (if MGIA present)
;			Available (otherwise)
;
; Memory higher than this is typically reserved for I/O
; or other expansion peripherals.

; BIOS Data Area.

bd_tag		= 0			; D BIOS Data Format tag
bd_bitplane	= bd_tag + 8		; D Pointer to MGIA framebuffer.
bd_planesz	= bd_bitplane + 8	; D Size of said framebuffer, bytes.

bd_cx		= bd_planesz + 8	; H Cursor X position
bd_cy		= bd_cx + 2		; H Cursor Y position
bd_maxcol	= bd_cy + 2		; H Maximum number of columns (typ. 80)
bd_maxrow	= bd_maxcol+2		; H Maximum number of rows (typ. 60)

bd_planebw	= bd_maxrow+2		; H Width of bitmap in bytes
bd_planeh	= bd_planebw+2		; H Height of bitmap in pixels
bd_padding0	= bd_planeh+2		; H reserved.
bd_padding1	= bd_padding0+2		; H reserved.

bd_fontform	= bd_padding1+4		; D Pointer to system font image.

; Main entry point for the BIOS.  The CPU is in machine mode, memory mapping
; hardware is disabled, and we have full, unadulterated access to literally
; everything the hardware has to offer.  Since we arrive here after a power-on
; event, we must assume the entirety of RAM contains garbage.

bios_cold:	addi	sp, x0, 1	; SP = $1000
		slli	sp, sp, 12

		jal	ra, bios_init	; Perform power-on initialization

		; Start our built-in self-test with dumping all ASCII
		; characters onto the screen.

		addi	a0, x0, 1	; Device 1 is screen
		addi	a1, x0, 12	; Form Feed.
		jal	ra, mgia_chrout	; Clear the screen
		addi	a1, x0, 13	; Carriage Return.
		jal	ra, mgia_chrout

		addi	s0, x0, 32	; Start print from the space
bc100:		add	a1, s0, x0
		jal	ra, mgia_chrout	; Print character,

		addi	s0, s0, 1	; increment,
		addi	a2, x0, 256
		blt	s0, a2, bc100	; and repeat until done.

_bc900:		addi	a0, x0, 255
		slli	a0, a0, 16
_bc901:		ld	a1, 1024(a0)
		addi	a1, a1, 1
		sd	a1, 1024(a0)
		jal	x0, _bc901

wtf:		addi	a5, x0, 255
		slli	a5, a5, 16
		sh	a0, 1024(a5)
		addi	a1, x0, $777
		sd	a1, 1104(a5)
		jal	x0, *

		adv	RESET_BASE-BIOS_BASE, $CC
		jal	x0, bios_cold

; Initialize the BIOS Data Area at least to boot the remainder of BIOS.

bios_init:	addi	sp, sp, -8
		sd	ra, 0(sp)

		jal	ra, mgia_init

		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)
