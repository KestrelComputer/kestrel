; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

		include	"bios.inc.asm"
		include "bios.data.asm"
		include "bios.mgia.asm"
		include	"bios.jump.asm"
		include	"bios.chr.asm"
		include "math.asm"

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

; Main entry point for the BIOS.  The CPU is in machine mode, memory mapping
; hardware is disabled, and we have full, unadulterated access to literally
; everything the hardware has to offer.  Since we arrive here after a power-on
; event, we must assume the entirety of RAM contains garbage.

bios_cold:	addi	sp, x0, 1	; SP = $1000
		slli	sp, sp, 12

		jal	ra, bios_init	; Perform power-on initialization

		; Start our built-in self-test with dumping all ASCII
		; characters onto the screen.

		ld	s7, BIOS_JUMPTAB(x0)	; Get BIOS jump table in S7

		addi	a0, x0, 0	; Screen device never allows input
		jalr	ra, BIOS_CANINP(s7)
		bne	a0, x0, wtf

		addi	a0, x0, 0	; Device 0 is screen
		addi	a1, x0, 12	; Use Form Feed to clear screen.
		jalr	ra, BIOS_CHROUT(s7)

		addi	a0, x0, 0	; Device 0
		addi	a1, x0, 13	; Carriage Return.
		jalr	ra, BIOS_CHROUT(s7)

		addi	s0, x0, 32	; Start print from the space
bc100:		add	a1, s0, x0
		addi	a0, x0, 0
		jalr	ra, BIOS_CHROUT(s7)	; Print character,
		addi	s0, s0, 1
		addi	a2, x0, 256
		blt	s0, a2, bc100	; and repeat until done.

		addi	a0, x0, 0	; Output BIOS banner to the screen.
		jalr	ra, BIOS_I_STROUT(s7)
		byte	13, 10, 10
		byte	"Kestrel-3 BIOS V1.15.51"
		byte	13, 10, 10, 0
		align	4

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

; SYNOPSIS
; bios_init()
;
; FUNCTION
; Initializes the BIOS Data Area to power-on default values.
;
; This gets the video display up and running first and foremost, so that
; diagnostics can be printed if errors occur during BIST.

bios_init:	addi	sp, sp, -8
		sd	ra, 0(sp)

_bi100:		auipc	gp, 0
		ld	a0, _ih_B105-_bi100(gp)
		sd	a0, bd_tag(x0)

		jal	ra, bios_jumptab
		sd	a0, bd_jumptab(x0)

		jal	ra, mgia_init

		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)

		align	8
_ih_B105:	dword	$B105

; CPU reset vector.  The Polaris CPU boots here after the reset signal has
; been asserted.

		adv	RESET_BASE-BIOS_BASE, $CC
		jal	x0, bios_cold

