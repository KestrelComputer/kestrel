program progmem.ram10
start slide

34 left ! 2 top ! S" Hello World!" text

20 left ! 4 top ! S" First Look at the Kestrel-3 and Project" text

20 left ! 6 top ! S" ---------------------------------------" text

31 left ! 8 top ! S" Samuel A. Falvo II" text
32 left ! 9 top ! S" kc5tja@arrl.net" text

33 left ! 11 top ! S" 2016 January 1" text

19 left ! 13 top ! S" https://kestrelcomputer.github.io/kestrel" text
19 left ! 14 top ! S" https://github.com/kestrelcomputer/kestrel" text

0 left ! 17 top ! S" Navigation: 1=First   2=Previous   3=Next   4=Last   0=Quit" text

slide S" First, a bit of history..." title

S" Growing up, I vowed to work at Commodore Business Machines" bullet
S" The cool computers were at Commodore: PET, C64, C128, Amiga" bullet
S" Every model contributed something to computing as we know it today" bullet
2 left +!
  S" PET was the very first commercially successful PC" bullet
  S" VIC-20 proved the utility of serial, message-based I/O.[1]" bullet
  S" C64 provided world-class music synthesis" bullet
  S" C128 burst mode proved serial I/O can be fast enough" bullet
  S" Amiga gave us stereo, 30fps multimedia, multitasking under $1000" bullet 
-2 left +!
S" I wanted to be part of the next thing to contribute to society" bullet
2 top +!
S" [1] Atari 400/800 had SIO years before VIC-20; but, VIC-20 sold" text 1 top +!
S"     more, and C64 smashed records.  Before VIC-20, nobody but Atari" text 1 top +!
S"     used serial I/O for message-based disk access." text 2 top +!
S"     Today, of course, USB is everywhere." text

slide S" Some more history..." title

S" Then, I grew up; CBM went bust, I started washing cars" bullet
S" My dream never died, though" bullet
S" When I could afford it, I built my own computers for myself" bullet
S" At first, it was for fun; a hobby" bullet
S" But, then, ..." bullet
2 left +!
  S" Win-Tel oligopoly started Trusted Computing Initiative" bullet
  S"   (UEFI evolved from Trusted Computing Initiative.)" text  1 top +!
  S" Widespread market refusal of customer's right to ownership" bullet
  S" Legal pressure for covert channels in hardware, software" bullet
  S" APIs to hide complexity, thus creating yet more complexity" bullet
  S" Companies using complexity to justify IP; APIs trademarkable!" bullet
  S" Miniaturization shut out casual electronics hackers" bullet
-2 left +!
S" Together, the average home PC is quite the purpose-built appliance" bullet
S" Office PCs and servers even more so" bullet
S" Over time, Kestrel changed from hobby to political rebuttal" bullet
S" Kestrel an act of rebellion as it is a return to simplicity" bullet

slide S" Kestrel-1P3 (2004)" title

S" `Third prototype' of Kestrel 1 concept" bullet
S" W65C816 16-bit CPU running at 4MHz" bullet
S" 8-bit data path to RAM" bullet
S" 16-bit address (out of 24-bits) used for decoding" bullet
S" 32KiB static RAM" bullet
S" One W65C22 VIA chip for SPI I/O" bullet
S" Neither ROM nor interrupts!" bullet
S" System software loaded through `IPL port', " bullet
S"   a bit-serial DMA interface driven by host PC" text 1 top +!
S" Console via an SPI terminal interface" bullet
2 top +!
S" Proven -- worked great, even on lossy breadboard!" bullet

slide S" Kestrel-2/1 (2007)" title

S" W65C816 16-bit CPU running at 4MHz" bullet
S" 32KiB RAM, expandable to 8MiB" bullet
S" Two W65C22 VIA chips for I/O" bullet
S" No ROM!  System software through serial DMA again" bullet
S" IPL port driven by ATMega microcontroller" bullet
S" Built-in video!  640x480 16 colors!" bullet
S" Built-in sound!  Eight DMA driven, 16-bit DACs!" bullet
S" Expansion!  Eight bus-mastering, auto-config backplane slots!" bullet
S" A worthy successor to the Commodore 128!" bullet
1 top +!
S" Second System Effect: Ambition overcame practical matters" bullet
S"   The design never left the pages of my notebook. :(" text

slide S" Kestrel-2/1 (2007) (con't)" title

S" Nothing technically would prevent the 2/1 from becoming reality" bullet
S" However, I couldn't afford dev tools, FPGAs, etc. back then" bullet
S" Also, design is easy; DEBUGGING, now that's hard!" bullet
S" No appreciation for how many weekends this would take" bullet
S" Kestrel-2 would have to wait until . . ." bullet

slide S" Kestrel-2/2 (2011)" title

S" First FPGA-based design!" bullet
S" S16X4 custom, 16-bit stack CPU (later, S16X4A) @ 12.5 MIPS" bullet
S" 48KiB RAM (32KiB program RAM, 16KiB video RAM)" bullet
S" Custom GPIA for general purpose I/O (16 ins, 16 outs)" bullet
S" SD card for mass storage, typically run at 10kbps" bullet
S" 640x200 monochrome (not enough Block RAM for 640x480)" bullet
S" Still no ROM!  But, RAM pre-loaded from FPGA configuration" bullet
S" PS/2 Keyboard for the first time!" bullet
S" First OS: STS Version 1.0 (2011) - 1.2 (2013)" bullet
S" First App: Milestone-2 for STS V1.1" bullet
S" Simply referred to as `the' Kestrel-2" bullet

slide S" Kestrel-3/E (2014)" title

S" You're using it right now!" bullet
S" Development platform to work out system software bugs" bullet
S" E: emulator for RV64IS RISC-V compatible processor" bullet
S" 16MiB RAM (what comes on Nexys2 FPGA dev board)" bullet
S" 640x480 monochrome (finally, the MGIA unleashed!)" bullet
S" GPIA-II for 64 ins, 64 outs" bullet
S" KIA-II, backward compatible with KIA, now with interrupts!" bullet
S" Finally, a ROM!  (1MiB)" bullet
S" First OS: STS Version 1.5 (2015)" bullet
S" First App: Milestone-2 for STS V1.5 (running now!)" bullet

slide S" Kestrel-3/1 (2017? 2018?) PRELIMINARY" title

S" Target FPGA Board: Digilent Nexys2" bullet
S" 6.25 MIPS RISC-V RV64IS processor" bullet
S" 16MiB RAM (max. 28 MB/s bandwidth)" bullet
S" 640x480, 2 to 256 colors (CGIA)" bullet
S" CGIA boots into MGIA-compatible mode for backward compatibility" bullet
S" BIOS and Forth in ROM; boot STS from SD Card" bullet
S" Channel I/O over SPI for expansion" bullet
S" SD card transfer speeds up to 12MBps" bullet
S" PS/2 keyboard standard; mouse via expansion" bullet

slide S" Kestrel-3/2 (2022?) PIE IN THE SKY" title

S" Custom motherboard built around iCE40 FPGAs?" bullet
S" 50+ MIPS RV64IS processor?  Perhaps LowRISC?" bullet
S" 16MiB RAM minimum (80MBps+ bandwidth)" bullet
S" Explore RapidIO-over-SPI for expansion" bullet
S" Explore: single unit or separate computer from terminal?" bullet
S" Support for at least 32768 colors; 800x600 or 1024x768?" bullet
S" Internal ethernet?" bullet
S" Sv64 MMU?" bullet
S" BSD or Linux port?" bullet
S" Fame?  Fortune?  Heck, I'd be happy if I just had a community by then" bullet

slide S" But....why?!" title

S" PCs are not friendly to software, hardware hacking" bullet
S" OSes have layers upon layers upon layers of abstraction" bullet
S" OS APIs often need `walled garden' development environments" bullet
S" Industry tending toward 100% vendor lock-in" bullet
S" Motherboards ship with EULAs!" bullet
S" UEFI spec is open, but implementations are closed and user-hostile" bullet
2 left +!
  S" Personal 1st hand experience" bullet
  S" Linux upgrade bricked a $1000+ motherboard w/ UEFI after 10 tries" bullet
  S" I'm not the only one: http://tinyurl.com/hxaq4eu" bullet
  S" UEFI: Not Even Once" bullet
-2 left +!
S" PCs aren't anymore; today, they're media appliances" bullet
S" Reverse engineering prevented by DMCA; lawsuits filed" bullet
S" Trans-Pacific Partnership legislation passed" bullet
S" CISA legislation passed; expect backdoors everywhere" bullet

slide S" Remember when..." title

S" shutting down a computer meant flipping a switch?" bullet
S" you learned how to code from one primary text?" bullet
S" your computer actually CAME with a book at all?" bullet
S" a single reference covered using the OS and hacking the hardware?" bullet
S" you could study the schematics for your computer?" bullet
S" PCs had a healthy ecosystem with hardware and software innovation?" bullet
S" systems programming research wasn't dead?" bullet
S" you could actually explain to a child how the computer worked?" bullet

slide S" Vision" title

S" Imagine a 64-bit Commodore 64, Atari, Apple II, or TRS-80" bullet
S" Philosophy:" bullet
2 left +!
  S" Make it work" bullet
  S" Make it fast at 10MHz" bullet
  S" Performance at 100MHz is automatic; don't worry!" bullet
-2 left +!
S" On/Off switch kills power; no leakage, no shutdown process" bullet
S" A healthy community, respecting all open HW, not just Kestrel" bullet
S" OWNERSHIP of what you pay for.  No EULAs!" bullet
S" Everything documented and available open-source" bullet
S" A computer for the entheusiast, not the media junkie" bullet

slide S" Mission" title

S" Provide a reasonable computer design under an OPEN-SOURCE license" bullet
S" Provide a reasonable set of system software, maintainable by ONE" bullet
2 left +!
  S" STS Kernel: Require less than a man-month to port" bullet
  S" STS Apps: Each should require less than a man-month to port" bullet
  S" Dev tools: Compiler and assembler, each, under 2 months to write" bullet
  S" BIOS: Reusable, portable in less than a man-month" bullet
  S" See a pattern?  Contrast against Linux, BSD" bullet
-2 left +!
S" To the greatest extent that I can, facilitate and foster a community" bullet
S" Do not compete with PCs or mobiles; they fill their niches admirably" bullet

slide S" What About Raspberry Pi?" title

S" Congradulations to RPi team on their epic success!" bullet
S" Huge library of software, reusing ARM-based Linux repos" bullet
S" Growing hardware ecosystem" bullet
S" Super-cheap: priced for education in 3rd world countries" bullet
S" Small: About the size of a 4x6 photograph" bullet
S" I/O: HDMI, USB, ethernet, parallel I/O out of the box" bullet
S" Truly an inspiration to me!" bullet
1 top +!
S" BUT... core chipset is not open source!" bullet
S" RPi survives with only tenuous support from Broadcom" bullet
S" IIRC, HW ecosystem came only after some reverse engineering" bullet
S" Broadcom can, at will, decide to stop production of RPi's chips" bullet
S" It happened once before: vis. Apple and Motorola 68K and 88K" bullet

slide S" Why RISC-V?" title

S" License grants explicit permission to build my own, FOSS CPU" bullet
S" OR, I can use a commercial vendor; lifespan isn't dictated" bullet
S" Flexible hardware implementations; ARM has hardware specs baked in" bullet
S" Instruction set is wide open; ARM requires licensing" bullet
S" License is compatible with Kestrel Project's preferred license" bullet
S" Looking forward to future vector instruction set" bullet
S" Vibrant community surrounding RISC-V!" bullet
S" RISC-V community generally supportive of Kestrel Project" bullet

slide S" State of the Project" title

S" You're CURRENTLY using the Kestrel-3/E emulator" bullet
S" Emulator implements RV64I approved and RV64S subset standards" bullet
S" This slide deck viewer is a 64-bit RISC-V program called Milestone-2" bullet
S" Milestone-2 is running under an OS named STS Version 1.5" bullet
S" 16MB available to programs" bullet
S" STS running under a primitive BIOS" bullet
S" Everything running in Machine-Mode (no User-mode yet)" bullet

slide S" Single Tasking System (STS)" title

S" Operating system that's running right now" bullet
S" System calls include:" bullet
2 left +!
  S"      Memory: getmem fremem movmem setmem zermem" bullet
  S"       Files: open close filsiz read write[1] seek" bullet
  S" Executables: loadseg unloadseg" bullet
  S"   Utilities: strEql strDup strSplitSlash" bullet
  S"     Console: emit type cr space caninp getkey" bullet
  S"   Libraries: fndlib addlib rmvlib getlib rellib" bullet
-2 left +!
S" Comparable to a primitive TRS-DOS or CP/M system" bullet
S" ROM Filesystem done" bullet
S" RAM-Disk and SD card filesystems soon[1]" bullet
1 top +!
S" [1] Not yet implemented due to lack of time." text

slide S" Future of STS (V2.0+) -- PRELIMINARY" title

S" Explore event-driven concurrency model" bullet
2 left +!
  S" Single CPU" bullet
  S" Multiple CPUs" bullet
-2 left +!
S" Explore using a graphical user interface" bullet
2 left +!
  S" Application-centric?" bullet
  S" Document-centric?" bullet
  S" Something else all-together?" bullet
-2 left +!
S" Explore BIOS implications of event-driven concurrency" bullet
S" Explore how to manage jobs" bullet
S" Explore capability-based security" bullet
S" TCP/IP" bullet
S" Vastly more capable command-line shell environment :)" bullet

slide S" Kestrel-3/E Memory Map" title

2 left +!
  S" 0000000000000000 - 0000000000FEFFFF : Program RAM" text  1 top +!
  S" 0000000000FF0000 - 0000000000FFFFFF : MGIA Video RAM" text  1 top +!
  S" 0100000000000000 - 010000000000000F : General purpose I/O (GPIA-II)" text 1 top +!
  S" 0200000000000000 - 0200000000000001 : Keyboard Interface Adapter (KIA-II)" text 1 top +!
  S" 0300000000000000 - 0DFFFFFFFFFFFFFF : unused (traps on access)" text 1 top +!
  S" 0E00000000000000 - 0E00000000000001 : Debug interface to emulator" text 1 top +!
  S" 0F00000000000000 - 0F000000000FFFFF : ROM BIOS" text 1 top +!
  S" 1000000000000000 - EFFFFFFFFFFFFFFF : Reserved for hardware expansion" text 1 top +!
  S" F000000000000000 - FFFFFFFFFFFFFFFF : Mirrors $00xxx..$0Fxxx" text
-2 left +!  1 top +!

slide S" Kestrel-3/1 Memory Map (PRELIMINARY)" title

2 left +!
  S" 0000000000000000 - 0000000000FFFFFF : Program/CGIA RAM" text  1 top +!
  S" 0100000000000000 - 010000000000007F : GPIA-III PIC Read/Write Bits" text  1 top +!
  S" 0100000000000080 - 01000000000000FF : GPIA-III PIC Set Bits" text  1 top +!
  S" 0100000000000100 - 010000000000017F : GPIA-III PIC Clear Bits" text  1 top +!
  S" 0100000000002000 - 0100000000003FFF : GPIA-III PIC Configuration" text  1 top +!
  S" 0200000000000000 - 0200000000000001 : Keyboard Interface Adapter (KIA-II)" text 1 top +!
  S" 0300000000000000 - 0300000000000FFF : Config. Graphics Adapter (CGIA)" text 1 top +!
  S" 0400000000000000 - 0EFFFFFFFFFFFFFF : unused (traps on access)" text 1 top +!
  S" 0F00000000000000 - 0F000000000FFFFF : ROM BIOS" text 1 top +!
  S" 1000000000000000 - EFFFFFFFFFFFFFFF : Reserved for hardware expansion" text 1 top +!
  S" F000000000000000 - FFFFFFFFFFFFFFFF : Mirrors $00xxx..$0Fxxx" text
-2 left +!  2 top +!
S" GPIA-III basically an enhanced BERI Programmable Interrupt Controller." bullet
S"   See https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-852.pdf" text 1 top +!
S" Layout changed so GPIA-III backward compatible with GPIA-II." bullet

slide S" Kestrel-3/E Memory Map (con't)" title

S" Kestrel-3 design anticipates an expansion backplane at some point" bullet
1 top +!
S" Bits 63..60 addresses specific slot." bullet
S" Bits 59..56 addresses specific device on that slot's card." bullet
S" All other bits are device dependent." bullet
S" Slots 0 and 15 explicitly address the current card" bullet
2 left +!
  S" Some CPUs, like Z-80 and some RV, boots from address $0000" bullet
  S" Some CPUs, like 6502 and my RV, boots from address $FFF..." bullet
  S" With slot 0 == slot 15, I/O bus doesn't care which you use" bullet
-2 left +!
S" Turns out this was fortuitous, as it plays nicely with RapidIO" bullet

slide S" Documentation" title

S" It's currently somewhat out of date; but," bullet
S"   You can find it at https://leanpub.com/k3ug" text
2 top +!
S" How to download and install the emulator" bullet
S" How to use the machine-language monitor" bullet
S" How to use STS at a basic level of competency" bullet
S" Documents STS system calls" bullet
S" More will be coming" bullet
S" And, of course, the blog at the project website" bullet

slide S" Personal Applications" title

S" Some thoughts on what I'd use a Kestrel-3 for include," text 1 top +!
S" but isn't limited to," text 2 top +!
S" Amateur radio" bullet
2 left +!
  S" Solar-powered, always on, AX.25 packet radio station" bullet
  S" Freespace optical packet links" bullet
-2 left +!
S" Supporting open hardware communities" bullet
2 left +!
  S" Already had requests for using Kestrel for 3D printing" bullet
  S" Last year, was asked if Kestrel can be used for teaching" bullet
  S" Reciprocating technology back to the RISC-V community" bullet
-2 left +!
S" Business Automation (if it comes to it)" bullet
2 left +!
  S" If this results in a business, eat my own dogfood" bullet
  S" Word processing" bullet
  S" Desktop publishing"
  S" Spreadsheet" bullet
  S" Slideshow software (Milestone-2)" bullet
-2 left +!

slide S" What would you do with a Kestrel-3?" title

S" Thank you for taking this tour!" bullet

S" Please press 1 to return the deck to the beginning." bullet
1 top +!
S" Remember, you can always contact me at:" bullet
2 left +!  1 top +!
  S" E-mail: kc5tja@arrl.net" text   1 top +!
  S"    Web: https://kestrelproject.github.io/kestrel" text

end done

out" slides.bin"
\ To make the final binary, do the following script:
\ 
\ $ gforth asm.fs sdimage.fs				( compile Milestone 2 executable )
\ $ gforth slide-asm.fs slides.fs			( compile slides )
\ $ dd if=slides.bin of=sd.bin bs=1024 count=4 seek=8	( embed slide data into binary image )
\ $ sudo cp sd.bin /dev/sdi				( write blocks to SD card )
\ $ sync						( verify Linux flushes buffers )
\ 
\ The iamge should then boot on any Kestrel with the Milestone-3 bootstrap image.

