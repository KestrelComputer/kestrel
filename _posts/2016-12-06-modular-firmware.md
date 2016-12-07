---
layout: post
title:  "Modular Firmware"
date:   2016-12-06 16:00:00
---

The Kestrel-3 requires, like any computer, some "initial program" in order to run.
Unlike the IBM System/360 and DEC PDP-11,
I cannot just place a deck of punch cards or a roll of paper tape in a reader to "IPL" the computer.
The initial program for the Kestrel-3 must be placed in ROM, or something approximating its behavior.
This should come as no surprise to anyone.

However, the Kestrel-3 computer design aims to target at least two different FPGA development boards:
the Digilent Nexys-2 (no longer manufactured), the Terasic DE-1, and if I can make it fit, the myStorm BlackIce module.
I also have an Avnet LX9 MicroBoard which, while not directly capable of hosting a full Kestrel user experience,
might still be usable as an intelligent network controller running Kestrel firmware.
Each of these modules offers *very* different capabilities, as the table below demonstrates:

|Feature|Nexys-2|DE-1|Black Ice|Avnet LX9|
|:------|:------|:---|:--------|:--------|
|Video Resolution|configurable up to 640x480 maximum|configurable *at least* up to 640x480, possibly capable of 800x600 or higher|Expansion required.|Expansion required.|
|Color Depth|2, 4, 8, 16, or 256 colors out of a palette of 256|2, 4, 8, 16, or 256 colors out of a palette of 4096|Expansion required.|Expansion required.|
|Audio|Expansion required.|24-bit codec standard.|Expansion required.|Expansion required.|
|Keyboard|PS/2|PS/2|Expansion required.|Expansion required.|
|Mouse|Expansion required.|Expansion required.|Expansion required.|Expansion required.|
|Mass Storage|Expansion required.|Built-in SD card.|Built-in SD card.|Expansion required.|
|Network|Expansion required.|Expansion required.|Expansion required.|10/100 Ethernet|
|General purpose I/O|Three 2x6 usable Pmods (out of four) + Hirose adapter exposing 43 I/Os|Two 40-pin IDC connectors exposing 36 I/Os each|Two 1x6 Pmods + Six 2x6 Pmods + ARM-based I/O (Arduino-compatible) + header pins|Two 2x6 Pmods|
|ROM|Block RAM + 16MB Flash|Block RAM + 4MB Flash|Block RAM only|Block RAM + 16MB Flash|
|RAM|16MB Cellular RAM (in asynchronous mode, 70ns access)|512KB 10ns SRAM + 8MB SDRAM|512KB 10ns SRAM|64MB LPDDR SDRAM|


