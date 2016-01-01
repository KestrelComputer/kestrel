; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;
; ASCII Driver (depends on KIA-II driver to work)

; SYNOPSIS
; ascii_init()
;
; FUNCTION
;
; Initialize the KIA-II core.

ascii_init:	sb	x0, bd_aschd(x0)
		sb	x0, bd_asctl(x0)
		jalr	x0, 0(ra)


; SYNOPSIS
;
; yn = ascii_caninp(dev)
; a0                a0
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

ascii_caninp:	lbu	a0, bd_aschd(x0)
		lbu	a1, bd_asctl(x0)
		xor	a0, a0, a1
		jalr	x0, 0(ra)


; SYNOPSIS
;
; char = ascii_chrinp(dev)
;  a0.b               a0
;
; INPUTS
;    dev	Unused.
;
; FUNCTION
; Returns the head of the ASCII queue, then pops the queue.

ascii_chrinp:	addi	sp, sp, -8
		sd	s0, 0(sp)
		csrrci	x0, 1, mstatus	; disable interrupts

		; Get the current head.

		addi	a0, x0, bd_ascque
		lbu	a1, bd_aschd(x0)
		add	a0, a0, a1
		lb	a0, 0(a0)

		; If queue is not empty, then pop it.

		lbu	a2, bd_asctl(x0)
		beq	a1, a2, _asc100

		addi	a1, a1, 1
		andi	a1, a1, $0F
		sb	a1, bd_aschd(x0)

_asc100:	csrrsi	x0, 1, mstatus	; enable interrupts
		ld	s0, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)
