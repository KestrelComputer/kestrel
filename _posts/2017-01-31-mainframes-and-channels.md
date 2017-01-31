---
layout: post
title:  "Kestrel-3 leans towards mainframes, I/O channels"
date:   2017-01-31 16:00:00
---

# Abstract

## The Mainframe

The iCE40HX8K FPGA from Lattice contains a little over 7100 look-up tables (LUTs).
The *current* Kestrel-3 design, targeting a Xilinx Spartan-3E device, consumes a little over 5500 LUTs.
This suggests to me that, all other things being equal,
the current Kestrel-3 design should similarly synthesize to approximately the same number of LUTs in the Lattice part.
This leaves somewhere around 1500 LUTs left over for other tasks.

However, as I cogitate over the Kestrel's icoBoard implementation,
the realities of the 8K's LUT limitations truly start to sink in.
First, everything *isn't* equal.
Some of those LUTs will be used as wires,
since the iCE40 architecture doesn't have the same routing abilities as the Spartan-3.
It has fewer block RAMs, which all but *mandates* running from external RAM.
Running internally on "debug RAM" is simply not an option with the icoBoard implementation.
Upgrades to the CPU microarchitecture will consume LUTs as well (it's impossible for me to predict how much though).
Pipelining will require new control logic to coordinate the different stages,
while privilege levels, TLBs, and MMU page table walkers will likely consume a fair chunk of that 1500 LUT slop.
I have no idea if a cache controller will even fit, so it's best to not count on it for now.
Finally, overall performance of the computer will almost certainly not meet my home-computer targets.
The iCE40 chip is fabricated in a different process than the Spartan-3 chip,
so it's likely the CPU will need to be clocked slower than 25MHz when fully synthesized,
at least until pipelining is put into place.

Obviously, these things collectively do not sit well with me.
I want reasonable performance (eventually), interactivity, and an ability to upgrade pieces without too much hard labor.
This calls for a design which is *extremely* modular.
As indicated in my previous blog update,
I've decided to tackle a design not too dissimilar from early, 1960s-1970s-era mainframes.
Thus, the icoBoard gamma will have sufficient resources synthesized to allow it to compute,
but not much else.

This gives several benefits:
- The evolution of the *processor complex* (to reuse IBM's mainframe terminology) can occur independently of the rest of the system.  I do not expect a lot of performance from the icoBoard Gamma, as indicated above, due to the iCE40HX8K's performance relative to the Spartan-series of FPGAs.  After I get a working system, however, I can reflash the board to support pipelining to improve my instruction throughput in complete isolation of any attached I/O devices.  If that's still not fast enough for my preferences, I could swap the icoBoard Gamma out for a board with a faster FPGA and SDRAM combination.  As long as the new board implements the same I/O channels, my I/O investment is preserved.  Things should "just work."  I hope.
- It *forces* me to move towards device independent I/O architectures sooner, rather than on an as-needed (and, often, backward incompatible) basis.  For instance, on the Nexys-2 or Altera DE-1 board, I can synthesize the computer with an on-board terminal capable of supporting the video resolutions and color depth of my choice.  Fitting something like a Gameduino to these platforms doesn't make much sense (unless you're interested in dual-head display configurations).  However, for something like a MyStorm BlackIce or icoBoard Gamma, using an Arduino/Gameduino combination, or a Raspberry Pi, or whatever makes *perfect* sense, since you basically have no other choice.  The system software will, somehow, have to be at least minimally compatible with these configurations.
- It eases documentation efforts.  The Kestrel-3 User's Guide is currently written assuming a home-computer configuration.  If I continue to keep the all-in-one home computer concept, I'd have to document not only how to program the computer and its operating system, but also how to generate graphics, audio, etc. myself.  Migrating to a mainframe approach allows me to document only the computer, its innate [channel I/O](https://en.wikipedia.org/wiki/Channel_I/O) capabilities, and the operating system.  External terminals can then be separately documented, and indeed, I can just re-use *existing* documentation more easily or by reference.
- If carefully architected, it meshes perfectly with the *everything is a device* I/O model that, e.g., Commodore and Atari 8-bit computers had back in the day, so programming will be more familiar.  Obviously, it will also mesh quite well with the *everything is a file* I/O model that Plan 9 and Unix variants support, which makes these OSes a natural fit for the Kestrel-3 going forward (once the CPU is enhanced to include an MMU and privilege levels).

It also gives some disadvantages:
- It's not what I promised originally, so followers of the project looking for a true home-computer experience will need to wait longer for me to deliver that concept design, or will get impatient and look elsewhere.  However, I value slower progress today than a perfect system tomorrow.
- Nearly all I/O becomes an exercise in message passing, which requires intelligent peripherals.  This isn't such a bad problem today, as you can get Arduino(-compatible) microcontrollers for cheap these days.  An ESP8266-based microcontroller can be acquired for $3 to $5 as I write this.
- Message-passing won't often impact aggregate performance with I/O devices; however, where instantaneous response is required, it can be an issue.  It's not suited for real-time I/O at all.

You might think, "You should use RS-232 for your interconnect," or perhaps, "SPI would be perfect for this."
I used to think this was the case too.
It's not.
I've decided to resurrect a dead technology instead: [IEEE-1355](https://en.wikipedia.org/wiki/IEEE_1355).
This is the protocol behind the currently niche [SpaceWire protocol](https://en.wikipedia.org/wiki/SpaceWire), used pretty much only in aerospace.
Why would I use this seemingly out-dated technology?

Honestly, I've no idea why this technology died.  It is far, far, *far* from out-dated.
As one article puts it, it offers ["ATM speed at RS-232 cost"](http://www.sciencedirect.com/science/article/pii/S0141933198000349).
My particular reasons for adopting this standard are:

1.  I need only four digital wires: two inputs, and two outputs.  This fits perfectly with a 6x1 PMOD connector, giving even the humble icoBoard gamma room for up to eight I/O channels at, potentially, 5 MB/s (peak) each.  I could *probably* improve this to 10MB/s peak with DDR techniques, but that's extra credit.  In comparison, the IBM System/360, which filled a room, could fit 16 5MB/s (peak) channels, over a *96-position* "bus and tag" cable set.
2.  No voltage level converters needed.  No current loops.  Only point-to-point, native voltage interconnects.  Easy to opto-isolate if better isolation required.  In fact, pretty trivial to couple to free-space optical interconnect, especially if using multi-color LEDs.
3.  Timing is largely automated.  Since the transmission clock can be recovered with a single XOR operation, there's no need to negotiate data transmission rates so precisely.  It's still good to negotiate maximum speeds while transmitting at a slower speed, though, for the benefit of bit-banged microcontrollers.  Thankfully, this need only happen *once* per link establishment, so that cost is trivially amortized, *and*, it only applies to that one hop.
4.  Implementing a UART would take comparable resources, but offer none of the above advantages.
5.  It's much easier to bit-bang in a microcontroller due to relaxed timing constraints.
6.  It's a point-to-point interconnect, but is packet switched, supporting infinite expansion through the use of switches in the I/O fabric.  The wire-level protocol is so simple, a Commodore PET or C64 can handle it effortlessly.
7.  If/when I decide to support RapidIO, there is already a mapping of [RapidIO over Spacewire](http://2011.spacewire-conference.org/proceedings/Presentations/Networks/Belvin.pdf).
8.  Flow control is done right, using a credit system with 8-byte granularity.  Thus, unlike ATM-based solutions, you don't need gobs of RAM to serve as buffers, and transmitters *assume* the receiver is busy until told otherwise.  Flow control is also hop-to-hop, not end-to-end, which makes transmission of data in noisy environments substantially more reliable.

Despite its advantages,
I will need to change some aspects of IEEE-1355 to better suit my needs.
IEEE-1355 is specified with the assumption that both sides of a connection use a dedicated controller,
which can maintain the link state in real-time to a 2 microsecond resolution.
That is, it can detect link errors and reset within two microseconds.
Similarly, if you pull a cable, it can detect the link having gone dead within that time as well.
This is infeasible with (especially slower/cheaper) microcontrollers.
For this reason, I need to relax this constraint.
The link reset protocol will likely remain the same, but
specific timings will be relaxed to allow, say, 10ms resolution times.
This is still fast enough for humans to perceive instantaneous response times, but
should be slow enough to support bit-banged implementations in slower microcontrollers.

## Terminals

To use a mainframe, you'll need a terminal.
I have two terminal ideas floating around in my head.

I first plan to rig an ESP8266-based microcontroller to serve as a bridge between IEEE-1355 and RS-232.
This would allow the mainframe to be operated from a host PC, Raspberry Pi, or similar device.
It would be a dumb peripheral,
in the sense that it would perform no interpretation of the data sent by either the Kestrel-3 or the user.
This represents the simplest possible I/O controller, and thus, easiest to get working.
In essence, it's a $3 replacement for a $15 USB/RS232 cable.
Don't worry; the economics of this baffles me too, but it seems to work.

I then happened upon the idea of using a Kestrel-2 as an 80x25 monochrome terminal with some bitmapped graphics abilities.
This would require a more sophisticated protocol on the Kestrel-3/Terminal Controller side of the connection,
since we are no longer dealing with just a dumb terminal.
It now is closer in scope to a VNC client.
As long as the protocol is compatible,
anyone can build a microcontroller-based terminal built around a Gameduino as well.
Software running on the Kestrel-3 should be nonethewiser,
resolution and color depth-sensitive code notwithstanding.

I've also toyed with the idea of using a line-mode and block-mode terminal (a la 3270 terminals) as well.
These user interfaces fascinate me, and I think they're quite under-appreciated.
Commodore used its line-oriented interface to great effect,
particularly with its machine-language monitors responding like magic to screen-editing operations.
Expect me to spend some time playing with these in the future.

## Storage

A mainframe is worthless without storage.
I continue to plan on using SD storage.
However, instead of the FPGA driving the SD card directly,
as I've done with the Kestrel-2 before,
I now plan on off-loading SD card management to a microcontroller.

The reason for this is simple:
abstract away the protocol differences between SD, SDSC, SDHC, SDXC, SD/UHS, etc. protocols.
And that's not even touching the MMC-derived protocols.

What I *don't* yet know is whether or not I intend on off-loading *filesystem* operations to the microcontroller.
It's awfully tempting, especially since I have several existing models I could follow:

1.  [Embrace and extend](https://en.wikipedia.org/wiki/Embrace,_extend_and_extinguish) Commodore DOS for use with the Kestrel.  Start out with something on par with a Commodore 1541 or 8050 disk controller DOS, and later fork it to support subdirectories, partitions, filenames longer than 16 characters, etc.  This has the benefit that it's a relatively simple and well-defined protocol for storage devices which also supports direct access to the underlying storage media, allowing new filesystems to be implemented.  Risks include a poor mapping from IEEE-488 semantics to IEEE-1355 semantics, and a potentially poor mapping of tracks and sectors to logical blocks.  Maximum volume size is 16MB, due to limitations of 256 tracks, 256 sectors, and 256 bytes per sector.

2.  Subset Commodore DOS.  Focus only on the direct access aspects, leaving the filesystem aspects for the Kestrel-3 to handle.  Same risks as above.  In effect, GEOS for Commodore 64 and 128 uses this approach, particularly with VLIR files.

3.  Support [9P](https://en.wikipedia.org/wiki/9P_%28protocol%29).  This is more modern than Commodore DOS, in that it natively supports subdirectories, supports multi-user environments, etc.  However, it does not support direct access to the storage media, so you're stuck using whatever filesystem the 9P driver on the controller implements.  9P was designed to operate over IP packets, and thus is a better fit than Commodore DOS for IEEE-1355 packet switching.  It is also markedly more complicated too.  Another risk with 9P is how to handle removable media.  Consider, at any time, the user could pull an SD card out of its slot, or accidentally break the SPI connection with the SD slot.  How does 9P handle this?

4.  Support IBM mainframe-style raw read, raw write, and seek cylinder commands.  This exposes the true nature of disk drives to the programmer.  However, disk drives are a dying breed these days.  We'd have to synthesize the concept of cylinders when using SD media, for example.

Right now, it seems like 9P is the best option to go with for general purpose storage.
I just wish I could find an implementation I can actually *understand.*
I might start out with something simple, like a subset of Commodore DOS,
and switch to 9P later on once I gain more experience.

## Conclusion

All the problems I've been having with the Kestrel-3 of late have gotten me down,
but in retrospect, it might be the best thing to happen to the computer design.
This level of modularity might actually make the computer more appealing to a wider free/open source hardware community.
Here's hoping things come along nicely.

