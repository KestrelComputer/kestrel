---
layout: post
title:  "Why Not Machine Forth for the RISC-V Platform?"
date:   2015-03-11 15:00:00
---

## Abstract

The RISC-V instruction set architecture proves singularly difficult to adapt to a naive interpretation of the Machine Forth concept.
Some of the problems it exhibits includes literal management, stack management, and control flow discrepencies inside and outside of a colon definition.
This article attempts to explain in reasonable detail the problems encountered, and why I decided against using Machine Forth for the Kestrel-3's system software.

## Introduction

In 2001, Chuck Moore, inventor of Forth, released an updated set of [ColorForth primitives](http://colorforth.com/forth.html).
These primitives descended from earlier work with Jeff Fox and [Machine Forth for the MuP21 microprocessor.](http://www.ultratechnology.com/mfp21.htm)
The primitives were simple enough that a compiler could naively expand a single sequence of host microprocessor instructions for each Machine Forth instruction.
Moore and Fox aimed to produce a set of primitives that exploited the existing (80x86) microprocessor semantics that best emulated an ideal MISC architecture chip.
Indeed, the ColorForth page linked to previously lists the expansion for every Machine Forth primitive he defined.

As you can see for the Intel architecture, Machine Forth maps surprisingly well to individual instructions thanks in part to the CISC nature of the instruction set.
However, the RISC-V instruction set exhibits a bimodal degree of support; some primitives map to one or two RISC-V instructions, while others yield large sequences of instructions.
The following table compares the x86 and RISC-V RV64I expansions.

                    x86                     RISC-V
    Opcode  Source  Assembly                Assembly        Description

    0       word ;  jmp                     JAL  X0,label   Jump to word; tail recursion

    1       if      jz                      BEQ  T,X0,label Jump to 'then' if T=0

    2       word    call                    ADDI RP,RP,-4   Call word
                                            SW   RA,0(RP)
                                            JAL  RA,label

    3       -if     jns                     BLT  T,X0,label Jump to 'then' if not negative

    6       ;       ret                     ADDI RP,RP,4    Return to calling word
                                            LW   RA,-4(RP)
                                            JALR X0,0(RA)

    8       @       mov EAX, [EAX*4]        LW   T,0(T)     Fetch from address on stack (option 1)

                    dup; mov EAX, a                         (option 2)

    9       @+      dup; mov EAX, [EDX*4]   dup             Fetch from address in A; increment A
                    inc EDX                 LW   T,0(A)
                                            ADDI A,A,4

    a       n       dup; mov EAX, n         dup             Fetch number (option 1)
                                            ADDI T,X0,n

                                            dup             (option 2)
                                            LW   T,ofs(GP)

    b       @r      (undocumented)          dup             Fetch from address in R
                                            LW   T,0(RA)

    c       !       a!; mov [EDX*4], EAX    a!              Store to address on stack (option 1)
                                            SW   T,0(A)
                    drop                    drop

                    mov a*4, EAX; drop                      (option 2)

                    mov a*4, n                              (option 3)

    d       (unassigned)

    e       !+      mov [EDX*4], EAX        SW   T,0(A)     Store to address in A; increment A
                    inc EDX                 ADDI A,A,4

    f       !r      (undocumented)          SW   T,0(RA)    Store to address in R; increment R
                                            ADDI RA,RA,4

    10      2*      shl EAX, 1              SLL  T,T,1      Shift stack left

    11      2/      sar EAX, 1              SRA  T,T,1      Shift stack right, propagate sign

    12      -       not EAX                 XORI T,T,-1     Ones complement stack

    14      and     and EAX, [ESI]; nip     LW   T1,0(SP)   And to stack (option 1)
                                            AND  T,T,T1
                                            nip

                    and EAX, n              ANDI T,T,n      (option 2) (-2048<=n<2048 for RISC-V)

    15      or      xor EAX, [ESI]; nip     LW   T1,0(SP)   Exclusive-or to stack (option 1)
                                            XOR  T,T,T1
                                            nip

                    xor EAX, n              XORI T,T,n      (option 2) (-2048<=n<2048 for RISC-V)

    16      +       add EAX, [ESI]; nip     LW   T1,0(SP)   Add to stack (option 1)
                                            ADD  T,T,T1
                                            nip

                    add EAX, n              ADDI T,T,n      (option 2) (-2048<=n<2048 for RISC-V)

    17      *+      (unused)                (unused)        Multiply step

    18      push    push EAX; drop          ADDI RP,RP,-4   Push stack onto Return
                                            SW   RA,0(RP)
                                            ORI  RA,X0,T
                                            drop

    19      a       dup; mov EAX, EDX       dup             Load A register onto stack
                                            ORI  T,X0,A

    1a      dup     lea ESI, ESI-4;         ADDI SP,SP,-4   Duplicate top of stack
                    mov [ESI], EAX          SW   T,0(SP)

    1b      over    dup; mov EAX, [ESI+4]   dup             Load 2nd datum onto stack
                                            LW   T,4(SP)

    1c      pop     dup; pop EAX            dup             Pop Return onto stack
                                            ORI  T,X0,RA
                                            LW   RA,0(RP)
                                            ADDI RP,RP,4

    1d      a!      mov EDX, EAX; drop      ORI  A,X0,T     Store stack into A register
                                            drop

    1e      drop    lodsd                   LW   T,0(SP)    Discard stack
                                            ADDI SP,SP,4

    1f      nop     nop                     ORI  X0,X0,0    Do nothing

    n/a     nip     lea ESI,[ESI+4]         ADDI SP,SP,4    Pops the 2nd top of stack.


## Tail-Call Optimization

Machine Forth requires tail-call optimization to enable simple looping constructs without bulking up the compiler with immediate words.
Intel CPUs support this relatively easily, requiring the compiler to back-patch previously deposited code.
I illustrate the process below, with the caret representing the compiler's current input pointer:

    foo bar ;               foo bar ;               foo bar ;
        ^                           ^                         ^

    CALL    foo             CALL    foo             CALL    foo
                            CALL    bar             JMP     bar


As we'd expect, the compiler emits a `CALL foo` instruction after encountering a reference to `foo` in the instruction stream.
Since the compiler lacks any look-ahead, it also emits `CALL bar` when it encounters `bar`.
Only when it attempts to compile `;` will the compiler look behind in the instruction stream, and realize that it previously compiled a `CALL` instruction.
It then understands that it can translate the `CALL` to a `JMP`, and thus, tail-call optimization completes.

For the RISC-V architecture, code becomes significantly more complex.


    foo bar ;               foo bar ;               foo bar ;
        ^                           ^                         ^


    ADDI RP,RP,-4           ADDI RP,RP,-4           ADDI RP,RP,-4
    SW   RA,0(RP)           SW   RA,0(RP)           SW   RA,0(RP)
    JAL  RA,foo             JAL  RA,foo             JAL  RA,foo
    LW   RA,0(RP)           JAL  RA,bar             JAL  X0,bar
    ADDI RP,RP,4            LW   RA,0(RP)
                            ADDI RP,RP,4


Note how the simple act of compiling a second subroutine call requires back-patching to avoid grotesquely wasting memory with redundant return stack manipulations.
Unfortunately, back-patching cannot occur if we need the top return stack value for any reason between subroutine calls.

After compiling the semicolon, we back-patch again, replacing three instructions with a single `JAL X0,label` instruction.


## Literal Management

In many cases, numeric constants will fall between -2048 and 2047, inclusive.  
If this happens, working with numeric literals proves as easy as it would for Intel architecture CPUs.
However, with roughly equal frequency in my experience, you'll want to express an address of a buffer, variable, or even call-back word.
With RAM starting at $0100000000000000 in the Kestrel-3, these literals fall well outside of the +/-2KiB range; these require indirection to load into a CPU register for processing.
For this purpose, RISC-V software reserves a register to point to a pool of literals, known as the "global pointer."

Each colon definition will need to initialize this global pointer if the compiler finds out that it's required.
The compiler will need to reset the global pointer after it completes a run of subroutine calls as well, for at least one of the subroutines will alter the global pointer for its own needs.

During compilation, the compiler must maintain a table of constants in a separate block of memory from the compiled program, for the compiler doesn't know how big the program will end up becoming.
Since the beginning of a procedure will remain constant throughout compilation, we can reasonably expect the compiler to use negative offsets from the global pointer.
Remember that an index may range from -2048 to 2047, inclusive.
This practically limits the *combined constants and program space* to 2KiB.
The compiler will need to continually monitor for global offsets that fall outside this range.

When laying the procedure down in memory for the last time, the compiler will need to place the constants pool first, and then the code thereafter.
This means the compiler cannot know the word's actual address until after it lays down the constant pool.
Thankfully, the RISC-V instruction set is fully position independent.


## Code Bloat

Intel's x86 instruction set remains byte-coded to this day.
Variable length instruction sequences ensures commonly used instructions *generally* have shorter representation in memory.
For this reason, while the total number of instructions might compare well between x86 and RISC-V, Intel's x86 instruction set architecture holds a clear advantage over RISC-V's rigidly defined instruction word lengths.

As a result, seemingly simple sequences of Machine Forth instructions may require a surprisingly amount of memory to encode.
Consider the `!` instruction to store a number to an arbitrary address.
In the table above, we see it defined as:

    a!
    SW   T,0(A)
    drop

We see it depends on two other macro expansions to function: `a!` and `drop`.  When we fully expand these, we get this final result in memory (right-hand side eliminates the redundant `ADDI` instruction):

    Unoptimized                     Optimized

    ORI  A,X0,T     ; a!            ORI  A,X0,T
    LW   T,0(SP)                    LW   T,0(SP)
    ADDI SP,SP,4                    SW   T,0(A)
    SW   T,0(A)                     LW   T,4(SP)
    LW   T,0(SP)    ; drop          ADDI SP,SP,8
    ADDI SP,SP,4

One of these sequences appears for *every* occurance of `!` in any Machine Forth source code you compile.  Contrast with its complement, `@`, which requires only a single CPU instruction.


## Conclusion

I've gone over some of the rationale as to why Machine Forth doesn't mesh well with the RISC-V instruction set architecture.
Alternative languages, such as Lisp or a higher-level dialect of Forth such as ANSI Forth, seem more appropriate for the machine.
I will attempt to provide analyses of other language options in the future.
For now, I will continue to program the RISC-V architecture in pure assembly language.

