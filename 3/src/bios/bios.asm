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
		addi	s0, s0, 1
		addi	a2, x0, 256
		blt	s0, a2, bc100	; and repeat until done.

		addi	a0, x0, 1	; Output BIOS banner to the screen.
		jal	ra, bios_i_strout
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
; actual = bios_strout(dev, buffer)
; a0                   a0   a1
;
; FUNCTION
; Sends a NULL-terminated string to the indicated character-oriented
; device.  The NULL byte is not sent.
;
; If the device cannot accept new characters at any time during the
; output procedure, bios_strout will simply return early.
;
; RETURNS
; The actual number of bytes sent.

bios_strout:	addi	sp, sp, -24
		sd	ra, 0(sp)
		sd	s0, 8(sp)
		sd	s1, 16(sp)

		addi	s0, a0, 0	; preserve device ID
		addi	s1, a1, 0	; get string address

_so110:		addi	a0, s0, 0
		lb	a1, 0(s1)
		beq	a1, x0, _so100
		jal	ra, mgia_chrout
		addi	s1, s1, 1
		jal	x0, _so110

_so100:		ld	ra, 0(sp)
		ld	s0, 8(sp)
		ld	s1, 16(sp)
		addi	sp, sp, 24
		jalr	x0, 0(ra)


; SYNOPSIS
; addi	a0, x0, deviceID
; jal	ra, bios_i_strout
; byte	"Hello world.",13,10,0
; align	4
;
; INPUTS
; A0		Device ID (see bios_chrout).
; Inline	NULL-terminated string to print.
;
; FUNCTION
; A convenience procedure for bios_strout, letting assembly programmers
; print an inline string to the desired output device.  Most typically,
; this device will be the screen.
;
; If the output device buffer cannot accept new characters for any reason
; while the output is in progress, this function will not block; it will
; simply return early.  If you need an accurate assessment of how much data
; was successfully sent, you should use bios_strout instead.
;
; It's strongly recommended that this procedure be used only with devices
; that can comfortably accept the length of string you intend on printing.
; The screen device is guaranteed to accept as many characters as can fit
; in memory.
;
; RETURNS
; Presently nothing.

bios_i_strout:	addi	a1, ra, 0

_so210:		lb	a2, 0(ra)
		beq	a2, x0, _so200
		addi	ra, ra, 1
		jal	x0, _so210

_so200:		addi	ra, ra, 3
		andi	ra, ra, -4
		jal	x0, bios_strout

; SYNOPSIS
; bios_init()
;
; FUNCTION
; Initializes the BIOS Data Area to power-on default values.

bios_init:	addi	sp, sp, -8
		sd	ra, 0(sp)

_bi100:		auipc	gp, 0
		ld	a0, _ih_B105-_bi100(gp)
		sd	a0, bd_tag(x0)

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

