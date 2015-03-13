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

Chuck Moore, inventor of the Forth programming language, also invented a number of Forth-based microprocessors as well.
Programming his most recent processors required using a particular subset of Forth which [Moore dubbed "Machine Forth."](http://www.ultratechnology.com/mfp21.htm)
The primitives are so simple, and so basic, that nearly any real-world microprocessor supports a mapping to Machine Forth with a relative minimum of host instructions.
Each primitive mapped to one, sometimes two, and relatively rarely, three or more Intel 80x86 assembly language instructions.
Moore and Fox documented a set of primitives that exploited the existing Intel microarchitecture features that best emulated their MISC architecture chip.
The latest revision of this effort resulted in the set of [primitives used to implement ColorForth, published in 2001.](http://colorforth.com/forth.html)

The following table compares the 80x86 and RISC-V expansions.
As you can see for the Intel architecture, Machine Forth maps surprisingly well to individual 80x86 instructions thanks in part to the CISC nature of its instruction set.
However, the RISC-V instruction set exhibits a bimodal degree of support;
some primitives map to one or two RISC-V instructions,
while others yield surprisingly large sequences of instructions.

                    x86                     RISC-V
    Opcode  Source  Assembly                Assembly        Description

    0       word ;  JMP label               JAL  X0,label   Jump to word; tail recursion

    1       if      JZ label                BEQ  T,X0,label Jump to 'then' if T=0

    2       word    CALL label              ADDI RP,RP,-4   Call word
                                            SW   RA,0(RP)
                                            JAL  RA,label
                                            LW   RA,0(RP)
                                            ADDI RP,RP,4

    3       -if     JNS label               BLT  T,X0,label Jump to 'then' if not negative

    6       ;       RET                     JALR X0,0(RA)   Return to calling word

    8       @       MOV EAX, [EAX*4]        LW   T,0(T)     Fetch from address on stack (option 1)

                    dup                     (no equiv.)     (option 2)
                    mov EAX, addr

    9       @+      dup                     dup             Fetch from address in A; increment A
                    mov EAX, [EDX*4]        LW   T,0(A)
                    inc EDX                 ADDI A,A,4

    10      n       dup                     dup             Fetch number (option 1)
                    MOV EAX, n              LW   T,ofs(GP)

                    (no equiv.)             dup             (option 2; -2048<=n<2048 for RISC-V)
                                            ADDI T,X0,n

    11      @r      (undocumented)          dup             Fetch from address in R
                                            LW   T,0(RA)

    12      !       a!                      a!              Store to address on stack (option 1)
                    MOV [EDX*4], EAX        SW   T,0(A)
                    drop                    drop

                    MOV a*4, EAX            (no equiv.)     (option 2)
                    drop

                    MOV a*4, n              (no equiv.)     (option 3)

    14      !+      MOV [EDX*4], EAX        SW   T,0(A)     Store to address in A; increment A
                    INC EDX                 ADDI A,A,4

    15      !r      (undocumented)          SW   T,0(RA)    Store to address in R; increment R
                                            ADDI RA,RA,4

    16      2*      SHL EAX, 1              SLL  T,T,1      Shift stack left

    17      2/      SAR EAX, 1              SRA  T,T,1      Shift stack right, propagate sign

    18      -       NOT EAX                 XORI T,T,-1     Ones complement stack

    19      and     AND EAX, [ESI]          LW   T1,0(SP)   And to stack (option 1)
                    nip                     AND  T,T,T1
                                            nip

                    AND EAX, n              ANDI T,T,n      (option 2; -2048<=n<2048 for RISC-V)

    21      or      XOR EAX, [ESI]          LW   T1,0(SP)   Exclusive-or to stack (option 1)
                    nip                     XOR  T,T,T1
                                            nip

                    XOR EAX, n              XORI T,T,n      (option 2; -2048<=n<2048 for RISC-V)

    22      +       ADD EAX, [ESI]          LW   T1,0(SP)   Add to stack (option 1)
                    nip                     ADD  T,T,T1
                                            nip

                    ADD EAX, n              ADDI T,T,n      (option 2; -2048<=n<2048 for RISC-V)

    23      *+      (unused)                (unused)        Multiply step

    24      push    PUSH EAX                ADDI RP,RP,-4   Push stack onto Return
                    drop                    SW   RA,0(RP)
                                            ORI  RA,X0,T
                                            drop

    25      a       dup                     dup             Load A register onto stack
                    MOV EAX, EDX            ORI  T,X0,A

    26      dup     LEA ESI, ESI-4          ADDI SP,SP,-4   Duplicate top of stack
                    MOV [ESI], EAX          SW   T,0(SP)

    27      over    dup                     dup             Load 2nd datum onto stack
                    MOV EAX, [ESI+4]        LW   T,4(SP)

    28      pop     dup                     dup             Pop Return onto stack
                    POP EAX                 ORI  T,X0,RA
                                            LW   RA,0(RP)
                                            ADDI RP,RP,4

    29      a!      MOV EDX, EAX            ORI  A,X0,T     Store stack into A register
                    drop                    drop

    30      drop    LODSD                   LW   T,0(SP)    Discard stack
                                            ADDI SP,SP,4

    31      nop     NOP                     ORI  X0,X0,0    Do nothing

    n/a     nip     LEA ESI,[ESI+4]         ADDI SP,SP,4    Pops the 2nd top of stack.


## Tail-Call Optimization

Machine Forth requires tail-call optimization to enable simple looping constructs without bulking up the compiler with immediate words.
For example, a program to iterate all integers between 0 and 99 for a popular song might look like:

    : bottles ( n -- )   ...etc... ;
    : song0 ( n -- )     IF DUP bottles -1 + song0 ; THEN DROP ;
    : song ( -- )        99 song0 ;

Intel CPUs support this relatively easily, requiring the compiler to back-patch only one previously deposited byte of code.
I illustrate the process below, with the caret representing the compiler's current input pointer:

    foo bar ;               foo bar ;               foo bar ;
        ^                           ^                         ^

    CALL    foo             CALL    foo             CALL    foo
                            CALL    bar             JMP     bar


As we'd expect, the compiler emits a `CALL foo` instruction after encountering a reference to `foo` in the instruction stream.
Since the compiler lacks any look-ahead, it also emits `CALL bar` when it encounters `bar`.
Only when it attempts to compile `;` will the compiler look behind in the instruction stream, and realize that it previously compiled a `CALL` instruction.
It then understands that it can translate the `CALL` to a `JMP`, and thus, tail-call optimization completes.

For the RISC-V architecture, things become more complex in one of two ways.
If we elect to save the return address (RA) register at the time we call our first subroutine,
thus preserving the invariant that the `RA` register always caches the top of the return stack,
we find we need to back-patch across multiple bytes on every subroutine call we wish to compile:


    foo bar ;               foo bar ;               foo bar ;
        ^                           ^                         ^


    ADDI RP,RP,-4           ADDI RP,RP,-4           ADDI RP,RP,-4
    SW   RA,0(RP)           SW   RA,0(RP)           SW   RA,0(RP)
    JAL  RA,foo             JAL  RA,foo             JAL  RA,foo
    LW   RA,0(RP)           JAL  RA,bar             LW   RA,0(RP)
    ADDI RP,RP,4            LW   RA,0(RP)           ADDI RP,RP,4
                            ADDI RP,RP,4            JAL  X0,bar


Note how the simple act of compiling a second subroutine call requires back-patching to avoid grotesquely wasting memory with redundant return stack manipulations.
Unfortunately, back-patching cannot occur if we need the top return stack value for any reason between subroutine calls,
and the compiler will need to be smart enough to detect this situation.
After compiling the semicolon, we back-patch again, replacing three instructions with another sequence of three,
ending with the intended `JAL X0,label` instruction.

The other approach involves unconditionally saving the return address for a subroutine using standard prolog and epilog instructions.
In this case, we trade on-demand return stack management for two new problems:

* The return stack necessarily behaves differently than the data stack.  The `DSP` register would point *to the second top of stack* value, while the `RSP` pointer must refer to *space reserved for, but not yet set to, the top of return stack*, since the top sits in the `RA` register on subroutine entry and exit.
* Consider the definition of `song0` in the example provided above.  When referenced inside the `song` top-level definition,
it points directly *at* the definition of `song0`.
When used inside of `song0` itself, however, it must point to code *just beyond that necessary to preserve the `RA` register contents*.
If it didn't, we'd corrupt the return stack upon looping.


        song0:      ADDI  RSP,RSP,-4 ;     <--- external references call here.
                    SW    RA,0(RSP)  ; (at this point, RA has no use.)
        _song0:     BEQ   T,X0,L1    ; IF  <--- However, internal references jump
                    ADDI  SP,SP,-4   ; DUP      here.
                    SW    T,0(SP)
                    JAL   RA,bottles ; bottles
                    ADDI  T,T,-1     ; -1 +
                    JAL   X0, _song0 ; song0 ;
        L1:         LW    T,0(SP)    ; DROP
                    ADDI  SP,SP,4
                    LW    RA,0(RSP)  ; ;
                    ADDI  RSP,RSP,4
                    JALR  X0,0(RA)

As you can see, the compiler becomes more complicated regardless of the approach taken.


## Literal Management

In many cases, numeric constants will fall in the range [-2048, 2047).
Working with small numeric literals proves as easy as it would for Intel architecture CPUs.
However, with roughly equal frequency in my experience, you'll want to express an address of a buffer, variable, or even call-back word.
With RAM starting at $0100000000000000 in the Kestrel-3, these literals fall well outside of the +/-2KiB range; these require indirection to load into a CPU register for processing.
For this purpose, RISC-V software reserves a register to point to a pool of literals, known as the "global pointer", or GP for short.

Each colon definition will need to initialize this global pointer if the compiler finds out that it's required.
The compiler will need to reset the global pointer after it completes a run of subroutine calls as well,
on the assumption that at least one of the subroutines will alter the global pointer for its own needs.

During compilation, the compiler must maintain a table of constants in a separate block of memory from the compiled program,
for the compiler doesn't know how big the program will end up becoming.
We can reasonably expect the compiler to use negative offsets from the global pointer, as doing anything else requires maintaining relative offset relocations, further complecting the compiler.
Remember that an index may range from -2048 to 2047, inclusive.
This practically limits the *combined constants and program space* to 2KiB.
(Proper support for the full 4KiB range requires more sophistication, and thus,
a more complex compiler.)
The compiler will need to continually monitor for global offsets for those that fall outside this range.

Here's how it all works together; assume that `foo bar 4096 baz ;` represents the contents of a colon definition.

    foo bar 4096 baz ;    foo bar 4096 baz ;      foo bar 4096 baz ;
        ^                          ^                            ^
        
                                               -->  WORD  4096
    JAL RA,foo             JAL RA,foo               JAL   RA,foo
                           JAL RA,bar               JAL   RA,bar
                                                    ADDI  SP,SP,-4  <--+
                                                    SW    T,0(SP)      |
                                                    AUIPC GP,0         |
                                                    LW    T,-24(GP) <--+

We see that when compiling the number too large for immediate encoding,
we allocate a spot for it adjacent to the routine,
and reference it via a negative offset from the global pointer.
Note how the compiler had to logically, if not physically, make space for the literal at the start of the definition.
The compiler will also need to remember whether or not it has to re-initialize the GP register, so as to not emit redundant code.
It will need to do this for every colon definition you write.

When laying the procedure down in the dictionary, though,
the compiler will need to place the constants pool first, and then the code thereafter.
This means the compiler cannot know the word's actual address until
after it lays down the constant pool, at the very least.


## Code Bloat

Intel's x86 instruction set remains byte-coded to this day.
Variable length instruction sequences ensures commonly used instructions *generally* have shorter representation in memory.
For this reason, while the total number of instructions might compare well between x86 and RISC-V Machine Forth instruction sequences, Intel's encoding holds a clear advantage over RISC-V's rigidly defined instruction word lengths.

As a result, seemingly simple sequences of Machine Forth instructions may require a surprising amount of memory to encode.
Consider the `!` instruction to store a number to an arbitrary address.
In the table above, we see it defined as:

    a!
    SW   T,0(A)
    drop

We see it depends on two other macro expansions to function: `a!` and `drop`.
When we recursively expand these,
we get this final result in memory:

    ORI  A,X0,T     ; a!
    LW   T,0(SP)
    ADDI SP,SP,4
    SW   T,0(A)
    LW   T,0(SP)    ; drop
    ADDI SP,SP,4

In the absence of any other form of optimization,
this sequence appears for *every* occurance of `!` in any Machine Forth source code you compile.
That's 24 bytes for each and every use of the store instruction.
If my math is right, I calculate only 5 bytes for Intel's encoding scheme.

In general, Intel's encoding yields code one-half to one-quarter the size of the equivalent RISC-V software.

One method to work around this problem is to implement large sequences of instructions as runtime-provided subroutines,
which the software then calls with a single `JAL` instruction.
That drops the space used to, say, 24 to 28 bytes plus another 4 bytes for each additional use.
Essentially, subroutine-threading.
However, the compiler now needs to recognize *three* classes of words:
true primitives (definitions trivially inlined with `,`),
primitives which really aren't but we like to pretend they are (such as `!`),
and then colon definitions, which as illustrated above, opens a world of complexity unto itself.
By my estimate, I'd have to implement just about half of the available "primitives" as pseudo-primitives.


## Conclusion

I like to think I've convinced you that Machine Forth for RISC-V isn't a worthy trade-off.
I may yet decide to implement a Machine Forth compiler for RISC-V;
however, alternative languages,
such as a dialect of Lisp or a different dialect of Forth,
seem like they're more appropriate for the RISC-V instruction set.
I will attempt to provide analyses of other language options in the future, but
only after I continue to program the RISC-V architecture in hand-crafted assembly language.
Without that experience, I won't know the pain-points unique to RISC-V coding,
and thus, what to optimize the language for.

