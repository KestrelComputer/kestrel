; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;
; This file implements device-specific dispatch for character-oriented
; functions, along with some handy utilities suitable for these devices.


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

