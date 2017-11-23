---
layout: post
title:  "Thawing Kestrels: Rebooting the Dream"
date:   2017-11-22 21:00:00
---

## Abstract

I think it's time to work on the Kestrel-3 again.
I've been employed long enough that I feel the urge to resume working on it.
But, some things will definitely need to change going forward.

## Kestrel-2DX: the Return of the Kestrel-2

I've been employed for some time now, and I'm feeling the urge to work on the Kestrel-3 again.
More or less secretly, I've been working on updating the Kestrel-2 design with my 64-bit RISC-V processor,
and have gotten a working computer again.
Hardware-wise, the computer is very nearly done; it only lacks support for interrupts and hardware timers.
Software-wise, I need only finish its Forth environment.
I'm currently in the process of writing its own implementation of Forth to use as its host operating system.
This new computer is called the **Kestrel-2DX**,
and because of that,
the Forth environment is called **DX-Forth**.

Like its predecessor, this computer remains limited in some ways.
From the user's perspective, this computer is more closely related to a Jupiter ACE than it is to an Atari ST or Amiga.
The processor can address no more than 64KB of FPGA block RAM (the Nexys2 only has 48KB of usable block RAM, however).
However, *unlike* its predecessor, the following new features exist:

* A true ROM exists starting at address `$00000`, providing some manner of hardware abstraction for loaded software.
* The 48KB of memory lies contiguous in the processor's address space, starting at address `$10000`.
* The MGIA can now address video memory from any of the three pages (it defaults to `$10000` at reset, though).
* I/O resources start at address `$20000`.

The goal of the 2DX is to help me in bringing up the Kestrel-3 later on.
In particular, having a computer with which I can *interactively* toggle bits
should prove quite helpful for all manner of things:

* It can be used to capture waveforms for logic analysis.
* It can be used to interactively develop software that drives large-capacity RAM chips.
* It can serve as a system debugging console.

## Kestrel-3

I'm no longer compromising on this computer's specs.
I'm done playing the race to the bottom.
Effective immediately, I'm setting what I think are imminently achievable goals for this computer design.
In particular:

* The Kestrel-3 **will not** support the Digilent Nexys-2 board or any of its progeny going forward.  This board is just too limited, and successor boards do not satisfy me in terms of capability acquired for the price paid for them.  Instead, I'm going to shoot for the Altera/Terasic DE-1 board.  I received this board via a donation about two years ago, for the specific purpose of supporting the Kestrel in some way.  I can't think of a better way than to debut the Kestrel-3 on it.
* 512KiB of SRAM at the very least.  This would take the place of on-chip block RAM, since the Altera part doesn't have anywhere near the amount of usable block RAM that Xilinx parts have.
* 4096 color palette.  The DE-1 board has a 12-bit resistor-DAC to drive its VGA display.
* 640x480 resolution with 16 colors visible.  I can probably pull off better specs than this; but this is what I'm willing to commit to.
* SD card to boot from.
* Will boot into a Forth interpreter, just like the 2DX will.  I should hopefully have enough room to fit a proper ANSI-compatible Forth.
* KCP53000 64-bit RISC-V processor at 25MHz (estimated 6 MIPS performance on average).  This is the processor driving the Kestrel-2DX.  I *may* change this out for a Rocket core instead, if I can manage it.  I've been trying to learn Chisel, and for whatever reason, "this time" I seem to be getting it.  If I find Rocket too hard to use, oh well; KCP53000 it is.  At least it'll run!
* Wishbone B.4 pipelined interconnect will replace the current Wishbone B.3 synchronous interconnect used in the 2DX.  This won't affect latency, but it should allow me to keep maximum clock speeds higher than they are in the 2DX, meaning it should be easier to hack on with confidence the design will actually converge and work as expected.  Best case, it'll also give larger MIPS rating too, but that's icing on the cake.

The board also has a 24-bit audio CODEC as well; but I don't really know much about audio.
I'm not a musician, so all I could really do is somehow support a direct DMA feed to audio output.
However, I'm *not* willing to commit to this, since it's not a mission critical component to an MVP of the computer.

## Chisel or Verilog?

Verilog is always a safe fall-back; but,
I'm going to make a concerted effort to apply Chisel to the job of building the Kestrel-3.
I have four motivations for this large design change:

* Improved productivity; Verilog works great, but it's a slog to have to constantly develop test fixtures with it.  Instead of using formal methods (which have **never** worked for me, reflecting how little I know about how to properly apply them), I employ test-driven development techniques instead.  Chisel looks to be far better than Verilog in supporting this approach to hardware design, in that it involves far less code for far greater overall coverage.  You can write an *exhaustive* test in an order of magnitude fewer lines of code than you can just focusing on edge cases in the corresponding Verilog code.
* The Rocket core is written in Chisel.  If I can manage to apply the Rocket core successfully, I get a significantly superior CPU; 64-bit, 4x performance, AMO instructions, multiply/divide, and here's perhaps the best part, a paging MMU that is powerful enough to support Linux, BSD, and Plan-9 operating systems.  KCP53000 isn't anywhere near this level of capability, and wouldn't be for at least another year if I worked on it full-time.
* Simulation can be done in C/C++, which is significantly faster than using `iverilog`.  This might be useful if I can only reproduce a hardware bug under certain circumstances triggered by buggy software,  for instance.  Instead of waiting weeks for emulation time, it might take hours or days instead.  (Yeah, it can take that long.)
* Compiles to Verilog anyway, so I can still use my current set of Verilog components if I get impatient.  :)

## Kits?

I've considered the possibility of also selling a Kestrel kit of some kind.
My vision consists of a backplane and a few plug-in cards,
a lot like the RC2014 computer concept.

I'm not sure the Kestrel-2DX would be of interest to anyone beyond myself,
considering how limited this computer design is.
However, I've definitely been considering it for the Kestrel-3.
It's hard to say what will happen so early in its development stage.

If I do this, I would need to redesign the Kestrel-3 to use Lattice iCE40HX4K or 8K parts
on a custom motherboard.
I've pondered this before, as some of my Hackaday.io readers would know.

Perhaps alternatively,
I could just sell pre-programmed parts based on the
icoBoard Gamma,
MyStorm BlackIce,
or even
Terasic DE-1 boards.

The latter, especially, might be terribly expensive on my part though;
DE1 boards can be purchased for $150,
I'd have to pay double shipping costs (to get the board, then to ship it out after programming), etc.
There's inventory costs (storage) associated, as well as handling returns (you know there'll be returns).
Anyway, these are just things I'm thinking about; **nothing has been decided on yet.**

## Conclusion

Let this article serve as notice that I'm officially rebooting the Kestrel Computer Project,
starting in 2018.
I see it as a necessity in the open-source hardware community,
even if it never attains any significant degree of popularity.
This is particularly relevant given the recent batch of articles and discoveries concerning
Intel's management engine, and how insecure it has been discovered to be.
I think the biggest advertisement for the Kestrel-3 is a simple one:
**no management engine.**

