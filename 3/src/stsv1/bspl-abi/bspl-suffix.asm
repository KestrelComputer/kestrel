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

; Configures the CPU to run BSPL code.  We need to reset the stack pointers
; and the global variable vector pointer.

__cold__:       addi    dsp, x0, $0400	; DSP -> $0400 ($0000..$03FF)
                add     rsp, dsp, dsp	; RSP -> $0800 ($0400..$07FF)
                add     gvp, rsp, rsp	; GVP -> $1000 ($0800..$17FF)
                jal     x0, _

                adv     $FFF00, $CC
                jal     x0, __cold__
