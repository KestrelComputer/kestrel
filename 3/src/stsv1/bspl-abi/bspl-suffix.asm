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

__cold__:       addi    dsp, x0, $0400	; DSP -> $0400 ($0000..$03FF)
                add     rsp, dsp, dsp	; RSP -> $0800 ($0400..$07FF)
                add     gvp, rsp, rsp	; GVP -> $1000 ($0800..$17FF)
                jal     x0, _

                adv     $FFF00, $CC
                jal     x0, __cold__
