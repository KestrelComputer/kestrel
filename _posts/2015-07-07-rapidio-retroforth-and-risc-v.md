---
layout: post
title:  "RapidIO, RetroForth, and RISC-V Update"
date:   2015-07-07 18:41:00
---

On June 29 and 30, I attended the [Berkeley RISC-V Workshop](http://riscv.org/workshop-jun2015.html) at the International House.
This has been nothing short of a positive experience for me,
and will have a lasting impact on the future evolution of the Kestrel.

## RetroForth Ported to Kestrel-3

First, I'd like to discuss with you a quick-and-dirty experiment with the Kestrel's firmware.
About a week prior to the convention, I got the idea of porting the [Ngaro virtual machine](http://retroforth.org/docs/The_Ngaro_Virtual_Machine.html) to the Kestrel-3.
This permits the Kestrel to interpret a kind of word-code which, as it turns out, already has a dialect of Forth written for it.
You might have heard of it: [RetroForth](http://retroforth.org).
I'm pleased to say that, after spending about three days working on it, RetroForth 11.6 now runs on the Kestrel.
This implies also that RetroForth is the very first language environment to successfully run on the Kestrel.
I just need to finish two things before merging to master and updating the User's Guide.

First, I need to complete its division routine.
Right now, it successfully divides two unsigned integers.
In some rare cases, it'll even work with negative numbers.
However, in the general case, it's wrong when working with signed quantities.
I know how to fix this.
I just need to get off my duff and do it.

The other feature that's missing is, well, a filesystem.
In particular, RetroForth depends on a backing filesystem to load modules via its `needs` command.
The way Retro works, though, it ought to be easy to jury-rig a pseudo-filesystem that couples to block storage.
While it wouldn't be able to load support libraries by convenient name anymore,
it's conceivable that it could be made to load in a filesystem implementation,
which can then hook into Retro to restore its normal, documented behavior.

I observed that Retro _always_ looks in a single directory named `library/` and appends `.rx` for the source modules it wants to load.
This kind of predictability makes bolting on a filesystem-to-block-storage adapter rather easy.
For instance, to load a single block, I might tell it, `needs __b_12345` to load block 12345.
It'll attempt to open a file named `library/__b_12345.rx`, which I can parse out to fetch block 12345, and
then provide a kind of stand-in for a file handle to access its contents.
For a range of blocks, I might use, `needs __b_12345_67890` to load blocks between 12345 and 67890 inclusive.
These names simultaneously are compatible with most filesystems,
with Retro's module-naming syntax (so it'll properly track if it's already loaded a module),
and is even future compatible when I eventually do implement a proper filesystem.

I won't stop with RetroForth, though.
I still have plans to complete my own Forth environment for the firmware.
In fact, the division code I wrote to make Retro work can be easily reused with my own Forth so far.
A blog post on how it works will be forth-coming.
That Retro actually exists now, though, means that people can actually start playing with the computer _now_.
And that's just awesome in my book.

You can find my RetroForth work in the [`master` branch](https://github.com/KestrelComputer/kestrel).

## RISC-V Workshop Success

Having a working Ngaro VM was a nice bonus for an unrelated event: the 2nd RISC-V Workshop.

I gave a [poster](http://kestrelcomputer.github.io/kestrel/images/poster-full.pdf) presentation on June 29 covering the Kestrel, my mission, vision, and justification.
This presentation was surprisingly successful, considering that
everyone else in attendance were working either in the deep-embedded space or in the supercomputing realms.

Considering the expertise of everyone else there, you can imagine how deeply intimidated I felt.
I was _alone_ in presenting a home computing solution built around the RISC-V architecture.
This was the first time speaking in public where I was dry-mouthed, and 
actually shaking.
Yet, I've been told by many at the poster session that my 3-minute lightning talk would have (paraphrased) incited an ovation
were it not for the fact that it was requested that hold their applause for time consideration.

I can't help but feel vindicated by this quite unexpected response.
I've always known that the commercial incumbents in the space, even by those working on such offerings as the Raspberry Pi,
are largely ignoring the home computer opportunity.

## [RapidIO](http://rapidio.org)

Also at the convention, Rick O'connor gave a compelling presentation on RapidIO.
It's an open standard, and they mean *open.*
*Anyone* can [download the specs](http://www.rapidio.org/wp-content/uploads/2014/10/RapidIO-3.1-Specification.pdf).  *Anyone* can write Verilog implementing it.
And, as if that weren't enough, *anyone* can make unofficial bindings of RapidIO to technologies not considered in the official specs,
all because of how cleanly separated the various specifications are.
This last point is of particular interest to me: a small fry in a big ocean.

As you might already be aware, the Kestrel never concerned itself with commercial matters.
Choosing a technology for the Kestrel has never been about "what everyone else is doing,"
but rather about "what's the right choice."
This necessarily makes the Kestrel family a quixotic computing platform.
However, it's _my_ computing platform, and as such, I can understand it, document it, and support it over time.
It's stable, in a way that desktop standards simply cannot be.

Keeping this in mind, I'm seriously considering using RapidIO _for the sole, official I/O interconnect_ on the Kestrel family.
It's clearly scalable, from kilobits to terabits, even if the official specs won't cover that range.
This means that, while some ad hoc I/O will be necessary here and there (e.g., MMC/SD card support),
these would be considered only for pragmatic reasons.
Future, purpose-built I/O peripherals should use RapidIO protocols, and where possible, signalling.

RapidIO's specifications do not list speeds slower than 125MHz for parallel, and 1GHz for serial, interconnects.
Does this mean that RapidIO cannot be used on slower links?
If you want to use the RapidIO trademark, then that's exactly what it means (so far as I understand).
But, there's nothing preventing me from saying that a slower interconnect is "RapidIO-compatible".
I'm considering creating a binding for the RapidIO logical and common transport specifications to the SPI interconnect.
These would be very slow to relatively slow links:
at 25kHz, you'd deliver a peak throughput of 3KB/s, single-data-rate (about the same speed as Commodore's IEC bus).
At 25MHz, however, you'd pull off 3.15MB/s, just 75% that of the IBM XT's ISA bus.
You could perhaps abuse the SPI hardware to support double-data rate, and increase the clock rate to 50MHz, and get 12.5MB/s,
which is about _half the performance of Commodore-Amiga's Zorro-II bus._
Keep in mind, this is with only 5 I/O pins: MOSI, MISO, SS#, CLK, and SRQ#.
I'll probably dedicate a 6th signal just to facilitate hot-plug support.
That still leaves two more pins available for future expansion.
Maybe add an additional set of data pins to double the data rate yet again?

Before you complain that this would be impractically slow,
consider that SD/MMC cards communicate with a packet-like interface as well,
and are quite successfully used at a wide variety of data rates ranging from
kilobits to megabits per second.
So, if you're already familiar with how fast SD card access can be, you're
already familiar with how fast RapidIO would be over an SPI link.

To support proper SPI binding, though,
I'd need to add configuration registers that would tell the SPI master how fast to drive its clock.
Otherwise, you run the risk of a master over-clocking its slave's port, and that'd result in garbage I/O exchanges.
Thankfully, the way RapidIO's specifications are structured, I can do this.
To my knowledge, you simply can't do that with PCI or HyperTransport and retain compatibility.

The Digilent Nexys2 also has a 44-pin I/O connector along its edge.
That's big enough to support a pair of 16-bit, single-ended, DDR, parallel RapidIO links.
Now, single-ended buses aren't defined, so again, it'd be quixotic for pragmatic reasons.
However, with a 50MHz clock, it would allow (100 transfers per second * 2 bytes per transfer) = 200MB/s throughput each way,
which is _faster than Commodore-Amiga's Zorro-III bus_.

Oh, did I mention that the Nexys2 has an open socket in which you can place a 100MHz clock oscillator?
So, if you really wanted top speed, you can (in theory) double all those rates with some minor Verilog hackery.
That means, with a single SPI port, you could actually _match_ Zorro-II levels of performance (or beat it by a factor of two if you use a 2x data path),
while the parallel backplane connector would actually exceed PCI performance by 33%.

Not bad for a home-brew computer built with technology totally independent of any commercial interest, if I do say so myself.

I understand that RapidIO also includes support for hog-plugging (so I can, for example, properly detect when I insert or remove a device),
and of course, it's always been fully plug-and-play with a defined, if tedious and somewhat hard to understand, discovery and routing protocol.

Now, I haven't pulled the trigger on this decision just yet.
I still have much work to get done with the Kestrel's emulated environment yet.
Supporting RapidIO in software emulation seems like it'd be pretty difficult to get working right,
mainly due to the behavior of how switches work.
Still, the appeal of RapidIO is very strong,
particularly since it's a totally open specification, just as RISC-V itself is, and just as the Kestrel-3 itself will eventually be.
I'm salivating at the chance to give it a shot.
