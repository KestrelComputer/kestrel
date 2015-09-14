; exits the emulator if we're running inside of one;
; otherwise, deadlocks the machine.

bye:            addi    rsp, rsp, -8
                sd      x0, 0(rsp)
                csrrw   x0, rsp, $780
                jal     x0, *

; Configures the CPU to run BSPL code.  We need to reset the stack pointers and
; the global variable vector pointer.

____:           addi    dsp, x0, $0400
                add     rsp, dsp, dsp
                add     gvp, rsp, rsp
                jal     x0, _

                adv     $FFF00, $CC
                jal     x0, ____
