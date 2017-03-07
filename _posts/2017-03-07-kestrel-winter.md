---
layout: post
title:  "Winter for Kestrels: Shutting Down a Dream"
date:   2017-03-07 16:00:00
---

# Abstract

I've been unemployed since November 2016, and Kestrel-3 progress has slowed to a crawl despite all my efforts devoted exclusively towards it.
Without small wins, I lose hope and it manifests when attempting to look for a job.
Mothballing this project in favor of other projects is the only way forward.
I'll be resurrecting my old attempt at self-employment, RezuRezu, in the hopes that it either helps me land another job soon-ish, or I actually succeed in running my own company.

## Vacation's Over

I left Rackspace in November, 2016,
where I devoted all of my time towards the Kestrel Computer Project.
I was hoping that I could use this time to bring something,
*anything*,
out to the world.
I had a working emulator for the machine I envisioned building with the now-discontinued Digilent Nexys-2 FPGA board.
I had the start of a decent quality guide for new user's.
I had a clear vision of what I wanted, and I had people who agreed with me and followed me accordingly.

As my followers know, I've had to withstand numerous set-backs of both technical and social varieties.
I'll discuss only some of the issues below;
however, let it be known that this set is not exhaustive.
For every kvetch I belched onto Twitter,
at least two or three more went unpublicized.

### RAM-rodded.

While working with the Digilent Nexys-2 FPGA board,
I've had the most unfortunate experience of working with their choice of PSRAM chip,
a Micron part that is the sole reason this board isn't made anymore.
When running this part in asynchronous RAM mode,
following the only timing criteria I could find,
the chip refused to support writes of any kind.
When running this part in synchronous RAM mode,
the chip refused to support any kind of reads.
It's also likely not supporting writes as well, but without reads, it's impossible to tell.
Literally, the chip simply **refused** to assert voltage on the data bus, so far as I could tell.

Thus, I cannot use the Nexys-2 for anything beyond what RAM the FPGA itself provides.
This is why the Kestrel-2 works fine on it, but the Kestrel-3 is a non-starter for this platform.

### RAM-rodded 2.0.

In my attempt to get the above problem resolved,
I sought known working examples of projects using this chip.
I found **nothing**, not even on the back country hills of Github,
where it's a vast wasteland of unfinished projects as far as the eye can see.

The only project I am aware that actually uses this chip successfully (ostensibly)
is Digilent's own VHDL board BIST designs.
However, the *way* it used this chip was utterly retarded:
it was a *peripheral accessed via MMIO* from an on-board microcontroller that ran from internal block memory.

Let me be plain.  **This is the only known working example for using this RAM chip that I can find.**

Subscribing to Digilent's forums proved fruitless as well.
Don't get me wrong; people were helpful and, thankfully, put up with my acerbicness.
Nonetheless, their efforts didn't help.

### Slipping on Black Ice

Knowing that my efforts with this FPGA board were bust,
I decided to try my luck with the Lattice iCE40-based boards that I have:
the icoBoard Gamma, and the MyStorm Black Ice board.
Both of these boards are quite minimal,
offering *zero* built-in I/O capability,
and an FPGA with only 7600 LUTs (as compared from the 50,000 LUTs or more offered by larger FPGA boards).
This meant that the Kestrel-3,
as I've originally conceived it as a home computer a la Commodore 64 or Atari ST,
would never fit.
Not, at least, on one chip alone.

So, I decided to adopt a more minimal architecture,
learning lessons from the older generations of IBM Mainframes in the process.
In particular, build *the computer*, and a standard method of conducting I/O,
and leave the rest of the details to off-board I/O controllers.

I started the Remex I/O controller project as a way of learning IEEE-1355 data/strobe signaling,
and the various state-machines required for hardware protocol management.
According to its inventors, you can make one of these things in the same amount of area as you can a 16550 clone.
I'm calling bullshit on that, based on my experience.
It's small, to be sure, but it's not *that* small.
Anyway, I digress.
Point is, the Remex controller was never *fully* completed;
the complexity of the whole package *alone* is too big for me to keep in my head.
The RX pipeline is more or less finished, and I'm actually quite happy with it!
Working on the TX pipeline, however, I ended up blocked.
I'm just not motivated to finishing it.
I will *someday*, though.  I really *like* Spacewire as a technology,
and I think it's worth having a truly open-source implementation that is FPGA-optimized instead of ASIC-optimized.
But, I'm burnt out trying to get things to work right now,
so I'll return to this project later.

So, I decided to use what I have of Remex in an attempt to make *something* work.
(Notice a pattern here?  I just want *something* to work.  **ANYTHING!**  I'm desperate for vindication here!)
I packaged the KCP53000 CPU, my 64-bit RISC-V core which is already FPGA proven,
along with all the necessary bridges to interface it to a 16-bit Wishbone bus interface
(since RAM exposes only a 16-bit data path),
a 256-byte bootstrap ROM for testing purposes,
and attempted to simulate the design.
I'd written some simple firmware that just blinks a handful of LEDs; less than 20 instructions total.
This should be a *snap* to simulate.

Except that it wasn't.
Icarus Verilog apparently gets stuck in an infinite loop while simulating.
Verilator's linter discovers something like 8 "circular loops",
which I feel has no rhyme or reason to actually exist since the logic is decomposed hierarchically.
But, in any circuit involving strobes and acknowledges,
*some* feedback loops are bound to exist
(if for no other reason than your ack must negate the strobe).
Nonetheless, I have been **utterly ineffectual** at locating these infinite loops,
what's causing them,
or how to remediate them.

OK, this isn't necessarily a deal breaker, but it was a major time-sink.
Maybe synthesis to actual bitstreams will prove more useful?
I try it, and voila, bitstreams are generated!  Woohoo!
So I attempt to plug in my MyStorm BlackIce board and follow the directions on how to program the unit.
Except, for some reason, I do not have a /dev/ttyUSB0 file to send the bitstream to.
That's weird, so I double-check that the MyStorm is being recognized in the USB stack.
Watching the output of `dmesg -w`, I see indeed that it is recognized.
When I look for more information on setting things up on the MyStorm website,
I find nothing.
So I joined their fora, and posted a message for help.
To date, no response so far.

MyStorm is dead in the water.

Next, I decide to work with an icoBoard Gamma that I recently purchased.
This story is even sadder, because upon plugging in my icoUSBaseboard, the only that happens is power is applied.
`dmesg -w` **doesn't even see the device**,
leading me to believe that either the icoUSBaseboard or the icoBoard itself are somehow damaged.
I attempted contact via Twitter and via their online forums.
Again, so far, no response what-so-ever.

icoBoard isn't just dead in the water, it's apparently dead on arrival.

### What About the DE-1?

That leaves only my Altera DE-1 board as a possible vector for further development.
But, I've already invested 3 solid months of trying to get **anything at all** working on this cursed project.
And as I said back when I left Rackspace,
I gave myself only 3 months to get something to work before I had to finally look for employment.
I'm sorry, but the DE-1 will have to wait.

## What's Next for Me?

My next steps are to resurrect my old project, RezuRezu,
especially in light of difficulties looking for jobs I'm compatible with.
I have private and public motivations for doing so.
My private motivation is, frankly, I need something to help me edit my resumes when I start handing them out in force.
My public motivation is, frankly, I'm hoping someone will recognize a business opportunity,
and maybe want to help me turn this into a successful company.

## What's Next for Kestrel Computer Project?

Nothing.

There are no "next steps."

I've exhausted the use of commercial tools to get something working.
I've exhausted the use of open-source tools to get something working.
I've exhausted the patience of my wife.
I've exhausted the patience of myself.

I'll leave the assets of the Kestrel Computer Project online.
If anyone wants to contribute to the project,
I'll happily continue to accept the commits on the faith that they'll work.
People are actively encouraged to learn from what's there,
and I'll be happy to answer any questions people might have to the best of my abilities.

I'll also probably toy around with new designs here and there,
especially as I get burnt out with other projects.
But, I want to make clear that
I neither have the time nor resources to invest in Kestrel Computer Project *as such* any more.
It has failed to bear any fruit for me in any way what-so-ever:

* Lack of progress prevents me from using it as a reference for finding electrical engineering work.
* Lack of progress further prevents me from claiming even *one* "win" on project completion.  That means I'm intellectually broke in the currency of Silicon Valley.
* It's a project which never had wide appeal, so nobody except a small body of followers will care that it's gone.
* It's consumed a voracious amount of time and effort on my part, preventing me from spending time with my wife and friends.  I can't place that burden on my wife indefinitely.

Any future progress on this project will happen organically.
I'll resume attending to it if, and *only* if,
it somehow becomes popular on its own (highly doubtful),
I *accidentally* do something to make it popular,
or if I get so burnt out with other tasks that this becomes the highest priority project again.

## Apologies and Regrets.

I never accepted money for this project,
although I was hoping some day it would let me earn a spare buck by selling kits.
Therefore, I don't really have much to be apologetic for.

Nonetheless, I am sorry to my followers for perhaps misleading them.
Everytime I'd get optimistic about the project,
I'd inevitably write a blog post to the effect of, "Surely, this configuration will work!"
It never did.

If I learned any lesson from this experience, it's this:
shut my damn mouth.

Until next time.

