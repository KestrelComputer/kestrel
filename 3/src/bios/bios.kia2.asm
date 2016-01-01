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

		; Set the KIA interrupt vector to our interrupt handler.
		jal	a2, kia2_irq_a1
		sd	a1, bd_kiavec(x0)

		; Enable the KIA interrupt in MIE.  Master IE bit is still
		; clear, though, so no fear of spurious interrupts yet.
		csrrc	a0, x0, mie
		addi	a1, x0, 8
		slli	a1, a1, 8
		or	a0, a0, a1
		csrrw	x0, a0, mie

		; Set our keyboard shift state to defaults.
		sb	x0, bd_shifts(x0)

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
; interrupt kia2_irq
;
; FUNCTION
; Poll KIA-II core, and enqueue results into the raw keyboard queue for
; device 1's benefit.  Then, track shift status, and attempt to see if
; we can deduce a corresponding ASCII character for the keyboard event.
; If we can, enqueue that code into the ASCII queue for device 2's benefit.

kia2_irq_a1:	jalr	a1, 0(a2)
kia2_irq:	addi	sp, sp, -32
		sd	ra, 0(sp)
		sd	a0, 8(sp)
		sd	a1, 16(sp)
		sd	a2, 24(sp)

		; Verify KIA is the origin of the interrupt.
		; If not, ignore the spurious interrupt.

		addi	a0, x0, $0200
		slli	a0, a0, 48
		lbu	a1, 0(a0)
		andi	a2, a1, $01
		bne	a2, x0, _kirq100

		; Read in the 16-bit raw keycode.

		andi	a1, a1, $C0
		slli	a1, a1, 8
		lbu	a2, 1(a0)
		or	a1, a1, a2

		; Then, pop the KIA queue.

		sb	x0, 1(a0)

		; If the raw queue is full, stop everything.

		lbu	a2, bd_rawtl(x0)
		lbu	a0, bd_rawhd(x0)
		addi	a0, a0, -2
		andi	a0, a0, $1E
		beq	a0, a2, _kirq100

		; Enqueue the keycode.

		addi	a0, x0, bd_rawque
		add	a0, a0, a2
		sh	a1, 0(a0)
		addi	a2, a2, 2
		andi	a2, a2, $1E
		sb	a2, bd_rawtl(x0)

		; At this point, the raw queue now holds our character.
		; We should check and update shift-states here.
		; Then, we should attempt to isolate an ASCII representable
		; character, and if so, enqueue that character here.

		; If bit 14 isn't set, then it cannot be a shift key event.
		; It might be an ASCII representable character though.

		addi	a0, x0, $40 
		slli	a0, a0, 8
		and	a0, a0, a1
		beq	a0, x0, _kirq100

		; At this point, we know A1 holds a non-ASCII character.
		; We recognize the following codes as shift key events:
		;
		;	E0	Left CTRL
		;	E1	Left SHIFT
		;	E2	Left ALT
		;	E3	Left CMD
		;	E4	Right CTRL
		;	E5	Right SHIFT
		;	E6	Right ALT
		;	E7	Right CMD
		;
		; For the purposes of ASCII translation, we don't much care
		; about either of the command keys.  We only care about the
		; ALT, SHIFT, and CTRL keys.
		;
		; First, check to make sure we have a real shift event.
		; If not, abort the rest of the process.

		andi	a0, a1, $F8
		xori	a0, a0, $E0
		bne	a0, x0, _kirq100

		; Compute which bit to set or clear.

		addi	a2, x0, 1
		andi	a0, a1, 7
		sll	a2, a2, a0

		; If the high bit of the keycode is set, release the shift
		; state.  Otherwise, assert it.

		srli	a0, a1, 8
		andi	a0, a0, $80
		beq	a0, x0, _kirq110

		lbu	a0, bd_shifts(x0)
		or	a0, a0, a2
		xor	a0, a0, a2
		sb	a0, bd_shifts(x0)
		jal	x0, _kirq100

_kirq110:	lbu	a0, bd_shifts(x0)
		or	a0, a0, a2
		sb	a0, bd_shifts(x0)
		jal	x0, _kirq100

_kirq100:	ld	ra, 0(sp)
		ld	a0, 8(sp)
		ld	a1, 16(sp)
		ld	a2, 24(sp)
		addi	sp, sp, 32
		jalr	x0, 0(ra)


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

		; We don't bother turning off interrupts here b/c it's not
		; needed.  If a KIA IRQ happens between loading A0 and A1,
		; then A1 will correctly read the new tail pointer.  If the
		; IRQ happens after A1 is loaded, but prior to returning,
		; then we might have a false negative, but the app will
		; loop and will pick it up the next iteration.

kia2_caninp:	lbu	a0, bd_rawhd(x0)
		lbu	a1, bd_rawtl(x0)
		xor	a0, a0, a1
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

kia2_chrinp:	addi	sp, sp, -8
		sd	s0, 0(sp)
		csrrci	x0, 1, mstatus	; disable interrupts

		; Get the current head.

		addi	a0, x0, bd_rawque
		lbu	a1, bd_rawhd(x0)
		add	a0, a0, a1
		lh	a0, 0(a0)

		; If queue is not empty, then pop it.

		lbu	a2, bd_rawtl(x0)
		beq	a1, a2, _kc100
		addi	a1, a1, 2
		andi	a1, a1, $1E
		sb	a1, bd_rawhd(x0)

_kc100:		csrrsi	x0, 1, mstatus	; enable interrupts
		ld	s0, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)
