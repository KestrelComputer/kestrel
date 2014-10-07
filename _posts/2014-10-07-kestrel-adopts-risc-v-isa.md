---
layout: post
title:  "Kestrel Adopts RISC-V Instruction Set Architecture"
date:   2014-10-07 15:00:00
---

The S16X4A-based Kestrel-2 limits the programmer to a 64KiB memory space, of which RAM populates only 48KiB.
With the relatively poor instruction density of the S16X4A processor, writing even simplistic operating software for the platform runs into memory barriers.
The need for a new processor architecture for the Kestrel quickly manifested.
The new processor offers a wider data and pointer width, allowing maximum use of on-board memory.

## Kestrel-2 Shows its Age After Four Years

The Kestrel-2 employs a 16-bit, minimal instruction set processor called S16X4A.
This processor may address no greater than 64KiB of memory without external paging hardware.
It packs four instructions into a 16-bit word (thus, each instruction takes 4 bits of memory),
which the processor executes sequentially after a fetch cycle.
It offers both word- and byte-sized fetches and stores,
a truly minimal set of arithmetic and logic operators,
and a basic set of control flow instructions.
You can read more about it by [downloading its datasheet](https://github.com/sam-falvo/kestrel/blob/master/cores/S16X4A/doc/datasheet.pdf).

When I first wrote the Verilog for this processor, I had intended it only to serve as a hardware debugging processor.
64KiB seemed plenty large enough for this task, and indeed, the existence of the MGIA, KIA, and the GPIA I/O adapters vindicate its success in this role.
I had always intended to adopt a larger processor once a basic foundation for the computer had bee implemented.

I'd invested so much into the S16X4A development tools that I lacked motivation to rework the microprocessor just yet.
Eventually, simple debugging scripts became components of larger, more sophsticated programs.
The simple display debugging tools I wrote as far back as July 2011 evolved, eventually, into the Milestone 2 presentation software that I now use for all Kestrel-related presentations.
The software I wrote to debug the KIA remains at the core of the STS keyboard driver.
It's difficult for even me to comprehend; but, the S16X4 family of processors survived as the compute engine of the Kestrel-2 for going on three years now.
The J1 processor preceeded the S16X4 for about a year before that.

The more sophisticated the software I build for the Kestrel, however, the more limitations I encounter.
Some limitations are the result of my impatience with the Kestrel-2 architecture itself.
Others are more intrinsic with the MISC concept itself.

From the user's perspective, and by design, the Kestrel-2 functions as a graphics terminal.
Since it lacks any kind of tile-based or indirectly-addressed video modes, the processor must work hard to keep the display in order when working with text.
Font tables, work buffers, and other aspects of working with display bitmaps and frame buffers all conspire to assert pressure on the Kestrel-2's constrained memory resources.

The S16X4 family lacks support for multiplication, leading to many look-up tables, each of which can consume a significant fraction of memory as well.

Last, but not least, the Kestrel-2 lacks any ROM in which to store any bootstrap or support libraries.

Consequently, between the needs of the graphics update routines, the resident operating system, and any resident application software,
the 32KiB available for programs dwindles into insignificance very fast.
Of course, if you didn't care about the content of the screen, you could also employ the 16KiB frame buffer memory for data and code storage as well.
But, then, you'd be running your software blind.

The S16X4(A) instruction set architecture doesn't help either.
Indeed, the S16X4A came into existence, in part, to help benefit the rather lackluster code density of the original S16X4 by introducing explicit subroutine support.
Code densities improved an average 15%, but it isn't enough in practice.

The fundamental problem with the S16X4A instruction set can be seen by examining most programs that exist for that processor.
On average, half of the code I've written contains a literal fetch every other instruction.
These literals hold two kinds of values: typically very small immediate constants, and pointers to buffers or structures.
Consider the simple case of incrementing one pointer by 80 bytes and another by 256 (which happens quite frequently when rendering 8-pixel wide text on a 640-pixel monochrome bitmap):

    P @ 80 + P !
    Q @ 256 + Q !

The memory layout for these instructions appears below:

    +---+---+---+---+
    | # | @ | # | + |
    +---+---+---+---+
    | addr of P     |
    +---+---+---+---+
    | constant 80   |
    +---+---+---+---+
    | # | ! | # | @ |
    +---+---+---+---+
    | addr of P     |
    +---+---+---+---+
    | addr of Q     |
    +---+---+---+---+
    | # | + | # | ! |
    +---+---+---+---+
    | constant 256  |
    +---+---+---+---+
    | addr of Q     |
    +---+---+---+---+

As you can see, incrementing P consumes a total of 4.5 words, or 9 bytes, as does incrementing Q.
Compare this to the equivalent code for any typical RISC architecture processor you might find on the market today:

    addi  p, p, 80
    addi  q, q, 256

Of course, this requires that P and Q are cached inside processor registers;
but, since this is the kind of code you'd find inside of a loop, you can confidently bet that they will be.
Given that highly probable assumption, then, we find that we can bump both our respective pointers in the same space needed by the S16X4A to bump only one pointer.

Now, to be fair, not all MISC software is as verbose.
On average, however, the 16-bit MISC software packs about as well as a typical 32-bit RISC architecture.
In the worst-case, the 16-bit S16X4A may pack as poorly as a 48-bit RISC architecture.
This makes sense when you just count the bits needed to achieve a task.

So why not just widen the processor to 32-bits to cover more memory?
This has the added benefit of packing more instructions in an instruction word, which can potentially save space too, right?
Well, if we did that, our software above would still not pack any better:

    +---+---+---+---+---+---+---+---+
    | # | @ | # | + | # | ! | # | @ |
    +---+---+---+---+---+---+---+---+
    | addr of P                     |
    +---+---+---+---+---+---+---+---+
    | constant 80                   |
    +---+---+---+---+---+---+---+---+
    | addr of P                     |
    +---+---+---+---+---+---+---+---+
    | addr of Q                     |
    +---+---+---+---+---+---+---+---+
    | # | + | # | ! | ///////////// |
    +---+---+---+---+---+---+---+---+
    | constant 256                  |
    +---+---+---+---+---+---+---+---+
    | addr of Q                     |
    +---+---+---+---+---+---+---+---+

We've saved one processor word of memory, but the words now pack twice as many bits.
Instead of 9 16-bit words, the software now consumes the equivalent of 15 16-bit words (half of one instruction word isn't used).
Now our 32-bit MISC has the same instruction density as a 64-bit RISC with 64-bit wide instructions.
If we sacrifice some slots to widen the opcodes to, say, 5- or 6-bits wide, we can introduce stack manipulation primitives which helps reduce the number of literals.
However, because we pack fewer opcodes per instruction word, we now need more instruction words to achieve the same task.
The result, it can be shown, will be just about a wash.

MISC is a great architecture for narrow word widths.
Fast, nimble, simple to implement and trivial to debug, I strongly recommend considering MISC for control-oriented applications.
I'm still considering using the S16X4A or a future variant for an I/O coprocessor for the the Kestrel.
However, based on their instruction density, I cannot recommend them, at least in the general case, for anything wider than 16 to 24 bits.

## Introducing Polaris

I ultimately ended up choosing a homebrew, 64-bit, [RISC-V architecture](http://riscv.org) processor design I call Polaris, named after my fiance's red-tailed hawk.
I chose this architecture for these reasons:

* Being RISC, it'll exhibit no worse code density than the MISC.
* It uses 32-bit instructions, which implies it'll actually be twice to four times more compact than a comparable 64-bit MISC.
* The RISC-V instruction set encourages modular instruction set extensions, including future support for a 16-bit instruction encoding.
* Existing evidence shows Head-And-Tail (HAT) encoding promises code densities comparable with CISC, and can be added at any time later on.
* The RISC-V architecture proves even simpler than any RISC design I've imagined myself.

The 64-bit architecture, clearly, grants significantly more memory capacity than 64KiB.
I will, for the first time in Kestrel's history, be able to access the Digilent Nexys2's psuedo-SDRAM (8MB or 16MB, depending on the source of the information you read),
on-board Flash ROM for storing a simple bootloader and a few frequently used libraries,
and far, far more.

The 64-bit RISC will also improve the runtime performance (assuming single-cycle fetches from memory).
Recall that incrementing a pointer in the MISC instruction set took six instructions to complete (which takes 8 cycles total), while the RISC takes only one.
Even if we build the RISC processor to touch 16-bit RAM, thus requiring two cycles per instruction fetch, we're still looking at a factor of four improvement in performance for that operation.
After looking at the code I've written so far, porting it to the RISC should give me close to a 2x performance boost, bus overheads included.

Finally, and perhaps at long last for many of my readers, Polaris will have a software emulator.
With the S16X4-based architecture, I am glued to the FPGA development board while hacking.
But, with my return to software emulation, it means I can hack Kestrel stuff while watching TV next to my future wife.
I haven't been able to do that since early 2011.
But, more importantly, it also means *you* get to play with the Kestrel, at least initially in a reduced, simpler form.
For example, I'll probably start with an MGIA-based display, for emulating the MGIA is relatively simple, but the CGIA will be substantially more difficult to emulate.
Yet, it's very simple to make a hardware CGIA implementation come up in "MGIA-mode."
Thus, there should be "upward" compatibility (from emulator to hardware) at the very least.

## What's Next?

Right now, I'm hacking on a new assembler for Polaris.
Although existing RISC-V assemblers exist, they're based on the GNU toolchain, which means a user cannot study the code nearly as well as a fresh implementation.
When it's finished, you can bet I'll blog about it here.
After the assembler, I'll need to make a linker for the object files it produces.
Once that's done, I can start working on the new Kestrel emulator.

Here's hoping for another three to four years of successful Kestrel hacking, and hope you stick around to see it!

