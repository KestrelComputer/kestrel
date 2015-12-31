; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;
; KIA-II Driver

; SYNOPSIS
; kia2_init()
;
; FUNCTION
;
; Initialize the KIA-II core.

kia2_init:	addi	a0, x0, $0200
		slli	a0, a0, 48

		; Attempt to clear the KIA queue.  The queue is only
		; 16 elements deep, so we should trivially be able to
		; do this.  However, to avoid deadlocking without any
		; user-visible diagnostic, we bail after only 32 tries.

		addi	a2, a2, 32
_ki100:		addi	a2, a2, -1
		beq	a2, x0, _ki110
		lbu	a1, 0(a0)
		andi	a1, a1, 1
		beq	a1, x0, _ki100
		jal	x0, 0(ra)

		; If we're here, the KIA-II is either not present, or
		; it is malfunctioning.

_ki110:		addi	a0, x0, 0
		jal	ra, bios_i_strout
		byte	"KIA-II queue not empty after 32 tries.",13,10
		byte	"Either the KIA-II core is bad, or the interface "
		byte	"doesn't exist.",13,10,10
		byte	"System halted.",13,10,0
		align	4
		jal	x0, *


; SYNOPSIS
;
; yn = kia2_caninp(dev)
; a0               a0
;
; INPUTS
;    dev	Unused.
;
; FUNCTION
; Return non-zero if at least one character awaits; zero otherwise.

kia2_caninp:	addi	a0, x0, $0200
		slli	a0, a0, 48
		lbu	a0, 0(a0)
		andi	a0, a0, 1
		xori	a0, a0, 1
		jalr	x0, 0(ra)

; SYNOPSIS
;
; char = kia2_chrinp(dev)
;  a0.h              a0
;
; INPUTS
;    dev	Unused.
;
; FUNCTION
; Returns the head of the KIA-II queue, then pops the queue.
; Unlike most other character-oriented procedures, the results are 16-bits
; wide.  Bit 15 is set if the key code is a key release event, and is clear
; otherwise.  Bit 14 is set if bits 7-0 are not to be interpreted as ASCII,
; but as a lower-level scancode.  This is used for non-ASCII-representable
; codes, such as cursor keys or function keys.

kia2_chrinp:	addi	a2, x0, $0200
		slli	a2, a2, 48
		lbu	a0, 0(a2)
		andi	a0, a0, $C0
		slli	a0, a0, 8
		lbu	a1, 1(a2)
		or	a0, a0, a1
		sb	x0, 1(a2)
		jalr	x0, 0(ra)

