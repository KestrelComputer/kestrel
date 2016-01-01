; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;
; This file implements device-specific dispatch for character-oriented
; functions, along with some handy utilities suitable for these devices.


MAX_CHRDEV	= 2

chrdev_canout	= 0
chrdev_chrout	= 4
chrdev_caninp	= 8
chrdev_chrinp	= 12


bios_false:	addi	a0, x0, 0
		jalr	x0, 0(ra)


; SYNOPSIS
; 
; yn = bios_caninp(dev)
; a0               a0
;
; INPUTS
;    dev	Unused.
;
; FUNCTION
; Return true (non-zero) if the device is capable of delivering at least
; one more byte for input; false (zero) otherwise.
;
; RETURNS
; Non-zero or zero, depending on whether the driver can deliver another
; byte of input data.

bios_caninp:	addi	a2, x0, MAX_CHRDEV
		bgeu	a0, a2, _co120
		slli	a0, a0, 4
		jal	a2, _bios_chrtab
		add	a0, a0, a3
		jalr	x0, chrdev_caninp(a0)
_co120:		jalr	x0, 0(ra)

; SYNOPSIS
; chr = bios_chrinp(dev)
; a0                a0  
;
; FUNCTION
; If the indicated device is ready to deliver another character, this
; procedure will receive and return the next byte available to the caller.
;
; If no byte is available, $00 is returned.  However, many devices treat
; $00 as valid data; therefore, you should always use bios_caninp to determine
; data availability.
;
; RETURNS
; The next available byte, if any; $00 if none.

bios_chrinp:	addi	a2, x0, MAX_CHRDEV
		bgeu	a0, a2, _co130
		slli	a0, a0, 4
		jal	a2, _bios_chrtab
		add	a0, a0, a3
		jalr	x0, chrdev_chrinp(a0)
_co130:		jalr	x0, 0(ra)

; SYNOPSIS
; 
; yn = bios_canout(dev)
; a0               a0
;
; INPUTS
;    dev	Unused.
;
; FUNCTION
; Return true (non-zero) if the device is capable of accepting more input;
; false (zero) otherwise.
;
; RETURNS
; Non-zero or zero, depending on whether the driver can accept or no longer
; accept incoming data, respectively.

bios_canout:	addi	a2, x0, MAX_CHRDEV
		bgeu	a0, a2, _co110
		slli	a0, a0, 4
		jal	a2, _bios_chrtab
		add	a0, a0, a3
		jalr	x0, chrdev_canout(a0)
_co110:		jalr	x0, 0(ra)

; SYNOPSIS
; bios_chrout(dev, chr)
;             a0   a1.b
;
; FUNCTION
; If the indicated device is ready to accept another character, this
; procedure will hand of the byte to that device.
;
; Not all devices are physical; screen output is an emulation of a printer,
; but is not a real printer.
;
; If the device is not ready to accept a character, then nothing will
; happen.  Use bios_canout to determine if the device is ready.

bios_chrout:	addi	a2, x0, MAX_CHRDEV
		bgeu	a0, a2, _co100
		slli	a0, a0, 4
		jal	a2, _bios_chrtab
		add	a0, a0, a3
		jalr	x0, chrdev_chrout(a0)
_co100:		jalr	x0, 0(ra)

; Character Device Driver table

_bios_chrtab:	jalr	a3, 0(a2)
		jal	x0, mgia_canout		; Device 0: Screen output
		jal	x0, mgia_chrout
		jal	x0, bios_false
		jal	x0, bios_false

		jal	x0, bios_false		; Device 1: Raw Keyboard Input
		jal	x0, bios_false
		jal	x0, kia2_caninp
		jal	x0, kia2_chrinp


;
; 
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

_so200:		addi	ra, ra, 4
		andi	ra, ra, -4
		jal	x0, bios_strout


; SYNOPSIS
; bios_hex64out(dev, udword)
;               a0     a1
;
; INPUTS
;    dev	unused
;    udword	The 64-bit word to print the value of.
;
; FUNCTION
; Prints the value of udword to the selected output device,
; in hexadecimal form.

bios_hex64out:	addi	sp, sp, -24
		sd	ra, 0(sp)
		sd	s0, 8(sp)
		sd	s1, 16(sp)

		addi	s0, a0, 0
		addi	s1, a1, 0

		srli	a1, a1, 32
		jal	ra, bios_hex32out

		addi	a0, s0, 0
		addi	a1, s1, 0
		jal	ra, bios_hex32out

		ld	ra, 0(sp)
		ld	s0, 8(sp)
		ld	s1, 16(sp)
		addi	sp, sp, 24
		jalr	x0, 0(ra)

; SYNOPSIS
; bios_hex32out(dev, udword)
;               a0     a1
;
; INPUTS
;    dev	unused
;    udword	The 32-bit word to print the value of.
;
; FUNCTION
; Prints the value of udword to the selected output device,
; in hexadecimal form.

bios_hex32out:	addi	sp, sp, -24
		sd	ra, 0(sp)
		sd	s0, 8(sp)
		sd	s1, 16(sp)

		addi	s0, a0, 0
		addi	s1, a1, 0

		srli	a1, a1, 16
		jal	ra, bios_hex16out

		addi	a0, s0, 0
		addi	a1, s1, 0
		jal	ra, bios_hex16out

		ld	ra, 0(sp)
		ld	s0, 8(sp)
		ld	s1, 16(sp)
		addi	sp, sp, 24
		jalr	x0, 0(ra)

; SYNOPSIS
; bios_hex16out(dev, udword)
;               a0     a1
;
; INPUTS
;    dev	unused
;    udword	The 16-bit word to print the value of.
;
; FUNCTION
; Prints the value of udword to the selected output device,
; in hexadecimal form.

bios_hex16out:	addi	sp, sp, -24
		sd	ra, 0(sp)
		sd	s0, 8(sp)
		sd	s1, 16(sp)

		addi	s0, a0, 0
		addi	s1, a1, 0

		srli	a1, a1, 8
		jal	ra, bios_hex8out

		addi	a0, s0, 0
		addi	a1, s1, 0
		jal	ra, bios_hex8out

		ld	ra, 0(sp)
		ld	s0, 8(sp)
		ld	s1, 16(sp)
		addi	sp, sp, 24
		jalr	x0, 0(ra)

; SYNOPSIS
; bios_hex8out(dev, udword)
;               a0     a1
;
; INPUTS
;    dev	unused
;    udword	The 8-bit word to print the value of.
;
; FUNCTION
; Prints the value of udword to the selected output device,
; in hexadecimal form.

bios_hex8out:	addi	sp, sp, -24
		sd	ra, 0(sp)
		sd	s0, 8(sp)
		sd	s1, 16(sp)

		addi	s0, a0, 0
		addi	s1, a1, 0

		srli	a1, a1, 4
		jal	ra, bios_hex4out

		addi	a0, s0, 0
		addi	a1, s1, 0
		jal	ra, bios_hex4out

		ld	ra, 0(sp)
		ld	s0, 8(sp)
		ld	s1, 16(sp)
		addi	sp, sp, 24
		jalr	x0, 0(ra)


; SYNOPSIS
; bios_hex4out(dev, udword)
;               a0     a1
;
; INPUTS
;    dev	unused
;    udword	The 4-bit word to print the value of.
;
; FUNCTION
; Prints the value of udword to the selected output device,
; in hexadecimal form.

bios_hex4out:	addi	sp, sp, -8
		sd	ra, 0(sp)

		andi	a1, a1, 15
		jal	ra, bios_hextab
		add	a1, a1, a2
		lbu	a1, 0(a1)
		jal	ra, bios_chrout

		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)

bios_hextab:	jalr	a2, 0(ra)
		byte	"0123456789ABCDEF"
		align	4

