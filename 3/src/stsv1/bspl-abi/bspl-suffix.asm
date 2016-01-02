; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

; THIS MUST BE THE LAST FILE IN THE STS IMAGE.

; exits the emulator if we're running inside of one;
; otherwise, deadlocks the machine.

bye:            addi    rsp, rsp, -8
                sd      x0, 0(rsp)
                csrrw   x0, rsp, mtohost
                jal     x0, *

; This stub is required to support jump tables in BSPL.  It pushes
; the absolute address of the jump table onto the data stack.
; 
; jump-table: foo will compile a call to this procedure.
; Use jump-entries: to compile jump instructions to appropriate
; entries.

__jumptable__:	addi	dsp, dsp, -8	; Push address of jump table
		sd	t0, 0(dsp)
		jalr	x0, 0(ra)

; The call procedure is used to invoke a dynamically determined
; procedure.
;
; call ( ... proc -- ... )

call:		ld	x16, 0(dsp)
		addi	dsp, dsp, 8
		jalr	x0, 0(x16)

; Configures the CPU to run BSPL code.  We need to reset the stack pointers
; and the global variable vector pointer.

__cold__:       addi    dsp, x0, $10	; DSP -> $1000 ($0C00..$0FFF)
		slli	dsp, dsp, 8
                add     rsp, dsp, dsp	; RSP -> $2000 ($1000..$1FFF)
                add     gvp, rsp, rsp	; GVP -> $4000 ($3800..$47FF)
                jal     x0, _

; Normally, we would have the CPU reset vector declaration here.
; However, since we're porting to run underneath the Kestrel-3 BIOS,
; I'm going to comment this out for now.  BIOS is expected to dispatch
; to __cold__ after it resets and bootstraps itself.

;                adv     $FFF00, $CC
;                jal     x0, __cold__
