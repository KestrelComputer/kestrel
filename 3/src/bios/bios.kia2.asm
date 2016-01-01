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

		jalr	x0, 0(ra)

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
kia2_irq:	addi	sp, sp, -40
		sd	ra, 0(sp)
		sd	a0, 8(sp)
		sd	a1, 16(sp)
		sd	a2, 24(sp)
		sd	gp, 32(sp)

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
		; But, maybe, the ASCII queue has room.

		lbu	a2, bd_rawtl(x0)
		lbu	a0, bd_rawhd(x0)
		addi	a0, a0, -2
		andi	a0, a0, $1E
		beq	a0, a2, _kirq130

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

_kirq130:	srli	a0, a1, 8
		andi	a0, a0, $40
		beq	a0, x0, _kirq120

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

		; If control reaches here, then we suspect the event we
		; got might actually be an ASCII character.
		;
		; First thing to check is if it's a key release event.
		; If it is, skip everything else.

_kirq120:	srli	a0, a1, 8
		andi	a0, a0, $80
		bne	a0, x0, _kirq100

		; Otherwise, we have some idea that it's an ASCII character.
		; Next step is to translate it to the final value according
		; to the current shift-state.

		lbu	a0, bd_shifts(x0)
		srli	a2, a0, 4	; Fold right and left halves together
		or	a0, a0, a2
		andi	a0, a0, 7	; ignore CMD keys.


		slli	a0, a0, 1
_kirq125:	auipc	gp, 0
		add	a0, a0, gp
		addi	a0, a0, _kirq126-_kirq125
		lh	a0, 0(a0)
		add	a0, a0, gp
		andi	a1, a1, 255
		add	a0, a0, a1
		lb	a1, 0(a0)

		; Next we enqueue the byte, if room permits.

		lbu	a0, bd_aschd(x0)	; Exit if ASCII queue is full
		lbu	a2, bd_asctl(x0)
		addi	a0, a0, -1
		andi	a0, a0, $F
		beq	a0, a2, _kirq100

		addi	a2, a2, bd_ascque	; Enqueue converted ASCII byte
		sb	a1, 0(a2)
		lb	a2, bd_asctl(x0)
		addi	a2, a2, 1
		andi	a2, a2, 15
		sb	a2, bd_asctl(x0)

_kirq100:	ld	ra, 0(sp)
		ld	a0, 8(sp)
		ld	a1, 16(sp)
		ld	a2, 24(sp)
		ld	gp, 32(sp)
		addi	sp, sp, 40
		jalr	x0, 0(ra)

_kirq126:	hword	kia2_table_0 - _kirq125
		hword	kia2_table_1 - _kirq125
		hword	kia2_table_2 - _kirq125
		hword	kia2_table_1 - _kirq125
		hword	kia2_table_4 - _kirq125
		hword	kia2_table_1 - _kirq125
		hword	kia2_table_6 - _kirq125
		hword	kia2_table_1 - _kirq125

; no shift asserted
kia2_table_0:	byte	$00, $01, $02, $03, $04, $05, $06, $07	; $0x
		byte	$08, $09, $0A, $0B, $0C, $0D, $0E, $0F
		byte	$10, $11, $12, $13, $14, $15, $16, $17	; $1x
		byte	$18, $19, $1A, $1B, $1C, $1D, $1E, $1F
		byte	$20, $21, $00, $23, $24, $25, $26, $27	; $2x
		byte	$28, $29, $2A, $2B, $2C, $2D, $2E, $2F
		byte	"0123456789;;,=./"			; $3x
		byte	"@abcdefghijklmnopqrstuvwxyz[\]^-"	; $4x-$5x
		byte	"`abcdefghijklmnopqrstuvwxyz[\]^", $7F	; $6x-$7x

; CTRL
kia2_table_1:	byte	$00, $01, $02, $03, $04, $05, $06, $07	; $0x
		byte	$08, $09, $0A, $0B, $0C, $0D, $0E, $0F
		byte	$10, $11, $12, $13, $14, $15, $16, $17	; $1x
		byte	$18, $19, $1A, $1B, $1C, $1D, $1E, $1F
		byte	$20, $21, $00, $23, $24, $25, $26, $27	; $2x
		byte	$28, $29, $2A, $2B, $2C, $2D, $2E, $2F
		byte	"01", $00, "3456789;;,=./"		; $3x
		byte	$00, $01, $02, $03, $04, $05, $06, $07	; $4x
		byte	$08, $09, $0A, $0B, $0C, $0D, $0E, $0F
		byte	$10, $11, $12, $13, $14, $15, $16, $17	; $5x
		byte	$18, $19, $1A, $1B, $1C, $1D, $1E, $1F
		byte	$00, $01, $02, $03, $04, $05, $06, $07	; $6x
		byte	$08, $09, $0A, $0B, $0C, $0D, $0E, $0F
		byte	$10, $11, $12, $13, $14, $15, $16, $17	; $7x
		byte	$18, $19, $1A, $1B, $1C, $1D, $1E, $08

; SHIFT
kia2_table_2:	byte	$00, $01, $02, $03, $04, $05, $06, $07	; $0x
		byte	$08, $09, $0A, $0B, $0C, $0D, $0E, $0F
		byte	$10, $11, $12, $13, $14, $15, $16, $17	; $1x
		byte	$18, $19, $1A, $1B, $1C, $1D, $1E, $1F
		byte	$20, $21, $00, $23, $24, $25, $26, $22	; $2x
		byte	$28, $29, $2A, $2B, "<_>?"
		byte	")!@#$%^&*(::<+>?"			; $3x
		byte	"@ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~_"	; $4x-$5x
		byte	"~ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~", $7F	; $6x-$7x

; ALT
kia2_table_4:	byte	$00, $01, $02, $03, $04, $05, $06, $07	; $0x
		byte	$08, $09, $0A, $0B, $0C, $0D, $0E, $0F
		byte	$90, $91, $92, $93, $94, $95, $96, $97	; $1x
		byte	$98, $99, $9A, $9B, $9C, $9D, $9E, $9F
		byte	$A0, $A1, $00, $A3, $A4, $A5, $A6, $A7	; $2x
		byte	$A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF
		byte	$B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7	; $3x
		byte	$B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF
		byte	$E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7	; $4x
		byte	$E8, $E9, $EA, $EB, $EC, $ED, $EE, $EF
		byte	$F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7	; $5x
		byte	$F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF
		byte	$E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7	; $6x
		byte	$E8, $E9, $EA, $EB, $EC, $ED, $EE, $EF
		byte	$F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7	; $7x
		byte	$F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF

; ALT+SHIFT
kia2_table_6:	byte	$00, $01, $02, $03, $04, $05, $06, $07	; $0x
		byte	$08, $09, $0A, $0B, $0C, $0D, $0E, $0F
		byte	$90, $91, $92, $93, $94, $95, $96, $97	; $1x
		byte	$98, $99, $9A, $9B, $9C, $9D, $9E, $9F
		byte	$A0, $A1, $00, $A3, $A4, $A5, $A6, $A7	; $2x
		byte	$A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF
		byte	$B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7	; $3x
		byte	$B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF
		byte	$C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7	; $4x
		byte	$C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF
		byte	$D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7	; $5x
		byte	$D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF
		byte	$C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7	; $6x
		byte	$C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF
		byte	$D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7	; $7x
		byte	$D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF

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
