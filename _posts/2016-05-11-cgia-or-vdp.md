---
layout:	post
title:	"Instead of CGIA, Go With a Super-VDP Instead?"
date:	2016-05-11 18:22:00
---

*(This article first appeared on [my Hackaday.io project page.](https://hackaday.io/project/10035-kestrel-computer-project/log/37873-instead-of-cgia-go-with-a-super-vdp-instead)  I've since made some minor edits, and reposted it here.)*

After stumbling upon a [fairly sizable collection of design notes and interviews](http://spatula-city.org/~im14u2c/vdp-99xx/) from the inventor of the Texas Instruments TMS9918A VDP (video display processor), I began to entertain the possibility that maybe the Kestrel-3 should use a VDP-like video core to replace the MGIA instead of my original CGIA (Configurable Graphics Interface Adapter) idea.

## Recap: CGIA

I've not disclosed details about the CGIA much anywhere because I never had a need to, but this is what I've been thinking. Take the MGIA logic as-is, and expose some of its guts to the programmer. In particular, retain the ping-pong scanline buffer, where a (now programmable) DMA engine fetches data into the ping buffer, while the CGIA refreshes the screen from the pong buffer.  Every HSYNC, the CGIA simply swaps the roles of the ping and pong buffers.

The fetch logic would not make any attempt to interpret the meaning of the bits it stuffs into the ping buffer at all.  Meanwhile, the contents of the pong buffer would be clocked out at a configurable rate (thus achieving a configurable horizontal resolution), with the bits routed to a palette register bank in a configurable manner. In this way, the programmer would have complete control over video bandwidth/CPU bandwidth tradeoffs.

## Recap: VDP and its Progeny

The TMS9918A exposes only a minimal amount of configuration to its user; coming out of reset, it is basically configured in a 32x24 character display (what they call "pattern graphics"). The configuration it does offer is, for example, whether or not you're using 4K or 16K dynamic RAMs, whether or not background video is genlocked, and where the various display tables will appear in video RAM. The number of colors supported and the monitor synchronization timing are all hard-wired to support NTSC television, not unlike the Kestrel-3's MGIA being hardwired to support IBM VGA. A completely separate chip had to be made a few years later to address the PAL market.

Later generations of the VDP, such as the V9938, V9958, and V9990, all added higher bandwidth paths to memory when they became available, support for higher color depths, planar as well as patterned graphics, etc.; but, they otherwise retained their hardwired video timing parameters. An [open source clone](http://codehackcreate.com/archives/30) of the TMS9918A that borrows some V9938 features, and which drives a VGA display, is also available online.

Finally, [there is the Gameduino 1.0](http://excamera.com/sphinx/gameduino/) device, which is perhaps the first VDP-like video interface to actually drive SVGA monitors (800x600 72Hz, to be precise). It's feature list is most impressive; however, it is limited in its resolution (400x300 visible pixels out of 512x512 addressible pixels) and available on-screen colors (globally on the screen, you can show lots of colors; but your palette selections for local details are limited and highly optimized for tile-based graphics, such as you'd find on NES-like gaming consoles). It fills its niche quite well, but I don't think it's appropriate for the Kestrel-3.

## My Thoughts

I think, if I were to go the VDP clone route, and it is indeed appealing for a number of reasons, I do not currently see a reason why I couldn't add the programmable video timing parameters I'd like to see. Moreover, I can have it bootstrap into a planar graphics video mode that is backward compatible with the MGIA, thus allowing existing system software to work with it. No need to recompile any existing graphics drivers except where color, sprites, or different resolutions are needed.

Benefits of my original CGIA concept:

- Programmable resolutions and HSYNC/VSYNC polarities to drive SVGA monitors.
- Exposes DMA timing to the programmer to let programmer decide tradeoff between color depth and CPU performance when accessing video memory.
- Single, flat plane of bitmapped graphics.
- Dot shifter (which interprets the data fetched from above flat plane of graphics) would be configurable to use 1-, 2-, 4-, 8-, or 16-bits per pixel, thus affecting the number of colors visible on the screen at once.
- Significantly simpler implementation.
- Effortless vertical smooth scrolling by simply controlling the DMA pointer at the start of every frame.
- Extremely modular design; classic producer/consumer problem in computer science. Higher cohesion, lower coupling (at least at the Verilog level).

Detriments of my original CGIA concept:

- No sprites. They'd need to be emulated in software. For high color-depth screens, this would be a performance bottle-neck.
- No pattern graphics modes. AKA, no character display modes. This means you cannot poke a single byte into video memory and expect a complete character to be displayed. You have to write console drivers which places a glyph onto the display. (This is already done in Kestrel-3's firmware now, but it costs runtime performance.)
- No horizontal smooth scrolling. You have to emulate this entirely in software. CGIA is not optimized for game-play, but rather for productivity instead.

Benefits of adopting a VDP-like architecture:

- I can add programmable HSYNC, VSYNC timing and polarity control easily enough.
- I can, albeit with somewhat less flexibility, still expose CPU/video bandwidth tradeoffs to the programmer.
- Support for planar or chunky graphics can be added easily enough. V9958 proved that. This implies effortless vertical smooth scrolling as well.
- Support for pattern graphics/character modes.
- Sprites. Potentially lots of them. On a 640x480 VGA display, and if my math is right, I can probably pull off between 16 and 20 (monochrome) sprites on a single scan-line at any given time. With a 1024 pixel wide, monochrome display, probably closer to 40. This won't win many awards from arcade game aficionados, but it is more the adequate for supporting WIMPy user interfaces that supports effortless drag-n-drop of icons.

Detriments of adopting a VDP-like architecture:

- Significant complexity compared to my original CGIA concept.
- Internal design will require greater number of internal dependencies.
- Still no obvious way to support horizontal smooth scrolling.

I can't think of any further disadvantages. I should point out that the horizontal smooth scrolling problem is caused by the same problems in both VDP and CGIA designs. They would be solved in the same way for both as well. While I list lack of horizontal smooth scrolling as a detriment for both, any solution I come up with for solving that issue would equally apply to both VDP and CGIA.

So I'm curious about your thoughts; should I try to go with a VDP architecture? Would this make the Kestrel-3 more appealing for others to use or program for? Should I stick with a simpler graphics architecture and rely on improving CPU performance to make up for sluggish frame rates in the future?
