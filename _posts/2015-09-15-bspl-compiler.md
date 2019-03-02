---
layout: post
title:  "The BSPL Compiler"
author: "Samuel A. Falvo II <kc5tja@arrl.net>"
date: 2015-09-15 23:55:00
---

Over the weekend of September 5 through September 7,
I had the rare opportunity to relax and write code for the Kestrel.
I rather expected to continue to refine the ROM-based Forth image.
Instead, I ended up writing a compiler
for a simple programming language
loosely inspired by
previous generations of
[Machine Forth](http://www.ultratechnology.com/mfp21.htm).
I call it BSPL,
short for Bootstrapping Systems Programming Language.

As I've [written in the past](http://kestrelcomputer.github.io/kestrel/2015/03/11/why-not-machine-forth/),
the RISC-V architecture is
singularly difficult to write a
Machine Forth dialect for.
The 80386, 6809, 65816, 68000, and similar CISCy CPU families
all provide sufficient built-in functionality
that if you restrict your instruction choices enough,
and in some cases make clever register allocations,
you can treat these CPUs more or less as a stack architecture CPU.
It's quite rare for any Machine Forth primitive
to expand to more than two CISC instructions,
making a Machine Forth implementation for CISC CPUs easy.
Software may not be the fastest possible,
but the compiler will be small,
convenient to write,
*substantially* easier to port than even the simplest of C compilers,
and utterly trivial to debug.
You could reasonably get a Machine Forth compiler
for x86
running in about two days worth of effort.
I know, [because I've done it,](https://github.com/KestrelComputer/kestrel/blob/master/cores/Kestrel-2/sw/asm.fs)
albeit for the Kestrel-2.

PowerPC, RISC-V, MIPS, SPARC, and other kinds of RISCy CPUs,
however,
don't fare nearly as well.
These CPUs provide primitives that are
far too atomic, and thus,
to emulate a stack CPU,
you literally need to translate each
Machine Forth primitive into a *sequence* of RISC instructions.
For example, simply adding two numbers on the data stack
involves the following code on RISC-V architectures:

	ld		x16, 0(dsp)
	ld		x17, 8(dsp)
	add		x16, x16, x17
	addi	dsp, dsp, 8
	sd		x16, 0(dsp)

Ouch.  If we cache the top of the data stack in a CPU register, say X16,
then we save two instructions:

	ld		x17, 0(dsp)		; DSP points to 2nd top of stack now
	add		x16, x16, x17
	addi	dsp, dsp, 8

Still, we're talking a minimum of three instructions just to add two numbers
and make sure our data stack pointer is properly aligned.
To see why this sucks so much, let's look at the same code for the 68000:

	add.l	(a0)+, d0

Along a somewhat related vein,
I don't think I need to explain the impact on code bloat this has.
It should be fairly obvious from the above example!
The larger the code, the more cache pressure you have,
and thus, the more cycles spent fetching cache lines
instead of running your code.
The RISC-V code is six times larger than the 68000 code.

Clearly, the naïve "macro expansion" method of compiling a Machine Forth dialect
will not work for RISCy CPUs.
We need something more sophisticated,
yet still small and easy enough for a curious person to understand.

To finally realize a reasonable Machine Forth-like compiler for the RISC-V architecture,
I combined several ideas from various sources, including one of my very own:
first, I redefined the run-time execution model by considering a *third stack*;
second, I abandoned the 1-pass compiler model and switched to a multi-pass compiler approach;
third, while all this is going on, I maintain the intermediate program representation in a distinct "compile buffer";
and fourth, I made the evaluation stack *ephemeral* across basic-block boundaries.

## Data, Return, and Now, Evaluation Stack

One of my great insights came when I pondered,
what if we used a three-stack virtual machine instead of a two-stack virtual machine?
I can keep Forth's traditional data and return stacks *in memory*;
but, instead of conflating CPU registers with the data stack,
I just treat CPU registers as a
dedicated evaluation stack that's kept strictly internal to the CPU.
The *compiler* keeps track of which registers are in use,
which register is *known* to be the current top of the evaluation stack,
and other matters of statically-knowable, run-time bookkeeping.

The idea is simple enough.
If we push a literal onto the stack,
we allocate a CPU register to hold that value,
and load the constant into that register.
If we use a stacked datum,
we use the corresponding register as a source to some instruction,
and then mark that register free for later re-use.

Let's pretend we have the input sequence `d# 1 d# 2 xor`.

The first time `d#` runs,
it allocates a new register (let's say it's X16),
places X16 onto the compiler's evaluation stack,
then emits code to load X16 with the value `1`.
The second time `d#` runs,
it allocates a new register (this time X17),
places X17 onto the compiler's evaluation stack,
then emits code to load X17 with the value `2`.

(Aside: In practice, it *doesn't* work this way;
as you'll read about below,
these three steps are factored out into different compiler passes.
However, this is what happens *conceptually*.
I'll get to the compiler's nano-pass design later.)

You'd think that the Forth environment would have `1` and `2`
pushed onto a stack somewhere, but it doesn't.
The Forth environment *doesn't exist* at this point.
However, the compiler *knows* that we just did something with
X16 and X17 in that order.
So, *the compiler's* evaluation stack holds references to those two registers,
also in that order.

What happens when we `xor` the two values?
The compiler knows that `xor` takes two parameters (it's a primitive),
and so consults the compiler's evaluation stack
to see which registers those parameters are in.
It finds X16 and X17, with X17 on top.
So, it generates a `xor x16, x16, x17` instruction as output,
and pops X17 off the compiler's evaluation stack.
This now leaves X16 as the new top of stack,
freeing X17 up for re-use in a subsequent computation.

BSPL currently reserves X16 through X31 for use
as the evaluation stack.
However,
I should point out that I've written a number of non-trivial programs with BSPL,
including unit testing tools and SD/MMC card device drivers.
I've yet to see more than three of these registers used in real-world code.

For straight-ahead code,
with no branches or other [basic block](https://en.wikipedia.org/wiki/Basic_block) boundaries,
this actually results in surprisingly good code.
It's not as good as a graph-coloring or see-the-future register allocator, of course.
It's wholly ignorant of superscalar execution opportunities, among other things,
and duplicate loads occur reasonably frequently.
Still, it's a far cry better than that mess I illustrated above or in my previous article on the topic.
In most cases,
a single Machine Forth primitive corresponds to a single CPU instruction.

## Ephemeral Stack

Consider the following Forth code naïvely ported to run in BSPL:

	variable foo
	: blort		1 foo @ if drop else 2 then 3 ;

After you run `blort`, what is the state of the evaluation stack?
Forget any specific values, how *deep* is that stack?
Clearly, the precise behavior will depend on the state of `foo`.
If it's zero, you'll have three things on the stack (1 2 3);
otherwise, just one (3).
This means that the 3 may appear either in register X16 or in X18,
depending on the state of `foo`.
This literally means that any code *following* the IF-statement
*cannot* know where to find the top of stack.

Traditional compilers use various control-flow analysis techniques to
"back propegate" preferred registers up into earlier segments of the generated code,
to minimize register/memory synchronization overhead.
For example, if I may over-generalize,
phi-functions in
[static single assignment](https://en.wikipedia.org/wiki/Static_single_assignment_form)
more or less gives the compiler
a back-end directive that says, "choose a register, and substitute it for all these terms above."

For now,
I work around these problems by just punting on the problem all-together.
At each basic-block boundary,
I simply *assume* the state of the evaluation stack
is completely empty.
It doesn't matter how many items I push into registers;
when execution crosses a basic boundary block,
such as a label or a jump instruction,
we throw away everything already on the evaluation stack,
and start allocating registers starting with X16 all over again.

This means you must explicitly load and store values to the data or return stack
if you want the data to persist across basic blocks.
For example, if we want to preserve the ANSI Forth semantics for the above if-statement,
we'd write it as follows:

	dword foo
	: blort		d# 1 >d foo @ if d> else d# 2 >d then d# 3 >d ;

Take a look at the consequent of the IF-statement above.
Note that I use `d>` to pop the 1 off the data stack,
which places it into a CPU register.
But, because I cross a basic block immediately afterwards,
by the time `d# 3 >d` is executed,
it's value is completely lost,
leaving only the 3 on the data stack, as intended.
Otherwise, during the alternate,
we push 2 onto the data stack,
so that by the time we leave the IF-statement,
both 1 and 2 are on the stack as we expect them to be.

(Aside:
The `d#` word is a parsing word which
takes a decimal literal and compiles it as a literal push.
Beyond that, it's unrelated to the data-stack accessors.
A corresponding `h#` exists for hexadecimal numbers as well.)

Because it takes a control flow change to invoke a colon definition,
the compiler assumes the evaluation stack is empty at the start of all definitions.
For the same reason,
the compiler must assume the evaluation stack is empty
upon returning from an invoked word.
All parameters are to exist on the *data* stack.
Put in terms compatible with other contemporary programming languages,
word invokations, IF-blocks, and BEGIN-blocks (not shown)
are *statements*, not *expressions*.

Compared to traditional or CISC-targeting Machine Forth,
BSPL (currently) can be pretty noisy
due in large part to the need to manually manage parameter persistence.
Despite this,
I find it's no worse
than the assembler I used for the Kestrel-2.
Indeed, despite the *totally* different designs,
BSPL appears to the user to be a spiritual descendent of the Kestrel-2 assembler.

Here's some code that prints an ISO 8829-1 character dump to the Kestrel-3 emulator's debugger console:

	\ Print characters in 16x16 matrix.

	\ Dump character to debugger port.
	: emit		d> h# 0E00000000000000 c! ;

	\ Print special characters or control codes.
	: cr		d# 13 >d emit  d# 10 >d emit ;
	: space		d# 32 >d emit ;

	\ Print a character followed by a space.
	\ Print a dot if the character is not printable.
	: ch		0 d@ d# 32 - -if d> d# $2E >d then emit ;
	: c			0 d@ >d ch space 0 d@ d# 1 + 0 d! ;

	\ Print 16 characters per row, then emit a carriage return.
	: r			c c c c c c c c c c c c c c c c cr ;

	\ Starting with character code 0, print 16 character rows,
	\ then deadlock.
	: boot		d# 0 >d r r r r r r r r r r r r r r r r begin again ;

## Intermediate Compile Buffer

The next contribution to the compiler
came after I realized that a 1-pass compiler is
simply impossible when your host CPU
cannot always inline a numeric literal.
Thus, I needed a multi-pass compiler,
if for no other reason than accomodating space for literals.
It turns out to be *really* handy
for dealing with efficient return address and global pointer register management as well.

Before I go further,
I want to make sure I provide appropriate attribution
for this next contribution to my compiler.
This is one of those ideas that's so obvious in retrospect,
but for some reason,
it's totally escaped me until now.

This idea was presented to me from a fellow homebrewer and 6502-entheusiast,
[Hans Franke](http://vcfe.org),
who brought this technique to my attention.
It derives from a simple 2-pass assembler
written by [Lois Nachtmann](https://www.elektormagazine.com/magazine/elektor-200501/17897)
for the 6502-based [Elektor Junior](https://en.wikipedia.org/wiki/Elektor_Junior_Computer).
This assembler was *tiny*: it fit in a meager 2KB of memory,
yet allowed forward references and other nice features typically associated with larger assemblers.
The computer and its source code
is described in a [set of books available online.](http://www.amazon.de/A.-Nachtmann/e/B00JETESMY/ref=dp_byline_cont_book_1)
I don't have these books myself;
my understanding of the technique is based on information provided by Hans,
who *does* have primary sources available to him.

Words compile not to native machine language,
as most normal Forth environments would.
Instead,
they compile to an *intermediate representation.*
This representation is basically a symbolc [MS1 instruction set.](http://users.ece.cmu.edu/~koopman/stack_computers/sec2_1.html)
At this point,
each instruction compiled takes the following form:

    n-1                  8 7      0
	+---------------------+--------+
	| //// parameter //// | opcode |
	+---------------------+--------+

The low byte specifies an opcode,
while all remaining bits in the cell
(n >= 32; in my case, n=64)
provides an operand for that opcode,
if it takes one.
(If not, the space is reserved, but goes unused.)

Instructions are laid down in a typical 1-pass compiler approach
common to virtually all Machine Forth compilers.
Here are some of the primitives BSPL supports as of this writing:

|Mnemonic|Takes Parameter|Description|
|:------:|:-------------:|:----------|
|noop||Take no action for the shortest, non-zero length of time possible.|
|lit|Offset to constant|Push literal onto evaluation stack.|
|add||Add.|
|sub||Subtract.|
|and||Bitwise AND.|
|or||Bitwise OR.|
|xor||Bitwise XOR.|
|label|Label index|Declares a label at this point in the program.|
|@8||Signed fetch byte.|
|@16||Signed fetch half-word.|
|@32||Signed fetch word.|
|@64||Signed fetch double-word.|
|!8||Store byte.|
|!16||Store half-word.|
|!32||Store word.|
|!64||Store double-word.|
|goto|Label index|Unconditional jump.|
|gotoz|Label index|Jump if TOS is zero.|
|call|String index|Call subroutine by name.|
|rfs||Return from subroutine.  (aka EXIT)|
|>r||Push item to R-stack.|
|r>||Pop item from R-stack.|
|r@|Cell offset|Fetch from R-stack.|
|r!|Cell offset|Store into R-stack.|
|>d||Push item to D-stack.|
|d>||Pop item from D-stack.|
|d@|Cell offset|Fetch from D-stack.|
|d!|Cell offset|Store into D-stack.|
|dup||Duplicate top of eval stack.|
|over||Duplicate second top of eval stack.|
|drop||Drop top of eval stack.|
|nip||Drop second top of eval stack.|
|rot||Rotate top three eval stack registers.|
|swap||Swap top two eval stack registers.|
|gotonz|Label index|Jump if TOS is non-zero.|
|2*||Shift TOS left by 1 bit.|
|u2/||Shift TOS right by 1 bit, filling in with 0 bits.|
|2/||Shift TOS right by 1 bit, preserving sign.|
|gotoge|Label index|Jump if TOS is greater than or equal to zero.|
|gvpea|Byte offset|Push effective address relative to GVP register.|
|strlit|String index|Push address and length for referenced string.|

Things differ from your common Machine Forth instruction set though.
Notice there's an instruction called `label`?
Control flow happens relative to *labels*,
the index of which is declared using the `label` primitive.
Note that a label may be declared *after* it's referenced
([see the definition of `if`](https://github.com/KestrelComputer/kestrel/blob/master/3/src/bspl/bspl.fm/pass1.fs#L148)),
which means we would need at least two compiler passes to resolve them.
(Currently, BSPL emits assembly source listings,
relying on a subsequent call to an assembler to perform the 2nd pass.
However, nothing prevents this from being done inside the compiler itself.)
Subroutines are referenced *by name*, not by address.
When you invoke `: foo`,
the compiler interns the string `foo` in a buffer,
and creates a unique token for it.
`call` then references that token in its parameter field.
Etc.

The compile buffer will have several pointers referencing it.

	+------------------+--------------+---/
	| numeric literals | ... code ... |
	+------------------+--------------+---/
	^                  ^              ^
	|                  |              |
	+- buf         fi -+          ni -+

`buf` is the compile buffer itself.  Executing that words pushes its address on the stack.
`fi` is the variable that points to the first instruction in the code space.
`ni` is the variable that points to the next instruction location, should you decide to compile another.
In between `fi` and `ni`,
for those compiler passes that use it,
another variable called `ci` refers to the current instruction being considered by that pass.
At all times, `buf` <= `fi` <= `ci` < `ni`.

Note that `fi`, `ci`, and `ni` are *indices* into the `buf` vector,
not actually pointers.
Effective addresses are always computed from them,
so I think of them in terms of pointers anyway.

As you assemble individual instructions,
they are placed at `ni`, and `ni` is bumped to the next location.
If a literal is pushed,
the whole image from `buf` to `ni` is moved
to make room for the new value at `buf`.
Obviously, in this case, we need to update both `fi` and `ni`
for later passes to use.
This can go on forever as long as `ni` doesn't overflow the buffer.

## Multi-Pass Compilation

Several compiler passes exist to incrementally refine the code
into a representation closer to a native RISC-V instruction stream.
Arguably,
the [first pass](https://github.com/KestrelComputer/kestrel/blob/master/3/src/bspl/bspl.fm/pass1.fs)
is translating the source into symbolic form.
All subsequent passes exist to
massage the highest-level intermediate representation discussed previously
into a form where one virtual instruction closely maps to a single RISC-V instruction.

After initial translation, the following passes occur in sequence.
Each pass aims to be very small, thus easily manageable.
I happened upon the idea of many tiny passes (as distinct from a few big passes) from
[this paper on Nanopasses.](http://www.cs.indiana.edu/~dyb/pubs/nano-jfp.pdf)

### Global Pointer Updates

The RISC-V architecture provides two ways to load constants into registers.
I illustrate them below:

	addi	x10, x0, n			; -2048 <= n < 2048

and

	ld		x11, offset(x5)	; for all n

Optimally, if we want to push a number between -2048 and 2047 inclusive,
then we can just emit a single `addi` instruction.
Any value outside of that range
requires we store the literal
outside the normal control flow of the program,
where we use normal memory accessors to load it into the desired register.

Right now, BSPL treats all numeric literals uniformly.
I store each literal at the beginning of the compiled procedure.
This lets me statically compute the literal's offset,
since I always know where the start of the procedure resides in memory.
Unfortunately, the CPU doesn't at run-time;
we need to use the `auipc` instruction
to retrieve the current program counter into a "global pointer" register.

We could introduce `auipc` in front of every literal load operation,
but this would cut performance significantly.
Small literals are used to bump pointers and decrement counters inside loops,
so it makes sense to optimize out all unnecessary `auipc` instructions early on.
Further, because any called subroutines may reset the global pointer,
for these subroutines might use literals themselves,
we need to also insert it in front of the first literal load after any subroutine calls.
The logic behind
the [lgp.fs module](https://github.com/KestrelComputer/kestrel/blob/master/3/src/bspl/bspl.fm/lgp.fs)
implements this intelligence.

When the `lgp.fs` pass completes,
certain literal load instructions will be prefixed
with a LGP virtual instruction, like so:

	+-------------+--------+
	|             | LGP    |  <-- inserted after this pass
	+-------------+--------+
	| byte offset | LIT    |
	+-------------+--------+
	| label index | LABEL  |
	+-------------+--------+
	|             | LGP    |  <-- inserted after this pass
	+-------------+--------+
	| byte offset | LIT    |
	+-------------+--------+
	| byte offset | LIT    |  <-- Note lack of LGP here!
	+-------------+--------+
	| label index | GOTOZ  |
	+-------------+--------+
	|             |        |

The reason we insert `LGP` after the label
should become clear when you consider that
the label exists for the purpose of control flow change.
It's possible that control will flow to that point
from somewhere such that the global pointer will not be set correctly.
The compiler plays it safe by making sure `LGP` is inserted accordingly.

Since I'm compiling for a 64-bit RISC-V architecture,
all numeric literals are stored as double-words,
even though the finished program representation will use single-words for instructions.
It would be fairly easy to adjust `pass1.fs`
to recognize constants that fit the indicated range,
and to emit a new kind of instruction that directly inlines the constant.
I just haven't done it out of laziness and a desire for semantic correctness.
Get something working first,
make it smaller/faster/better later.

### Prolog and Epilog Insertion

I actually list two passes inside
the [prolog-epilog.fs module](https://github.com/KestrelComputer/kestrel/blob/master/3/src/bspl/bspl.fm/prolog-epilog.fs).
The prolog pass basically asks the question,
"Do I need to incur the overhead of preserving the return address register?"
It works by scanning through the compiled set of instructions,
looking for *any* subroutine calls.
If no subroutine calls are detected,
then no need exists to preserve the `ra` (return address) register.
Otherwise, we insert a `prolog` virtual instruction at `fi`.
In later passes, this will be expanded into something that preserves `ra` on the run-time returns tack.

The epilog pass only runs if the prolog pass inserted a `prolog` instruction.
It walks through the compiled code,
inserting `epilog` virtual instructions in front of any subroutine returns,
if they're needed at all.
As you might expect,
`epilog` instructions will eventually expand to code that restores the return address from the return stack.

### Register Assignment

So far,
our goal in running all these passes has been
to get our internal program representation
more or less coincident
with the final assembly language output.
That is,
to the greatest extent possible,
we should be able to map
one virtual instruction
to one RISC-V instruction.

So far, however,
we have not addressed the issue of register allocation.
The [register assignment pass](https://github.com/KestrelComputer/kestrel/blob/master/3/src/bspl/bspl.fm/regs.fs)
works to allocate enumeration stack registers
and assigns them as appropriate to source and/or destination slots for individual instructions.

It works by maintaining a compile-time stack.
As each instruction receives its consideration,
the pass will either allocate or dispose of CPU registers
according to normal stack management practices.
We could just use a simple counter for this job
were it not for the availability of enumeration stack permutation instructions,
such as `over`, `dup`, and so forth.

For each instruction between `fi` and `ni`,
the pass dispatches to a specific handler routine for that class of instruction.
A simple, linear scan through the instructions proves sufficient.

Up to now, all virtual instructions had one parameter field.
Some instructions now need a plurality of parameters.
For example, `+` requires two registers, a source and a destination.
The source register will be removed from the compile-time stack,
since it's corresponding slot in the evaluation stack will no longer be allocated.
Others require a register field *and* its existing parameter field.
For such instructions, the word `scoot` exists to vacate enough bits to hold register information.
The word `scoot` is responsible for vacating enough bits to hold register allocations.
Note that not all instruction types need scooting.

The before and after results of the register allocation pass
for a few kinds of virtual instructions follows
(LGPs and artifacts from other passes elided for clarity):

	Before							After

     63          8 7      0		     63         32 31    24 23    16 15     8 7      0
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	| label index | LABEL  |		| label index                            | LABEL  |
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	| byte offset | LIT    |		| byte offset | ////// | ////// | X16    | LIT    |
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	|             | @64    |		| /////////// | ////// | ////// | X16    | @64    |
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	| byte offset | LIT    |		| byte offset | ////// | ////// | X17    | LIT    |
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	|             | ADD    |		| /////////// | ////// | X17    | X16    | ADD    |
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	|             | DUP    |		| /////////// | ////// | ////// | ////// | DUP    |
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	| byte offset | LIT    |		| byte offset | ////// | ////// | X17    | LIT    |
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	|             | !64    |		| /////////// | ////// | X17    | X16    | !64    |
	+-------------+--------+		+-------------+--------+--------+--------+--------+
	| label index | GOTOZ  |		| label index | ////// | ////// | X16    | GOTOZ  |
	+-------------+--------+		+-------------+--------+--------+--------+--------+

As you can see,
what once appeared as a more-or-less pure stack-architecture sequence of instructions
now looks quite close to RISC-V assembly language.
We can now map these virtual instructions
onto individual RISC-V instructions with greater ease.

### Opportunities for Peephole Optimization

Before continuing with the last pass in the BSPL compiler,
I need to point out that a big opportunity for optimization exists.

If we wanted to provide additional (peephole) optimizations,
such as coalescing multiple bit-shift instructions into a single instruction with a larger-than-1 count,
or coalescing `LIT ADD @` or `LIT ADD !` sequences into single instructions,
one of the times to do that would be right now.
It wouldn't even be that hard to do,
and it'd still retain the desirable characteristic
where Forth code maps closely to generated machine language.

Again, I haven't implemented any of this logic
because I wanted to focus on getting something that
produced correct (even if slow) code first.
But, as time progresses,
you can bet that
I'll be writing additional optimization passes for BSPL.

### Assembly Listing Generation

At this point,
most of the instructions in the compile buffer
corresponds to one CPU instruction.
If any optimization passes were run,
then the program in the compile buffer should be as close to optimal as
stack-architecture compiler technology can bring it.
So, the [final pass](https://github.com/KestrelComputer/kestrel/blob/master/software/src/bspl/bspl.fm/asm.fs)
through the compile buffer
produces the assembly language listing.
It walks through every instruction in the compiler buffer,
and emitting its textual representation.

Since we know every dword of memory between `buf` and `fi` correspond to numeric literals,
we know to just emit these literals as `dword` directives in the source listing.
From `fi` to `ni`, we use a jump table to invoke code
specific to the opcode.
In most cases,
that code's handler is just a one-line print routine,
dumping the listing to `stdout`.

## That's It!

And that's all it takes to convert
something resembling a Machine Forth dialect
into a RISC-V instruction stream.
The code won't run as fast as something like modern-day C output,
but right now, that's not my intent.
I just want something that is:

1.  **Simple.**  Anyone should be able to look at the code and understand how it works with minimum effort.
2.  **Maintainable.**  As I need features from the BSPL language, I should be able to adjust the compiler with minimum effort without introducing unanticipated side-effects.
3.  **Reliable.**  BSPL takes no command-line options.  You provide input, you get output.  Errors cause BSPL to abort early in most cases.

BSPL currently takes up 804 lines of code,
of which 350 lines are commentary,
leaving 444 lines of actual productive code.
I'm willing to wager that this is pretty small by *any* compiler's standards,
let alone one that is multi-pass and capable of rudimentary optimizations in the future.

BSPL did take me longer than two days to get working.
Closer to several weeks, including the odd bug-fix in my RISC-V emulator.
However, it was still easier to get running
than any C compiler project I looked at,
including BCC, TCC, TinyC, GCC, CLang, and many others.
Maybe some day, I can move on to porting a C compiler,
or somehow figure out how to properly use the GNU toolchain
in a Kestrel-3 compatible way.
(If you're not targeting Linux or Raspberry Pi, it seems, you're SOL.)
Until then, I look forward to many productive hours of actual coding,
**in Forth.**
