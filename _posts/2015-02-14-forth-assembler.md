---
layout: post
title:  "Using the One-Pass RISC-V Assembler"
date:   2015-02-14 15:00:00
---

Not too long ago,
I completed a RISC-V RV32I and RV64I-subset assembler written using SwiftForth.
In this article, I'd like to illustrate how I've been using it.
Please note,
the assembler has not landed in master branch,
as I haven't completed the complete set of RV32I and RV64I instructions yet.

The assembler requires a *32-bit* ANS-compliant Forth environment for a *little-endian* processor.
I've been using [SwiftForth i386-Linux 3.5.6 26-Oct-2014](http://www.forth.com/swiftforth/index.html).
It *may* work with a 64-bit Forth; I haven't tried it.
It *definitely will not* work on a big-endian platform without code changes.
I can't imagine getting it working should be terribly difficult though,
as code which is environment-specific has appropriate commentary.

In this article, I'll dissect one of the Kestrel emulator's verification programs.
The complete listing appears in the conclusion, below.

# Assembling and Building the Software

To build the software in this article, I have a script `romfile.f`:

        include src/vasm/va.f
        include src/e/m4.asm
        2 argv >rom
        bye

It is invoked via a [redo](https://github.com/apenwarr/redo) script like so:

        sf src/e/romfile.f $3 >&2

where `sf` invokes the above-mentioned SwiftForth interpreter.

You'll notice that we start by including the assembler.
The assembly listing, then, comes as a separate include file.
The `>rom` <i>( c-addr u &mdash; )</i> word saves the assembled binary image to the named file.
If you wish to statically provide the ROM-file name, you can use `rom"`,
like so:

        rom" my-rom-file"

That's basically it, at this point.

The assembler does *not* provide a relocatable object file format at this time.
I simply don't need it just yet.
However, when I port the STS operating system to the Kestrel-3 environment,
I'll almost certainly need to implement a relocatable file format then.

# Assembly Listing Structure

You'll notice right away that the assembler listing consists of Forth code.
The dead give-aways include comments in parentheses or after back-slashes,
and the reverse-polish notation (operands precede operations).

        \ This comment extends to the end of the line.
        \ Parentheses are used for smaller comments, like so:
        1 ( a number ) 2 ( another number ) + . ( should print 3 )

Perhaps more importantly,
for those who remember the horrors of Kestrel-2 machine Forth,
you'll notice an absence of commas everywhere.

Assembly listings have less rigorously defined program structure than the Kestrel-2 Machine Forth listings.
Make no mistake: this is not a Forth subset compiler;
this is a *real* assembler, producing *arbitrary* programs with
no presumptions of being used in a Forth environment.

## Setting Assembly Origin

You might recall from the days of CP/M or Commodore 8-bit machines that
your assembly listings included an `ORG` statement to set the "origin".
This origin determined, exclusively, where in memory
your assembly language program would (often) load and (always) run.

### The `ORG` Directive

The RISC-V assembler, similarly, includes an `ORG` directive:

        $0000 ORG

Because all RISC-V opcodes are position-independent by design, this
directive doesn't mean as much as it used to.
Indeed, if you do not provide it, the origin defaults to zero.

Please observe: if opcodes are position independent by design,
why include an `ORG` directive at all?
It proves more useful when building complex data structures using the
`D,`, `W,`, and related construction directives.
(Discussed below.)

### Location Counter

The assembler also provides a *pseudo-symbol* called LC.
This *location counter* always holds the address of the next byte to be placed by the assembler.

        LC x0 jal               ( Halt. )

This instruction, for example, will always jump to itself;
even if we never know its absolute address.

### More on the Influence of `ORG` on Data Structures

Encoding the location of something can take two forms:
relative or absolute.
Encoding absolute addresses in a binary image requires a base address to
perform address arithmetic on.
This is the job of `ORG`.

For example,
let's pretend someone ported [AROS](http://aros.sourceforge.net/) to the Kestrel-3,
and we wanted to use this assembler to write a library or device driver.
To do so, you need to embed a `Resident` structure somewhere in the code.
Here's how you'd do it:

        -> romtag
        $4AFC H,        ( match word )
        romtag W,       ( points back to itself )
        0 W,            ( endSkip parameter )
        129 B, 33 B,    ( flags and version )
        NT_DEVICE B,    ( type of resident module )
        100 B,          ( initialization/discovery priority )
        AW> devname W,  ( device name )
        AW> idstr W,    ( device ID string )
        AW> init W,     ( initialization function address )

        -> devname
        S" typical.device" ASCII, 0 B,

        -> idstr
        S" typical 33.10 (1990-Mar-21)" ASCII, 0 B,

        -> init
                \ initialization logic here...

Notice that we include both forward and backward references to symbols.
Without setting the origin,
the statement `romtag W,` will produce a wrong address, as will
anything that starts with `AW>`.

## Laying Data Structures in Memory

The assembler includes several methods of laying data into memory,
depending on the type of data you want to place.
Here, we place strings and individual bytes:

        -> msg1 S" Polaris V1 RISC-V CPU" ASCII, 13 B, 10 B,
        -> msg1end

        -> msg2 S" Hello world!" ASCII, 13 B, 10 B,
        -> msg2end

The assembler also provides `H,`, `W,`, and `D,` for
16-bit, 32-bit, and 64-bit numbers, respectively:

        -> uart-tx      $0F000000.00000000 D,

## Advancing to an Arbitrary Address

Let's go back to `ORG` briefly.
You might recall in days of yore that you could use `ORG` to relocate
the assembler's location counter arbitrarily.
Programmers often exploited this to leave gaps in the program,
often for buffer allocation,
or just to ensure proper program alignment.

This assembler doesn't support this use of the `ORG` directive.
It could,
but it'd introduce a level of complexity that I felt wasn't worth the
investment.
Instead, a simpler, more explicit directive exists for this purpose:

        $CC $2000 ADVANCE       ( RISC-V ISA spec says we boot here. )

The `ADVANCE` directive takes two arguments.
The first is the value to fill in the unused space with.
The second argument is the address we wish to continue assembling at.
In the example above,
instructions assembled after the `ADVANCE` directive will be placed at address $2000 and higher.

I picked $CC for the fill byte above because
it has several benefits with respect to debugging:
1) All CPU instructions have bits 1 and 0 set, so
any attempt to execute an instruction in this unused space will
produce an illegal instruction exception.
2) Kestrel addresses start with $00, $01, or $0F.
Thus, attempting to reference data with an address that
starts with $CC will result in an illegal access exception.
3) $CC..CC is a pattern which is easily visible to programmers.

You can use the `ADVANCE` directive to fill in arbitrary numbers of bytes by using address arithmetic:

        $CC  LC 16 + ADVANCE

will provide exactly 16 bytes of $CC in memory.

## Forward References

The RISC-V instruction set architecture specifies at least five different ways of encoding operands for its instructions.
This means we need (at least) five forward-parsing words to keep track of forward references.
These are as follows:

* `AW>` &mdash; 32-bit absolute forward reference to a symbol.
* `AD>` &mdash; 64-bit absolute forward reference to a symbol.
* `B>` &mdash; 12-bit signed forward reference suitable for conditional branches.
* `JAL>` &mdash; 20-bit signed forward reference suitable for the `JAL` instruction.
* `GL>` &mdash; 12-bit signed forward reference suitable for memory load and `JALR` instructions relative to a global pointer.
* `GS>` &mdash; 12-bit signed forward reference suitable for memory store instructions, also relative to a global pointer.

One not nice feature of the assembler is that you, the programmer,
need to remember when to use the appropriate forward reference.
In practice, this is learned quickly; still, I'd rather this be automated somehow.
If/when I complete the two-pass assembler, this burden will disappear.

Here's a simple example:

        0 x31 auipc             ( X31 = address of next instruction )
        assume-gp
        
        x0 msg1 x1 addi         ( X1 -> msg to print )
        x0 msg1end msg1 - x2 addi       ( X2 = length of msg )
        x31 gl> putstr x3 jalr  ( try printing the string)

The `AUIPC` instruction adds (sign-extended, upper 20 bits of) the
immediate parameter to the current `PC` register contents,
leaving the result in the specified (`X31`) register.
In other words, after running the above instruction,
`X31` will point to the `x0 msg1 x1 addi` instruction.
This lets us reference absolutely-specified data in close proximity to our routine.
In this case, `X31` becomes our <q>global pointer</q>, or GP.

The `ASSUME-GP` directive tells the *assembler* what value we think is in our global pointer register.
In this case, it's the current location counter, which is the next `ADDI` instruction.
Once the assembler knows this, we can make forward references to symbols in program space.
For example, observe the `JALR` instruction, used to invoke the `putstr` subroutine.
This instruction takes a source register and 
a 12-bit, sign-extended displacement to add to its value to arrive at the subroutine's address.

We also find operand access via the global pointer in the `putstr` subroutine.

        x31 gl> uart-tx x4 ld   ( X4 -> UART TX register )

Because the Kestrel-3's address space is 64-bits wide,
but the instructions only encode 20 or fewer operand bits (depending on instruction form),
we need to load absolute addresses from memory explicitly.
The frequency of global pointer-relative loads, stores, and subroutine calls justify the `GL>`, `GS>`, and `<G` prefixes.
I'll discuss the `<G` form shortly.

## Backward References

You should never need any kind of prefixes for backward references,
except in one special case (`<G`), which I'll discuss shortly.

        -> agn
        x1 0 x8 lb              ( X8 = byte to print )
        x8 x4 0 sb              ( print it. )
        x1 1 x1 addi            ( Next byte to print )
        x2 -1 x2 addi           ( One less to print )
        x0 x2 agn bne           ( Print more characters until no more )

In the above loop,
you'll notice that the `BNE` instruction directly references the `agn` symbol.
We didn't need a `B>` prefix here, because `agn` is already defined by this point.

Likewise, when computing the lengths of the messages to print to the console,
we do so using address arithmetic:

        x0 msg1end msg1 - x2 addi       ( X2 = length of msg )

There is a special case where you still need a prefix though.
Consider this program fragment:

        -> aSubroutine
        x0 42 x2 addi
        x1 0 x0 jalr

        -> ultimateAnswer
        0 x31 auipc
        assume-gp
        x31 aSubroutine x1 jalr         ( point 1; crash! )
        \ ...

When we call `aSubroutine` at point 1,
the program will branch to the wrong address.
At this point, X31 points to the `JALR` instruction.
Thus, we expect to find a negative offset to the `JALR` instruction
in order to call backwards in program space.
The problem is, a simple reference to `aSubroutine`
will leave its *address*, which is a *positive* number.
Thus, the CPU will branch to an address that is `X31`+(a potentially huge number).

We use the `<G` prefix to fix this problem.
It calculates the GP-relative displacement for a *backward* reference.
(This is why the 'arrow' points to the left.)

        x31 <G aSubroutine x1 jalr      ( This is correct. )

Note that, unlike `GL>` and `GS>`, `<G` applies for both loads *and* stores,
as `<G` does not produce a relocation record for later resolution.

## Defining Symbols

By now, you probably already guessed that `->` defines new symbols.
From the point of definition,

        -> putstr

is equivalent to this Forth code:

        LC VALUE putstr

In addition to defining a VALUE-like Forth word,
it also takes care of any pending forward references to the symbol.

# Conclusion

In this post, I illustrated several directives of the assembler.
I showed how I use the assembler to build flat ROM files for emulator consumption.
I also illustrated how a typical listing is structured by
examining smaller pieces in isolation and exploring their relationships.

The listing below puts all the pieces together.
This program, in fact,
is the Polaris emulator's second verification and validation milestone.

        \ This software is the Kestrel-3's second milestone: print a message and halt.
        \ We do this by calling a subroutine.

                $0000 ORG

        -> msg1 S" Polaris V1 RISC-V CPU" ASCII, 13 B, 10 B,
        -> msg1end

        -> msg2 S" Hello world!" ASCII, 13 B, 10 B,
        -> msg2end

                $CC $2000 ADVANCE       ( RISC-V ISA spec says we boot here. )

                0 x31 auipc             ( X31 = address of next instruction )
                assume-gp

                x0 msg1 x1 addi         ( X1 -> msg to print )
                x0 msg1end msg1 - x2 addi       ( X2 = length of msg )
                x31 gl> putstr x3 jalr  ( try printing the string)

                x0 msg2 x1 addi
                x0 msg2end msg2 - x2 addi
                x31 gl> putstr x3 jalr

                LC x0 jal               ( Halt. )

        -> putstr
                x31 0 x30 addi          ( Save and assume a GP )
                0 x31 auipc
                assume-gp

                x31 gl> uart-tx x4 ld   ( X4 -> UART TX register )
        -> agn
                x1 0 x8 lb              ( X8 = byte to print )
                x8 x4 0 sb              ( print it. )
                x1 1 x1 addi            ( Next byte to print )
                x2 -1 x2 addi           ( One less to print )
                x0 x2 agn bne           ( Print more characters until no more )

                x30 0 x31 addi          ( Restore GP )
                x3 0 x0 jalr            ( return )

        -> uart-tx      $0F000000.00000000 D,

