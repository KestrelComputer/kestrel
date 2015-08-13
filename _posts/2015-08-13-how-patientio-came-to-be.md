---
layout: post
title:  "How PatientIO Came To Be"
author: "Samuel A. Falvo II <kc5tja@arrl.net>"
date: 2015-08-13 14:00:00
---

In this article, I attempt to answer the question,
"Why PatientIO?"  Why build it on top of RapidIO?
I hope to answer those two seemingly simple questions.

This post has been waiting to be published
for about a month now.
I'm sick of editing it and re-editing it,
so here it is, in its entirety.

You may recall from
[several posts ago,]({{site.baseurl}}/2015/07/27/towards-patientio/)
I mentioned that
I gave a tech talk on
the Kestrel-3's I/O architecture, PatientIO.
That talk was a 30-minute distillation
of the subject matter contain in this article.
So if that talk left you with some questions,
hopefully this article will help clarify things.

## Introduction

At some point,
someone will want to use the Kestrel-3
with at least one peripheral attachment.
It could be a printer,
an external harddrive,
a method of controlling LEDs for long-distance optical communications,
what have you.
In my own use-case,
I need to attach a 100Mbps network interface,
as the Digilent Nexys2 doesn't have an Ethernet port of its own.

Unfortunately,
users cannot depend upon commercial vendors to provide peripherals cheaply,
if at all.
We could use industry-standard interfaces such as USB or PCI-E,
but these interconnects often require 
(from my point of view)
deeply specialized,
and therefore expensive,
manufacturing or tooling just to play.
Even with relatively open standards like the SD/MMC protocol,
anyone can tell you that commercial vendors are notorious for not following openly available standards.
If you want to market your own products,
you often need to pay large sums of money
on a regular schedule
to acquire and maintain a vendor ID and similar tokens needed
to support automatic configuration and device enumeration.
Kestrel-3s and compatible computers aren't exactly a hot seller (yet?),
so this would be a losing proposition for anyone interested
in supporting the Kestrel-3.
If someone does manage to commercialize it, I hold no illusions to its future popularity.
I expect few in the industry will be interested,
considering the Kestrel-3 a toy.
This guarantees unsustainably low sales volumes for expansion peripherals.
There's also the built-in conflict of interests with commercial vendors,
namely that a completely open standards-based I/O stack
is at odds with a commercial entity's desire for strong intellectual property
in a strongly litigious society.
These all conspire to make the Kestrel-3 a niche product for some time to come, possibly forever.
Kestrel-3 entheusiasts must come to terms with this fact.

Thankfully, it's not all doom and gloom.
If we _truly_ evaluate our interconnect needs,
we can find surprisingly capable solutions right under our noses.
Affordable microcontrollers with high performance, inexpensive FPGAs,
and open standards built on top of SPI
(serial peripheral interconnect)
gives homebrewers the ability
to create custom peripherals
at usable levels of performance and
at acceptable price points.
By keeping the cost of peripheral design to a minimum,
without sacrificing conveniences we've come to live with,
I hope the Kestrel-3 community
will grow to support itself
to the greatest extent open-source hardware economics will allow.

But, first, we need open standards that the community can trivially comply with,
without the need to be a member of a potentially costly
centralized organization to certify compatibility.
This means the protocols need to be extremely simple,
reference implementations freely available,
and documentation on them written clearly.

## Background

The first generation of Kestrel-3 hardware will sit on a Digilent Nexys2 board.
I feel this board, to this day, still sits at an ideal price/performance point,
even though other FPGA boards have more capable I/O facilities.
The Nexys2 is somewhat I/O limited for my needs as a self-standing,
general purpose computer motherboard:
only four "full-height" (12-pin) "Pmod" ports for peripheral expansion,
and one 100-pin HiRose connector.

Each Pmod port offers 8 digital I/O pins, two grounds, and two 3.3V supply pins.
This doesn't sound like much,
but it's enough to implement a single full-featured SPI link,
two minimal SPI links, one minimal SPI and two I2C links, or, up to four I2C links.

Regrettably, I will not discuss I2C further here.
It's a wonderfully elegant interconnect;
but, it relies upon a closed protocol without any room for growth by home-brew hackers.
Besides,
the limited rates of speed it performs at
will be a bottleneck for high-performance devices
later on.

This leaves only variants of SPI as an expansion mechanism for the Kestrel.
With a suitably high frequency clock on an SPI interconnect,
Pmod ports can be surprisingly powerful, yet inexpensive, to use.

The Hirose connector is obviously intended for very high-performance,
perhaps even backplane,
applications.
With a compatible backplane, this would make the Nexys2 an ideal CPU
or dedicated I/O
card.
The Hirose connector is capable of delivering up to 400 MB/s throughput
simply by scaling up the techniques I'll use with the Pmod ports.
I'll explain more about this where it's relevant below.

### Basic SPI

If you look at most reference materials on SPI,
you'll see they give only a hand-wavy description of how it works.
Unfortunately, that's because that's all Motorola Semiconductor defined
when it first introduced the interface for its microcontrollers.
At first, people used it as a simple, low-cost means
of expanding parallel inputs and outputs using, e.g., 74595 chips.
They also used it as a faster-than-RS232 means of talking to other Motorola microcontrollers.
As time went on, though,
vendors manufactured products with more sophisticated state machines
and more complex command sets.
Since its introduction,
a myriad of different peripherals came into existance by different vendors,
seemingly all of which utilizing at least one of eight different,
and often incompatible,
"modes" of use.
Three variables affect the mode of operating an SPI link:
you can start with the clock idling high, or idling low when you select a slave;
you can sample data on the rising or falling edge of the clock,
implying you shift data on the opposite edge;
and, finally, you can shift data out starting with the most- or least-significant bit.
Strictly speaking,
SPI isn't even guaranteed to be octet-aligned,
although very nearly all products designed for SPI are for pragmatic reasons.

The simplest possible SPI interface is simple enough
to be implemented entirely in discrete TTL logic.
A master device writes a byte into a shift register.
It clocks this shift register eight times,
since a byte contains eight bits.
As each bit shifts out on the MOSI signal,
a new bit from the slave device shifts in on the MISO signal.
Thus, after eight clock cycles, the two bytes have exchanged,
and the master can now read the last value written by the slave.
Concurrently, the slave might react to the byte issued by the master.

                                MOSI
    +---------------------------------->----------------------------+
    |                                                               |
    |           master                       slave                  |
    |    +------------------+       MISO    +------------------+    |
    +----|  shift register  |<--------------|  shift register  |<---+
         +------------------+               +------------------+
                ^       ^                           ^       ^
                |       |       CLK                 |       |
    CLK >---------------*-----------------------------------+
                |                                   |
    DATA BUS <--+                                   +---> DATA BUS
    (master)                                                (slave)

To grant a master
the ability to work with multiple SPI devices on the same set of MOSI, MISO, and CLK pins,
most SPI devices also have a "slave select" signal as well.

As a result of this ultra-simple hardware interface,
all the complexity of coordinating the master and slave lies in the software that drives the hardware.
For most embedded applications, each attached component has its own SPI-aware driver.
Therefore, the driver is inherently aware of the physical protocol,
how fast data can be transferred, etc.

### Looking Forward: Exchanging more than one bit at a time.

This section is a speculative, back-of-the-envelop discussion about addressing future I/O needs.

Basic SPI's performance is surprisingly good.
The rules for determining overall performance is simple:
take your clock rate, and divide it by eight, and
that's how many bytes per second you can expect on the link
in any given direction.
Both directions are working concurrently,
so depending on the specific protocol,
you could even double this figure.

For example,
if we wanted to transmit a 256-color VGA (640x480) display
at 60fps over an SPI link
without compression,
we would need no less than a
(640 &times; 480) pixels/frame &times; 60 frames/sec &times; 8 bits/pixel =
147.5 Mb/s link.
For basic SPI, this implies a 147.5MHz clock.
If we wanted to do this at the nominal VGA dot-clock rate,
we'd need to increase this frequency to 201.6MHz.
Given today's technology, neither is an impossible rate of speed.

However, for the casual homebrewer, 
certainly those of my skill level,
147.5MHz signals fall well outside the realm of practicality.
You need to know how to engineer VHF/UHF RF circuitry for this to work properly, at a minimum.
This is a good skill to have in general; however, I don't want to require it, because
it precludes the ability to just cobble something together to see if it works.
As well, you'll want to take steps to ensure this signal doesn't radiate.
It's on the tail end of the amateur radio 2m band, and believe me, someone will notice.
The problem is, shielding cables at these frequencies is problematic for anything except a coaxial cable.
That's why all the commercial vendors are going to LVDS or something like it.

It's much easier to control radio emissions when the frequencies involved are much lower.
It makes a lot more sense, from the perspective of homebrewing,
to sacrifice some serial purism, and use some parallel interconnects.

Freescale, the direct descendent of SPI's inventor Motorola Semiconductor,
combines double-data-rate (DDR) with parallel buses.
A so-called 10MHz, DDR, x4 "Serial Quad Interconnect" (SQI) port can transfer up to 10MB every second,
while requiring no more than 6 I/O pins (4 for bi-directional I/O, clock, and slave select) and
only modest circuit layout techniques.
Compare against a stock Commodore-Amiga 2000,
which uses the 100-pin Zorro-II backplane bus
to deliver a meager 5.3MB/s at 7MHz.
To compete with this humble 6-pin interface,
you'd need to over-clock the Zorro-II bus in excess of 14MHz!
Or, you could upgrade to an Amiga 3000 and target the Zorro-III bus instead.

Since SPI uses unidirectional links,
we can of course drive the clock much faster than we could on a bidirectional bus.
25MHz is well within the specs of most SPI peripherals, and
50MHz to 100MHz seems to be closer to its practical limit without more exotic PCB routing techniques.
Since both the clock and the data pins connect only to shift registers,
signal loading has a greatly reduced effect on SPI performance.
Indeed, the _length of a cable_ has significantly more impact on performance.
This is why SPI and its derivatives
can compete so well
against traditional, so-called multi-drop, bus systems.

What would it take to support a 100 Mbps Ethernet NIC at line rate?
If we assume absolutely perfect communications efficiency,
clearly we'd need a 100 Mbps SPI link or its equivalent.
This means a 4-wide SPI link should do the job while requiring only a 25MHz clock.
(100 Mb/sec &times; 1 cycle/4 bits = 25MHz)
We can drop the clocking requirements down to 12.5MHz if we want to support DDR on the link.

Personally, I have no immediate plans to support SQI
as Freescale defines it.
Supporting the bidirectional I/O pins is not as easy as just using dedicated inputs or outputs
on an FPGA circuit.
Instead, I will follow in the spirit of SPI and continue to exchange symbols every clock cycle.
This means multiple MISO and multiple MOSI pins.
Such a x4-wide SPI variant will require only 10 pins.

    Scaling SPI Up (x4)
    +-----+
    | SPI |----> M3
    |     |----> M2
    |     |----> M1
    |     |----> M0
    |     |
    |     |<---- S3
    |     |<---- S2
    |     |<---- S1
    |     |<---- S0
    |     |
    |     |----> CLK
    |     |----> SS
    +-----+

While slightly more expensive than SQI
since it'd require more printed circuit board space,
it's not a deal breaker.
Additionally, unlike SQI,
it allows 4 bits to be *exchanged* every clock cycle.
If we totally max this link out at 100MHz SDR and DDR, respectively,
we can reasonably expect close to 50 MB/s and 100 MB/s *each* direction.
This 10-pin link is capable of competing with IBM's MicroChannel Architecture and is
just starting to threaten Amiga's Zorro-III bus.

The Nexys2 board's HiRose adapter happens to have 43 usable I/O pins (the rest are grounds).
That means we can bond *four* of these links together on that connector.
This scales linearly: if we drive each SPIx4 link at 100MHz, then
our aggregate performance can reach up to 200 MB/s to 400 MB/s *each direction*.
We've left Amiga's Zorro-III performance so far behind that
we're now playing in a low-end mainframe's sandbox.

Memory bandwidth permitting, of course.
For this reason,
these capabilities will be largely unused with the first generations of Kestrel-3.
For starters, the first-generation hardware will only have a 25 MB/s path to RAM.
A single SPIx4 running at 50MHz SDR will be sufficient to peg the utilization meter of RAM to 100%.
Even if we use the on-board RAM in SDRAM mode, we're still looking at, at most, 160 MB/s.
It's hard to justify implementing more than, say,
two SPIx4 SDR lanes on the expansion connector with this kind of bottleneck.

I'll almost certainly have my own custom motherboard before I have a need for higher I/O bandwidth.
Due to their ubiquity and relatively low cost,
I'll probably use EuroCard (16, 32, 48, or 96-pin DIN-41612) connectors.
Therefore,
I see no benefit to specifying how to use the Hirose connector at this time.


## Expansion Requirements Review

To be successful, then,
I think the Kestrel-3's I/O infrastructure should meet the following requirements:

* Start with basic SPI as our foundation, and build on top of that.
* Cost should scale with bandwidth requirements.
* Leverage existing concepts.
* Support single-beat and burst transfers.
* Trivially simple auto-config.
* Support for hot- and warm-plugging.
* Support DMA.
* Support general purpose messaging.
* Support interrupts.
* Supports software or hardware implementations.
* Switched fabric.

Let me elaborate on each of these and why I think they're important to have.

### Start with basic SPI as our foundation, and build on top of that.

As I discussed above, a 100MHz, SDR SPI port can be made to haul traffic at 12.5 MB/s each way,
and a DDR interface at up to 25 MB/s each way.
Considering how cheaply a homebrewer can fab these links, these are not small numbers.
Consider just low long 4 MB/s to 10 MB/s expansion buses carried us along in the personal computer industry!

Therefore, I feel confident that we can, and should, start out with a small SPI interface,
and scale up as needs require.
A single-channel, 48kHz, 16-bit audio codec with 20% protocol overhead
could get by with 960kb/s.
A contemporary hard-drive, obviously, will need more
if we want to transfer data at its maximum rate of speed.
It's nice knowing, though, that for as long as we consider connector space cheap, we can just "throw lanes" at the problem without too much thought.

Confident that we can start small
(tens of kilobits per second over a bit-banged, single-lane, SDR SPI link)
and expand to industrial-grade, backplane throughputs
by following a simple scaling algorithm,
we turn our attention to the service provided by SPI itself.

SPI provides a simple,
[transparent](https://en.wikipedia.org/wiki/Transparency_(telecommunication))
byte pipe from software's perspective.
This means that, except for the slave select signal on a single-lane interconnect,
SPI doesn't preserve distinct message boundaries
in *either* direction.
SD/MMC protocols, for example,
requires you to send `$FF` bytes when you're not sending anything interesting,
since it uses the falling edge of MOSI as a start-bit for command frames and response bytes.

Therefore, since it's a fully transparent byte-pipe,
we'll need to adapt some kind of framing protocol to facilitate transactions on the link.
This protocol should use as little bandwidth as possible.

There's another problem with pure SPI as well.
How does a slave asynchronously tell the master that it has a packet to send?
Remember the master is in charge of the `CLK` *and* the `SS` signal(s)!
This is easily addressed by providing another signal, `SRQ`.
When the slave has *at least one byte left* to send to the master, it asserts `SRQ`.
When it's buffers are empty, it negates `SRQ`.
In this way, the master can discover,
without periodic polling if `SRQ` is tied to a CPU interrupt,
when the slave has data pending for the master.

### Cost should scale with bandwidth requirements.

Low-speed peripherals should be cheap to make.
We _expect_ high-speed peripherals and backplanes to cost
(potentially significantly)
more.

The protocol should be simple enough to implement in hardware if performance demands it,
or easily emulated in (e.g., microcontroller) software if not.
This goes for both the Kestrel and any peripherals we might want to attach to it.
The cheapest, lowest-cost, lowest-performing implementation
would be a bit-banged interface on the Kestrel,
and a bit-banged interface on one or more peripherals.
I envision the simplest possible attached device will consist of a Pmod connector with
six wires attached to an Atmel ATmega328P or a Texas Instruments MSP430 microcontroller.
A 16-inch long cable represents roughly 2ns of transit delay, so at these speeds,
cable length is not important.
This should cost no more than $5 to $10 to produce a useful peripheral
with responsibly sourced components,
and should yield estimated throughputs up to
(12.5MHz &times; 1 bit/3 cycles &times; 1/10 looping overhead)=416 Kb/s
on first-generation Kestrel hardware.
Plenty fast enough to drive
a keyboard,
a mouse,
a floppy disk drive,
a pen plotter,
most printers for average printing tasks,
and just to establish some scale for its capabilities,
is just starting to scrape the ceiling 
for a mono, 8-bit, 44.1kHz audio channel.

The highest performing implementation would involve
CPU-transparent I/O bridges
in FPGA hardware on both the Kestrel and the attached device.
These bridges would obviously have direct memory access, and
would convert normal bus transactions into packets conveyed over the SPI link.
This configuration facilitates the maximum throughput possible,
since all hardware involvement happens independently of either processor.
We realize the full benefits of supporting DMA and interrupts via this implementation.
Clearly, the larger printed circuit board space needed to accomodate the wider data paths,
bigger connectors, FPGAs, and
other design considerations
will drive the cost of the peripheral up considerably.
Nonetheless,
I claim it'll still be cheaper than the super-miniaturized and more mainstream I/O chipsets of today.

### Leverage concepts.

A low bandwidth device should share most, if not all, of the protocol concepts as a high-bandwidth device.
Ideally, the same bit-stream representation should be used for 400 B/s serial and 400 MB/s parallel links.
Layers of the protocol should be clearly delineated, and understood in isolation of other layers.
The core software running on the peripheral
should not have to substantially change if you speed up or slow down the interconnect.
Auto-configuration should "just work" with a bit-banged, single-lane, SDR SPI link,
or a hardware bridged, x16, DDR interconnect.

### Single-beat and burst transfers.

To the greatest extent that the laws of physics allows,
the I/O protocol should be equally adept at transferring one byte as it is one megabyte.
Personally, I intend on attaching a wide variety of devices to my Kestrel over time, including
mass storage media,
network adapters,
keyboard and mouse,
DACs and ADCs,
maybe a touch-screen interface, and
perhaps the occasional set of general purpose I/O pins.
Broadly speaking, these devices can be classified into
"block addressible,"
"block streaming,",
"character streaming," and
"character addressible" devices,
respectively.
The interface needs to work relatively well
with all four classes of hardware,
preferably without any kind of mode bits involved.
Obviously, there will be compromises.
It's OK to prefer one over the other;
for example, most protocols are rightly optimized for block transfer of data.
My concern here is that the four kinds of accesses should not complect the protocol unnecessarily.

### Trivially simple auto-config.

Obviously this will require support from the system software running on the Kestrel-3;
however, there's no reason
why the peripheral auto-config protocol
should make life difficult for either the peripheral or the OS.

The Commodore-Amiga demonstrated that one can achieve automatic discovery and configuration of hardware
with only a modest investment in hardware,
and virtually no system software to speak of.
You didn't need the specialized chipsets that PCI, NuBUS, or TURBOchannel needed.
You didn't need to pay on the order of $10,000 to a special interest group
for a peripheral developer or vendor ID.
(You did still need to register with Commodore, though.)
The Kickstart ROM would enumerate all AutoConfig devices,
and using nothing more sophisticated than a doubly-linked list
serving as a database of which devices sat at which addresses in the CPU's memory space.
It was simplicity itself.

Any expansion mechanism for the Kestrel-3 should, despite the drive for low cost, support comparable features.
While manual device driver configuration should always be an option for the advanced user,
I consider it poor form
to *depend* upon manual device driver configuration
in the general case, at least long-term.
Not only can we match the Commodore-Amiga's I/O expansion features and performance,
we have the technology to exceed them, and for at most only a few dollars.

### Support for hot- and warm-plugging.

Since AmigaDOS (Amiga's port of TriPOS, a component of AmigaOS)
supported the notion that _all_ devices were removable, including fixed disks,
it proved relatively easy to tell AmigaOS that a certain device was about to go off-line for maintenance.
It would flush buffers, then prevent future access to the device.
(If an application did request services from an offline disk device,
the famous "Please insert volume whatever in any drive" dialog would typically appear.)
This happened, for example, if you ejected a floppy disk, ZipDisk, or CD-ROM.
It also happens when you format a fixed disk,
or attempt a filesystem check on a live system.

In theory, although never actually used in practice,
this facility can even let you maintain or administer the peripheral
while the Amiga itself remained powered on.
For example, if I told my SupraDrive 120XP to park the heads,
it would put all devices represented by the drive into a blocked state, park the heads,
then spin down the spindle.
I've never been brave enough to try this; but,
I could probably replace the drive with the Amiga 500 _hot_,
then bring the drive back into service by double-clicking the program to unpark the drive.
Regretably, this was virtually never actually used in practice,
as most vendors did not control power to their peripherals.
Also, the Amiga's target market segment
really didn't lead anyone to consider the possibility
of using Amigas in a data center environment.
So, as with other computers, 
swapping a harddrive necessitated power-cycling the Amiga.

Now, apply this same concept to Kestrel peripherals at the interconnect level.
The protocol should allow,
preferably encourage,
isolation of a controller from its controlled unit(s).
On the off-chance that someone decides to make a server-grade Kestrel,
this support will let them more easily administer Kestrel servers in a data center environment.
Closer to home,
this also allows a home user to not have to power a machine down
just to install or remove new hardware.

As someone who often performs digital ingest services for a fan-made Star Trek production,
having the ability to swap large harddrives on a fast interconnect with the computer hot is _very_ appealing,
and would save a lot of time and effort.
Both PCIe and eSATA provide this feature,
but supporting either interconnect is, you guessed it, nearly impossible for a homebrewer to tackle.

### Support DMA.

A protocol should exist which allows a peripheral to request contents of memory from _any_ attached device.
There's no reason for a network adapter to beg the attention of the host upon packet receipt
if it already knows where to deliver the data.
Obviously, this requires hardware support,
which implies *hardware* protocol implementations to function as intended.

If such hardware isn't available, which in a homebrew environment is a real possibility,
DMA transactions should look and feel like any other software-managed transaction.
This means that when a peripheral wants to function as a master,
and hardware for this doesn't exist,
the link will _gracefully degrade_ to a software-emulated DMA transaction.
The Kestrel-3 or the peripheral
will only know the difference because of its slower transfer speed.
The protocol itself must remain the same.

### Support general purpose messaging.

A protocol should exist which allows bulk transfer of data
without concern for target address space.
For example, if I'm making a printer interface,
there's no reason I should have to know the memory map of the printer.
I should just be able to issue command messages to it,
instructing it what format my page data is in, how many copies, etc.
Likewise with mass storage;
I should not have to be concerned with the precise address space of the controller or its units.
I should just be able to say, "Fetch me sector 2 on unit 0", or,
"Write this data to sectors 42 through 48."
For that matter, we can extend the concept further and
off-load the very filesystem itself to the peripheral.
We haven't seen anything like this since the death of Commodore's 8-bit floppy drive units,
at least until Plan-9 from Bell Labs.

In a multi-processing environment,
messaging can also be used by individual computers to talk to each other.
Passing TCP/IP over this messaging protocol may be a bit wasteful,
but it'll enable a lot of opportunities for
high-performance computing with minimal application rework.

### Support interrupts.

A protocol should exist which allows the peripheral to *asynchronously* grab the attention of some processor.
We can overload DMA operations for this, just as NuBus, TURBOChannel, HyperTransport does.
The idea is simple:
when you need service,
send a control word to a well-known memory location, where a processor will see it.
That processor's I/O bridge,
having knowledge of this well-known memory location,
will recognize the transaction and flag a local interrupt automatically.
If no such bridge exists, this transaction degrades gracefully to just another packet transaction,
which will itself trigger some kind of event handler when the corresponding `SRQ#` assertion happens.

### Switched Fabric.

You can attach one of two different kinds of devices to an SPI interface.
The first and simplest kind is a peripheral that takes its commands directly from the serial bit-stream,
and delivers its response directly to the serial bit-stream back to the Kestrel.
With this relationship, the slave-select (SS#) signal is responsible for addressing the specific device,
and also serves double-duty for properly framing commands and data between the peripheral and the Kestrel.
An SD or MMC media card are perfect examples of this class of SPI peripheral.

The other kind of peripheral is called a _switch_, and
it's responsible for routing traffic between the true peripherals and the Kestrel.
The totality of all switches in a system is called a _fabric_.

A simple peripheral need not concern itself with device IDs or other kinds of framing overhead;
however, you lose the ability to attach more devices to a port than you could otherwise.
While the Nexys2 offers four Pmod interfaces,
not all of Digilent's products offer as many interfaces.
Other vendors which use Pmod-compatible ports may only offer one or two, for example.

For this reason, with the sole exception of SD/MMC card support,
I'm recommending a switched fabric be used for I/O expansion.

## Evaluating the SD/MMC Protocol

Arguably the simplest and least-cost point-to-point solution
to letting people engineer peripherals for the Kestrel is to
piggyback on the experience of supporting the SD/MMC protocols.
The SD/MMC protocol is a block-transfer protocol which is very efficient
(up to 96% efficiency on the wire)
and relatively simple once you get past device initialization
(device initialization itself is a bear).
But, how well does it support our requirements?

### Start with basic SPI as our foundation, and build on top of that.

This is a gimme.
When power to an SD/MMC card first appears, it starts in native SDIO mode.
However, it's fairly easy to put the card into SPI mode.
While in SPI mode, it is capable of supporting (typically) 20MHz or 25MHz, depending on vendor and precise bus specification used.

If you can drive the bus in native SDIO mode, it can transfer data at 4x the nominal SPI data rate.
However, SDIO is a proprietary protocol;
while the specifications can be found online, you legally require a license to actually use it.

Also, by its nature, SD/MMC cards are restricted to a single SPI or SDIO data lane.
Thus, these devices exhibit limited ability to scale up to faster interconnects.

### Cost should scale with bandwidth requirements.

SD/MMC offer a fixed level of performance, at least when using openly available standards.
A variety of enhancements have been made to the native SDIO interface which supports faster transfer speeds,
but again, you need a license to use the technology.

### Leverage concepts.

Framing is achieved with a `0` start bit in the first command byte.
Both MISO and MOSI signals idle high when not in use, which appears as the byte `$FF` in software.
Leading command and response bytes vary in value between `$00` to `$7F`;
anything else would set the high bit, which would cause subtle framing errors.
`$FF` bytes are therefore ignored, except when appearing inside a command, response, or data frame.

Commands are fixed length, always five bytes followed by a CRC byte.
Likewise, all SD card responses, errors, and data streams are similarly framed.
For variable length chunks of data,
one requires setting the block length using a command (CMD16) first.

Since commands, responses, and even variable-length data blocks are framed,
the SD/MMC *protocol* can be sent down any channel width,
even if SD/MMC *devices* cannot support wider interconnects.
By striping bytes across multiple lanes on an as-needed basis,
the receiver can easily figure out which bytes are valid and which can be ignored.

The basic concepts of the protocol are:

* Setting block size to that desired for a transaction.
* Reading one or more blocks from the device (of the desired block size).
* Writing one or more blocks to the device (of the desired block size).
* Reading the card ID and capability registers.

These commands, on their own, are relatively easy to generalize and support arbitrary hardware with.
Since SD/MMC cards support both SDIO and SPI interconnect technologies,
the protocol naturally tends to be reasonably well factored from the underlying physical layer.

### Single-beat and burst transfers.

The SD/MMC protocol offers no explicit support for single-beat transfers
(blocks of data 8 bytes or less)
as distinct from burst traffic.
All I/O transactions occur with block data transfers.
You can, as a separate command, set the byte length of a block
(which I believe is limited to 2048 bytes, but I'm not aware of a lower limit).
Therefore, you can emulate single-beat transfers 
using the normal block data transfer commands;
however, you need to remember to set the block length appropriately.
The SD/MMC protocol assumes a stateful card, so once block length is set, it remains set.
This is good, as it lets you amortize the cost
of the _change block length_ command
across a number of subsequent I/O transactions.
However, it's a liability in multi-processor configurations,
in that each processing element cannot
assume another processing element hasn't altered the block length.
Therefore,
you need to remember to
either lock the channel from concurrent access, or
be sure to set block length explicitly with each transaction.
Either approach introduces overhead.

### Trivially simple auto-config.

The SD/MMC protocol provides overt support
for discovering a number of attributes about the SD/MMC card in use.
The inability to address multiple devices on a single link means that
you don't need to recursively enumerate devices.
Simply knowing the card's timing parameters,
preferred interconnect,
and capacity is sufficient to productively use the card.

The capability register contents are optimized for storage-type devices, of course.

### Support for hot- and warm-plugging.

The SD/MMC protocol offers no overt support for hot-plugging.
Instead, a master relies on an external mechanism,
usually a microswitch driving a single GPIO pin,
to report card presence.
Note that this I/O pin exists outside of the SDIO or SPI interconnect.

When the card is detected, a bring-up/initialization protocol is invoked to enumerate the SD/MMC card.
First, the link is brought into SDIO mode, then if using SPI, told to switch over to SPI mode.
At this point, data rate is low, typically tens to hundreds of kb/s.
Once the master reads the card's capability registers,
it may reconfigure the SPI link to drive the card at a faster rate.

If a user pulls the SD/MMC card, any in-flight transactions will (eventually) timeout.
Data corruption might occur, especially if
(as standards recommend)
the FAT filesystem is used on the card.
It is up to the cooperation between the user and the master
to ensure reliable storage when pulling an SD/MMC card.

### Support DMA.

SD/MMC offers no support at all for slave-initiated direct memory access.
The master controls all transactions.
The master may,
at its discretion,
use a DMA channel controller to communicate with the SD/MMC card.

### Support general purpose messaging.

None.
The SD/MMC protocol is strictly organized around low-cost mass storage.

### Support interrupts.

None that I can find in publicly available specifications.
The SD/MMC interface doesn't have enough pins available to support an interrupt or service request signal.
Further, it has no need for one;
since the master fully controls the storage medium,
no reason exists for the card to report anything back to the master asynchronously.
I'm not sure about SDIO though.

This means any I/O peripheral built to emulate an SD/MMC card
will require the master to poll periodically as required.

### Supports software or hardware implementations.

The protocol is fairly easy to emulate in software, although
you will probably try several times before you get it right.
(I certainly did!)

I was able to implement a proper subset of the SD/MMC card protocol in the Kestrel-3 `e' emulator,
and am pleased with how relatively simple it (finally) ended up being.
Porting the guts of this code to something like an Arduino
would easily allow one to build a peripheral based on the SD/MMC protocol.
Depending on your buffering requirements, however,
it could require a fairly substantial block of RAM to support,
which might preclude smaller microcontrollers.

### Switched fabric.

Unfortunately, the SD/MMC protocol offers no means that I could find
for supporting multiple peripherals on a single link.
A single peripheral adapter _could_ be made to support multiple controlled units
by partitioning the SD/MMC address space among them, however.
To truly support multiple peripheral controllers on a single SPI or SDIO lane,
incompatible changes to the protocol becomes necessary.

## Evaluating RapidIO and HyperTransport

Both RapidIO and HyperTransport offer solutions which target chip-to-chip and,
now-a-days,
board-to-board interconnects.
They scale from bit-serial links to wide 32-bit interfaces, and operate with a variety of data rates.
They seem ideally suited to function as a common I/O infrastructure for the Kestrel-3.

### Start with basic SPI as our foundation, and build on top of that.

Per their specifications,
both RapidIO and HyperTransport can operate over pairs of
clock-forwarded, bit-serial links
operating at very high data rates.
Each unidirectional link operates independently of the other,
and both currently rely on DDR clocking.

To get either RapidIO or HyperTransport working on an SPI link,
I would need to provide a new physical layer mapping.

For RapidIO, this should prove to be a relatively easy task.
The protocol is layered into three different, and mostly orthogonal, layers.
Where they aren't orthogonal, it's for reasons of bit transfer efficiency.
For example, the LP-LVDS 8/16-bit parallel binding offers a 10-bit header,
which fits the 6-bit prefix specified by the common transport layer,
thus making a nice 16-bit quantity that is easy to send or receive on octet-optimized links.
The transport layer, then, juggles one field from the logical layer around,
again to ensure a better fit on octet-optimized links.

RapidIO frames do not explicitly have a length field, but
their lengths can always be statically determined by examining some fields in the headers of each frame.
Furthermore, RapidIO frames can grow only to some maximum size
(as specified by the physical layer binding),
so buffer management is tractible in hardware implementations
and predictable in software implementations.

RapidIO's bit stream is not optimized for self-synchronizing framing.
Traditionally, RapidIO has relied on a dedicated hardware signal, `FRAME`,
which _toggles_ at the start of every new frame.
Thankfully, especially since RapidIO's own specs do this,
we're free to reorganize bit stream mapping when creating a new physical binding.
As it happens,
enough reserved bits exist in the LP-LVDS parallel bit streams that we can fairly easily
map it to any number of SPI channels.

HyperTransport's solution to delineating frames comes in the form of a `CMD#` signal
that rides along side the serial link.
They recognized that, over the wire, bit streams always alternate between command and data payloads.
Therefore, they arranged the link so that when `CMD#` asserts,
the serial input couples to a dedicated command shift register,
and when `CMD#` negates, the serial input goes to a dedicated data payload shift register.
This reduces a device's implementation complexity,
because the peripheral will always know what's command, and what's payload.
No complex decision trees are necessary, not in hardware, and not in software.

The problem comes when you attempt to map this to a transparent byte channel like SPI.
In essence, you can think of `CMD#` as a ninth bit for each byte sent over the link.
HyperTransport guarantees commands will not exceed 12 bytes in length,
and they always grow in 32-bit units.
We can use this knowledge to come up with a framing protocol
that incorporates a start bit with a command/data flag, and a length field.
For example, if we use the following layout:

    +---+---+---+---+---+---+---+---+
    | 0 | C | l | l | l | l | l | l |
    +---+---+---+---+---+---+---+---+

    Length = 4 * l + 4, where 0 <= l < 64.
    C bit is set for commands, clear for data.

    000000 = 4 bytes
    000001 = 8 bytes
    et cetera.

we can still use a single byte to represent frames up to 256 bytes long,
while identifying clearly which are commands, and which are data.

For both RapidIO and HyperTransport, though, we would need a CRC which includes the framing byte.
That helps prevent single-bit errors from causing the endpoints from losing sync with the sender.

In summary,
both RapidIO and HyperTransport can map cleanly to SPI,
albeit with some willingness to juggle bits around.

### Cost should scale with bandwidth requirements.

Since both RapidIO and HyperTransport can be made to work over a transparent byte channel,
they both can scale to very slow or very fast links as well.
The only requirement is that the peers remain in synchrony with each other.

### Leverage concepts.

Both RapidIO and HyperTransport are specified in layers.
I find RapidIO is more cleanly defined than HyperTransport;
however, HyperTransport is nonetheless still easy to understand.
HyperTransport has an implicit assumption that it's being used in a system with PCI devices,
while RapidIO makes no assumptions what-so-ever of the environment it's deployed in.

With either technology,
the underlying protocols
have been mapped to a wide variety of
interconnect widths,
data rates,
and different signaling mechanisms.
Both RapidIO and HyperTransport were designed from the ground up to support
"slow" links (around 2Gb/s) to much faster links (at least 20Gb/s, possibly faster).
Getting these protocols to work over something much slower, like a 1Mb/s SPI link, is child's play.
The core concepts behind either technology
has proven resilient against changes in specific interconnect technology.
For this reason,
it ought to be relatively easy to implement a software emulation of either protocol.

### Single-beat and burst transfers.

While single-beat transfers would result in sluggishness due to protocol overhead,
they are nonetheless supported explicitly (vis. `NREAD` packets in RapidIO).
We find that SD/MMC's protocol overhead compares favorably with either RapidIO or HyperTransport.
By my calculations, a single byte read would take, worst case, about 18 bytes of overhead, broken down as follows:

* 6 bytes for the set-block-size command to set block size to 1.
* 1 byte for the set-block-size response code.
* 6 bytes for the read-command.
* 1 byte for the read-command response code.
* 1 byte for the data framing byte.
* 1 byte payload.
* 2 bytes CRC.

RapidIO and HyperTransport would require 36 and 28 bytes to cross the link, respectively.
(The additional overhead comes from supporting the needs of a switching I/O fabric,
which as you might recall from above, SD/MMC protocol and devices do not support.)

Where all three of these protocols shine is in bulk transfer of data.
RapidIO supports payloads as large as 256 bytes (with power-of-two granularity once you go beyond a single beat),
while HyperTransport allows for 64.
RapidIO's bandwidth efficiency for a 256-byte `NREAD` + `RESPONSE` exchange comes to 91.4%.
Lower than SD/MMC's link efficiency of 93.7% (for a 256-byte payload to keep things fair),
but well within the ballpark.
HyperTransport's smaller maximum payload size limits its efficiency to just 84.2%, however.

### Trivially simple auto-config.

Neither RapidIO nor HyperTransport support _trivial_ auto-configuration.
However, they do overtly support plug-and-play capabilities in some capacity.

Automatic configuration of RapidIO occurs, near as I can tell, in two phases.
The first phase "enumerates" all the endpoints, assigning each their addresses,
and in the process, configures all intervening switch routing tables to reach them.
Endpoints and switches both provide a _large_ number of CARs (read-only Capability Registers)
and CSRs (read/write Configuration and Status Registers).
Through these registers, system software can identify who made the peripheral (assembly ID),
who manufactured the components inside (vendor ID),
and what kind of device it is (model ID).
If this isn't enough,
an extensible protocol for customized CARs and CSRs exists.
If the system software provided a mapping from these IDs to a device driver,
device drivers can be loaded upon demand, without user intervention.

RapidIO supports 256, 65536, or over 4.2 billion uniquely addressible devices,
each of which may contain its own 34-/50-/66-bit address space.
RapidIO does not lack addressing capability.
The Kestrel will probably be content with 8-bit device IDs
and 34-bit address spaces
for some time to come.

HyperTransport relies upon PCI standards to support device configuration and discovery.
These also involve a large number of registers, but the process is quite well understood, and
reference enumerators and configurators can be found online with fairly little difficulty.
However, all devices must share a common address space.

### Support for hot- and warm-plugging.

As long as the controller operates on a separate power supply than the controlled units,
both RapidIO and HyperTransport could, in theory, be made to support warm-plugging of attached units.

I don't know about HyperTransport;
however, I know contemporary versions of RapidIO offers hot-plugging support at the physical layer.
I found the protocol and CSR register definitions very complicated to follow.
This is not a protocol that should be implemented lightly; it's pretty heavy-weight.

### Support DMA.

Both RapidIO and HyperTransport evolved
out of a need to replace existing front-side buses on microprocessors with
something cheaper and faster than a multi-drop bus.
Since these interfaces will terminate at some point in a memory controller,
it's arguable that DMA is _the_ reason they exist.

### Support general purpose messaging.

Later HyperTransport standards have messaging support by streaming data to a well-known address.
General purpose messaging has been a part of the RapidIO specifications almost from its inception.
RapidIO's longer packet lengths will provide better efficiency.

### Support interrupts.

HyperTransport supports interrupts by memory writes to a well-known address space.
Unlike RapidIO, however, HyperTransport imposes a request/acknowledgement protocol.

RapidIO provides a service called _doorbells_,
which are short (16-bit), fixed-length messages you can send to another device.
These doorbells are typically interpreted as requests for service or notifications that something is complete.
Therefore, they map naturally to interrupts.
RapidIO does not provide explicit protocol support for acknowledgements.
An acknowledgement would come when an interrupt service routine accesses a particular register,
just as 6502- and 6800-compatible hardware used.

### Supports software or hardware implementations.

Both RapidIO and HyperTransport appear to be relatively easy to support in a microcontroller,
as long as you're happy with the lower performance levels this implies.

### Switched fabric.

HyperTransport does not rely on a switched fabric in the traditional or normal sense.
Instead, it relies on _daisy-chaining_ devices together.
Since HyperTransport does not give devices unique IDs, they all must share a common address space.
When a master makes a memory request,
the first device in the chain will compare the address
against a set of _base address registers_, or BARs.
If there's a hit, the device responds to the request, and the packet goes no further.
However, if the address is not intended for that device (does not match any BARs),
it queues the packet for transmission down the chain.
Any response packets for any device other than itself will be forwarded without hesitation.

RapidIO has a more complex switch fabric.
Each switch requires a routing table.
This table maps device ID to output port.
It doesn't pay attention to memory addresses, requests or responses, etc. at all.
The only time a switch will respond to a RapidIO packet is if
it receives a maintenance-class packet, _and_, the hop-counter is zero.
(Otherwise, there'd be no means of configuring a switch!)

Switches can connect to other switches.
While this increases latency,
it also expands greatly the number of devices you can afford on the RapidIO interconnect.
For example, a Kestrel-3 might have a 16-port switch internally, allowing up to 16 devices to be connected.
However, if a device happens to include a switch of its own,
that one controller can provide access to a plurality of controlled units,
each represented by a unique RapidIO device ID.
Alternatively, one Kestrel can connect to another, and each switch can route traffic to each other's memory or peripherals.

## So, What Do We Use?

The SD/MMC protocol doesn't allow attached devices to seek master attention,
which is important for many kinds of peripherals.
That is an instant disqualification.

I attempted at one point to come up with my own COBS-based protocol to serve as a point of comparison,
but honestly, I cannot do better than RapidIO while preserving its more desirable capabilities.
Therefore, for once in my life, I'm not reinventing the wheel.  :-)

HyperTransport has two demerits:
daisy-chained devices and unified address space.
Daisy-chaining is great for simple interconnects and greatly reduced hardware complexity.
It comes with a performance penalty, though.
If you have _n_ HyperTransport devices on a single link,
it can take up to _n_ packet propegation delays before finding the right endpoint.
If no endpoint exists, the bus must time-out, which can take some time in naive implementations.
For this reason, a computer engineer must be aware of the devices the computer will most frequently access, and
place them closer to the processor using them.
As you add more and more HyperTransport devices, these latencies get bigger and bigger.
Thus, there exists an incentive to keep the number of HyperTransport devices to a minimum,
which seems counter to the goals of peripheral expansion.
You might not notice this effect when your interconnect runs at 40Gb/s, but
it will become quite noticeable at the slower SPI speeds.
(To be fair, though, HyperTransport was never intended as a general purpose I/O interconnect.)

The requirement to map all peripherals into a single, flat address space
is indeed convenient from a software engineering point of view.
However, it also means that you lose the ability to talk to another computer
using the same fabric as you would any other peripheral.
That is, a network and a backplane remain fundamentally different things,
even though they both basically _do_ the same thing: ferry data from point A to point B.
For high-performance computing applications, this can be overcome with per-device bank-switching hardware.
The problem here is that said hardware is a global resource;
*all* I/O peripherals see the same bank-switching hardware.
You also are at the whim of that hardware being present at all.
If not, you're done.

RapidIO's fabric does not (have to) rely on daisy-chaining.
Switches route traffic based on a packet's destination device ID,
thus forming a tree-structured data path.
This minimizes latency when routing traffic to any endpoint, including a processor.
For a computer with the complexity of a Kestrel-3,
there should _never_ be any reason for more than two switch delays.

Each attached peripheral has its own (potentially quite huge) address space.
Each RapidIO local processing element is responsible for providing its own window
into a remote peripheral's address space.
This makes device drivers somewhat more complex, since
you must remember to set your I/O windows appropriately if they're not already set.
However, you gain in not having to worry about as much global state and
you get better support for (symmetric or asymmetric) parallel processing.

Correspondingly, since it's very rare for a RapidIO bridge to sport anywhere near 256 concurrently accessible devices, let alone 4.2 billion,
RapidIO's device IDs amounts to a kind of bank switching mechanism which is local to the processing element.
Each set of RapidIO BARs, local to the processing elements that are using them,
allows access to large address spaces on a per-device basis,
without the addressed device requiring any special support.

While both RapidIO and HyperTransport can pass message traffic between nodes
without having to worry about the target's detailed address space layout,
RapidIO can do so with better efficiency on the wire.

Of the available I/O standards, I think RapidIO meets my needs the best.

There's just two small problems with RapidIO which prevents me from actually _saying_ I support RapidIO:
first, I need to pay $9,500/year to acquire and keep a vendor ID for auto-configuration purposes;
second, I find its device capability registers inadequate for the device driver model I'd like to support.

My solution to the first problem is fairly straight-forward:
my I/O standard will use RapidIO's logical and common transport specifications, but
the physical mapping to SPI and a completely custom enumeration mechanism suitable for home-brewers
will be what differentiates my product.
Since I can't use the RapidIO name,
I've even given it a suggestive, yet deliberately silly, name:
PatientIO (because your data will get there when it gets there!).

My solution to the second problem is to borrow an idea from Microsoft's Component Object Model.
Instead of relying on a simple (assembly ID, vendor ID, model ID) -> device driver mapping,
I instead will use a list of *interface IDs*.
If a peripheral is compatible with a well-known binary interface,
then it should list that binary interface's UUID.
This reduces the need for complex device mappings and registry hierarchies, and
replaces it with a more direct means of discovering which drivers are compatible with which peripherals.
Note that this does not replace the existing RapidIO identification mechanism;
PatientIO's solution sits beside it.
Think of this as a
[horizontally-structured abstraction]({{site.baseurl}}/2015/08/12/gui-code-walkthrough/),
rather than a vertical abstraction.

Let me be very, very clear here, though:
my goal *is not* to put the RapidIO Trade Association out of business.
They've so far been very friendly to me and my Kestrel project, and it'd be foolish to burn them.
PatientIO merely exists because I, and I know many other home-brewers,
cannot afford their entry level costs for a vendor ID.
If you can, please support the RapidIO Trade Association, even if it's just through promotion.
They put a lot of work into their standards, and it shows in the quality of their specifications.

## Conclusion

As this article is already large enough as it is,
I'll defer the physical mapping to SPI for subsequent blog articles.
Besides,
it'll be a long while before I tackle the first PatientIO implementations for the Kestrel-3.

However, I'm eagerly awaiting the opportunity to do so.
I feel viscerally excited about the opportunities 
that RapidIO-compatibility will provide to the Kestrel ecosystem,
and I hope you feel similarly.

