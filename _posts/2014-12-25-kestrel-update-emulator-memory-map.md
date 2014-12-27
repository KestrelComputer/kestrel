---
layout: post
title:  "Kestrel Update: Emulators, Fake UARTs, and Memory Maps"
date:   2014-12-25 15:00:00
---

It's been several months since I offered any updates on the Kestrel-3 project.
I married the love of my life, got sick after the honeymoon, and then spent time taking care of development work for my employer.
Recently, however, I was able to invest some time into the Kestrel-3 project.
I'll discuss the current state of the Forth cross compiler, and some unexpected design problems I've run into.


### Introduction

Originally, I wanted to write an assembler for the RISC-V architecture processor at the center of the Kestrel-3.
I'd spent some time trying to get an assembler working, but it proved far more difficult than I'd care to admit.
Some of the problems I ran into include:

* I needed forward references.  How do I implement the two passes one needs to properly resolve forward references?  I literally could not find even one way to accomplish this goal that resembled sanity.

* The RISC-V instruction set specifies no fewer than *five* different ways to encode a displacement to a symbol.  The expression parser doesn't know the instruction format its result will be used with.  Given an expression with an as-yet undefined symbol, how do I keep track of this important piece of meta-information for later resolution?

* The RISC-V instruction set enforces position-independent coding.  This means some symbols are relative to a specific section of code.  Tracking this became hairy, and opened a can of worms semantically.  For example, if I have two labels, CodeLabel and DataLabel, each in their eponymous sections, and I say `foo EQU DataLabel-CodeLabel`, what does this actually mean?  Which section does `foo` bind to, if any?

I felt pretty boxed in by the interaction between these different problems.
Thus, I decided to throw it all away, and focus instead on a higher level language.
While I still have to deal with these issues at some level,
it turns out their relative scopes are greatly reduced.


### All New Forth Compiler

Having some kind of assembler or compiler for system-level programming is a prerequisite for writing the emulator.
The emulator needs input to process, and I can't be bothered to write binary files by hand anymore.
As a basic liveness test, I wanted to do something simple:
just write a bunch of A's to the screen.

So, with the power of wishful thinking,
I decided to write a program that I felt the compiler should be able to handle without much fuss.
The listing follows:

    \ This is a comment
    DEFER cold
    : .cold    65 $FFFF00 C! BIS ;
    ' .cold IS cold

If you're familiar with coding for the Kestrel-2, you're probably screaming with joy.
The first thing the reader will notice is how the comma doesn't appear anywhere in this listing.
For those unfamiliar with why this seems important, consider the following listing.
It's the same program as above, but written for the Kestrel-2's toolchain.

    \ This is a comment
    defer, cold
    :, .cold		65 #, $FFFF00 #, c!, again, ;,
    ' .cold >body @ is, cold
    s" bin.out" out

The reason I don't have all those commas everywhere is because the new Forth compiler now has its own lexer, parser, and internal vocabulary to dispatch from.
I no longer depend on a host Forth's lexer, parser, and vocabulary, which means I don't have to worry about namespace collisions anymore.
Of course, it's entirely possible to get a traditional ANS Forth to accept the former listing as input, provided your Forth supports wordlists (which most do).
However, it's more complicated than I'd like to deal with at the moment, particularly when it comes to handling numbers in the source listing.
You basically end up writing your own parser anyway.

Speaking of numbers, notice that no hashes are visible in the former source listing.
Since I rely on a custom parser, it knows how to handle numbers.
This will greatly ease writing of software, and reduce debugging time significantly.
I can't tell you how many hours I spent debugging Kestrel-2 listings all because I missed a `#,` somewhere.

The `again,` word has been replaced by `BIS`.
This is an [obscure adverb](https://encrypted.google.com/search?hl=en&q=define%3Abis) which means "to repeat",
and it seems an apropos [verbification](https://encrypted.google.com/search?hl=en&q=define%3Abis#hl=en&q=define:verbification) for what I'm using it for here.
For Forth environments which perform tail-call optimization, it's equivalent to `RECURSE EXIT`.
It also means I don't need to implement bizarre special-case logic to detect when `again` is used as part of a `begin` loop or not.
Less code, less to debug, easier to understand.

Another good reason for writing my own lexer, parser, and vocabulary structure is that the new compiler is written in C.
It was forced on me by MacOS X Yosemite, which for some reason, cannot compile GForth yet.
Since I'm impatient, I just decided to go ahead with C instead of waiting for GForth to be supported.
(Update: it has come to my attention that SwiftForth runs under Yosemite.
I might have to revisit the Forth-based compiler at a future date.)

Building and using the compiler is quite a simple matter if you have [`redo` (link)](https://github.com/apenwarr/redo) installed.
If I place the listing in a file `m1.fc`, here's how I build the software:

    redo
    bin/fc from m1.fc list

This will generate a binary file `bin.out`,
and will produce a simple program listing to the console for debugging purposes.
 
    kc5tja@deneb ~/git/kestrel/3 $ bin/fc from m1.fc list
    This is fc, the machine Forth compiler.
    Version 0.1.0
    
    	cold: ($00000000)
    6F 00 00 00 	JAL 	X0, 0 ($00000004)
    
    	.cold: ($00000004)
    23 30 17 00 	SD  	X1, X14, 0
    13 07 87 FF 	ADDI	X14, X14, -8
    23 30 01 01 	SD  	X16, X2, 0
    13 01 81 FF 	ADDI	X2, X2, -8
    13 08 10 04 	ADDI	X16, X0, 65
    23 30 01 01 	SD  	X16, X2, 0
    13 01 81 FF 	ADDI	X2, X2, -8
    03 B8 0F 00 	LD  	X16, X31, 0
    83 38 81 00 	LD  	X17, X2, 8
    23 80 08 01 	SB  	X16, X17, 0
    03 38 01 01 	LD  	X16, X2, 16
    13 01 01 01 	ADDI	X2, X2, 16
    6F F0 5F FD 	JAL 	X0, -44 ($0000000C)
    13 07 87 00 	ADDI	X14, X14, 8
    83 30 07 00 	LD  	X1, X14, 0
    67 80 00 00 	JALR	X0, X1, 0

Those familiar with the RISC-V architecture will correctly note that the generated code still isn't quite correct.
It doesn't establish the Forth runtime environment.
It also doesn't set up the global pointer register (X31).
This will require calculating the value of the global pointer before it's known concretely.
It's the same basic problem as what I encountered in the assembler: how to deal with forward data references.
One approach I've been thinking of was to alter the program like so:

    DEFER cold
    CREATE gpp  0 ,  ( reserve space for the assembler to put the GP value. )
        ( ... code goes here ... )
    : .cold	ENV0  warm-boot ;
    ' .code IS cold
    GPFIXUP gpp      ( causes compiler to store GP value in gpp. )

While effective, it nonetheless seems quite hacky to me.
It works because by the time `GPFIXUP` executes, the size of the code section will be known to the compiler.
Knowing that the read-only data section will immediately follow the code section lets the compiler easily compute its address.
I'm still looking for a better approach, though.
If I find one, it will no doubt inform a later attempt to write a true assembler.

# What's Next?

At the moment, the Forth compiler isn't sophisticated enough to compile much more than the input listing above.
Nonetheless, it'll soon be complete enough to move onto some new challenges.
In particular, we need an emulator to run the code.
I have some basic code written to emulate three things so far:
the 16MB of external Nexys2 RAM,
the 16KB of space to hold the bootstrap image, and,
the output register of a hypothetical UART which sends characters to the console for display.
Of course, the real Kestrel-3 will not have such a UART;
this is a debugging aide while I work out the kinks in the rest of the emulator environment.
It only lacks the CPU emulation.

You may be wondering about the $FFFF00 value in the source code.
This value is intended to be the byte address of the fake register which,
when written to, spits out a character to the emulator's stdout stream.
I picked that value because I wanted to exercise the compiler's ability to handle
small numbers and fairly large numbers (values outside -2048 <= x < 2048),
as they're encoded differently in the final output.

But, this raises an interesting question: just where *should* I put this register?

Answering this question is more complex than you'd think.

# Where to Put the Fake UART?

This is the one time when thinking about the future has a *big* pay-off.
If I focused exclusively on the Digilent Nexys2 board,
I can legitimately get away with a 32MB physical memory map.
The low 16MB can be broken up into I/O and ROM sections,
while the upper 16MB can be occupied by the Micron RAM chip.
But, what if someone wants to port the Kestrel to a different FPGA development board?
Or, what if they want to build a completely custom board?
I could be a dick and appeal to [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it),
but this directly contradicts my strong sense of developer experience.
YAGNI applies nicely for software because of how easily software can be changed.
Change the hardware in some way, though,
and you'll need to recompile no less than *all* the system software that sits on it,
including its bootstrap ROM.
The Kestrel should be a joy to hack, not a burden.

I need a memory map that is easy to emulate as well as easy to implement in Verilog.
I don't want to have to change these two sources every time I need to alter the memory map for some reason.

How can the memory map be influenced in the future?

Future peripheral expansion strongly influences how I lay out memory.
I can envision a day when the Kestrel no longer resides on the Digilent Nexys2 board,
and when a home-made circuit board holds the computer's logic.
I can see myself adding peripherals to the Kestrel,
perhaps a few based on more FPGAs, and others around some GreenArrays GA144 chips,
after having fabricated this board.
I can also see myself purchasing more FPGA boards and
hooking them up to a common backplane for parallel computing.

To be able to push data around the system as quickly as possible,
I envision a backplane system of expansion slots.
Two methods of addressing peripherals exist.

One of the simplest possible approaches to make this work is to assign each slot a region of address space.
To access another slot's peripherals and/or memory,
form an address where some of the high bits refer to the slot by name.
NuBus took this approach, and is called *geographical addressing*.
It has three advantages:

* it requires the least amount of hardware and software to get working,

* automatic configuration largely comes for free, and,

* it's fully compatible with building "dumb" peripheral hardware (e.g., devices without built-in processing capability or so-called "declaration" ROMs to auto-config with).  However, the cost is you must manually take steps to bind a driver to the peripheral if you go this route.  But, it at least *can* be done.

The only significant costs seem to be internal fragmentation of the address space.
Cards are assigned massive amounts of address space
(in my case, 1,073,741,824 gigabytes, explained below; in the case of NuBus, 16MB.);
but, often, only a small amount of that space will actually be used.
For dumb peripherals, as few as 4 bytes might be used for various control registers.
For intelligent devices, you could have a boot ROM, some RAM, and a separate I/O region all packed inside,
and still have the overwhelming amount of space wasted.

Another approach is to keep all peripherals in a quiescent state until configured by a master.
The master reads a configuration record for each peripheral,
and allocates a region of memory space for the peripheral to exist in.
This is the most flexible, but requires more hardware to make it work.
It also requires explicit software support in whatever OS or bootstrap software you have.
For example, booting from a "hardcard"
(controller and harddrive on a single expansion card)
will be impossible without first enumerating and configuring the hardcard.

Regardless of the approach actually taken,
the semantics of the emulator should match as closely as possible with the final hardware.
This minimizes the amount of effort I have to invest in coding and debugging.
Since geographical addressing requires the least amount of hardware to get a working system,
and since dynamically configured hardware can always be placed in an expansion space just like geographically addressed hardware,
it seems natural for me to design my address space with geographical addressing as a foundation.
If needs warrant, I can always update the system to a dynamically managed expansion space later.

Here's what I've come up with for a memory layout.
See the figure below.

    6666 5555 5555554444444444333333333322222222221111111111
    3210 9876 54321098765432109876543210987654321098765432109876543210
    ==== ==== ========================================================
    |    |    |
    |    |    +-- 67,108,864 GIGABYTES of space belonging to a device.
    |    |
    |    +------- Device Select on the addressed card
    |
    +------------ Card Select

Since microprocessors boot up with their high bits either set to all zeros or all ones,
"cards" 0 and F are reserved expressly to represent "the current card,"
as appropriate for that card.
Thus, from the microprocessor's perspective on any given card,
card-resident peripherals respond to at least two address ranges:
$0xxxxxxxxxxxxxxx and/or $Fxxxxxxxxxxxxxxx,
and if plugged into the backplane in slot N, $Nxxxxxxxxxxxxxxx.
This allows the processor on the card to bootstrap without having to know where its bootstrap image exists in the current address space.
More concretely, this allows the Kestrel-3 to boot without knowing if it's a bus controller or not
(that function is decided by its precise implementation, but should be mostly transparent to the software),
and without any regard to which slot (if any!) it's plugged into.

In the case of the Kestrel-3, I take another set of four address bits to select one of 16 devices in the computer.
Since the computer resets with its program counter set to 8192 ($0000000000002000),
it makes sense to reserve device 0 as the bootstrap ROM.

The remaining devices can pretty much be assigned arbitrarily.
To get the screenful of "A"s working, though,
I need at least access to external RAM,
and access to the fake UART I discussed above.
Resources which both the hardware and emulator share will be assigned device numbers in increasing order,
while emulator-only resources will be assigned device numbers in decreasing order.

Thus, I've arrived at the following address map for the Kestrel-3 so far:

    Bootstrap ROM	0000000000000000-0000000000003FFF
    External RAM	0100000000000000-0100000000FFFFFF
    (future I/O)	0200000000000000-0EFFFFFFFFFFFFFF
    Debugging UART	0F00000000000000-0F0000000000000F
    (backplane)		1000000000000000-FFFFFFFFFFFFFFFF

Eventually, devices like the KIA (PS/2 keyboard interface adapter),
CGIA (Configurable Graphics Interface Adapter),
and GPIA-II (64-bit general purpose I/O adapter) will find homes in the
space reserved for future I/O.

You'll notice an enormous amount of space wasted for each device.
Dedicating over *67 million gigabytes* of space to a 4-byte I/O device like the KIA seems overkill.
However, remember that my aim is hardware and software emulation simplicity.
Device selection can occur in software using a simple table-lookup,
and in the FPGA using a 1-of-16 decoder.
And, really, *sixty seven million gigabytes* is hardly something to be concerned about
when available RAM resources are themselves incapable of filling even a significant fraction of that space.
And, besides, if I ever do need petabytes of memory for some bizarre reason,
I can always add RAM to the expansion backplane, giving me access to over 1.3x10^10 gigabytes more RAM.
I'm not hurting for address space economy.

If I may now digress for a paragraph, this expansion strategy implies that the backplane can never have more than 14 slots.
From an electrical engineering perspective, this is hardly a limitation.
It takes a *lot* of electrical engineering effort to have more than even six slots in a backplane and retain valuable engineering properties at the same time.
This is why most computers with a backplane rarely exceed six slots on the motherboard.
Most industrial environments which need greater than six slots use a dedicated expansion chassis.
In fact, except for industrial applications, computers these days rely on point-to-point, packet-switched links.
The backplane as we've come to understand it simply doesn't exist anymore.

I'll punt on the problem of how to get multiple Kestrel-3s to recognize and cooperate with each other on the backplane
until a later date; namely, when this actually becomes an issue for me.
(I have to be honest with myself -- it never will.  But for you?  Who knows?  I'd love to be kept in the loop.)
For now, I just want to make sure I have a memory mapping strategy that accomodates a diverse set of expansion strategies while minimizing rework in the future.
I think I've done a pretty good job of arriving at a workable solution.

