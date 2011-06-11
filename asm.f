0 [if]  The J1 processor sports a 13-bit wide program counter, address-
        ing cells, not bytes.  Hence, the processor can only execute
        instructions from locations $0000 to $3FFE, inclusive.
[then]

16384 constant /image
create image
/image allot

0 [if]  When assembling/compiling, repeated references into target memory
        space will need to be made.  We want to ensure that we don't
        spill over into host memory when doing so.  Accessing any cell
        or byte not belonging to the target is strictly an error, and
        will result in immediate termination of the compiler.

        It should be noted that most contemporary Forth environments are
        32-bit or 64-bit, not 16-bit.  Thus, to better emulate how the
        J1 will be referencing memory, we would like to use @ and !, but
        constrained to 16-bits wide.  ANS Forth provides no such support,
        so we synthesize our own using C@ and C!, which we pray operate
        on 8-bit units of memory.

        To facilitate more seamless support for graphics, we define
        byte address A+0 to be displayed prior to A+1.  Since, to the
        human eye, A+0 appears to the left of A+1, we treat A+0 as
        bits 15..8 of a 16-bit quantity.  In other words, we define
        the J1 arbitrarily as big-endian.  This allows us to write
        graphics routines without byte-swapping all the time.
[then]

: -small    dup 0< abort" Address out of range" ;
: -big      dup /image >= abort" Address out of range" ;
: -odd      dup 1 and abort" Attempt to access cell with unaligned address" ;
: >host     -small -big image + ;
: w@        dup c@ 8 lshift swap 1+ c@ 255 and or ;
: w!        over 8 rshift over c! 1+ c! ;
: t@        -odd >host w@ ;
: t!        -odd >host w! ;

0 [if]  We mainain a compilation pointer, cp, to remember where our next
        word should be compiled to.  It will always point somewhere inside
        the target image.
[then]

variable cp
: org       cp ! ;
: there     cp @ ;

