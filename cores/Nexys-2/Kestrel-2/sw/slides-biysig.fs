program progmem.ram10
start slide

36 left !  7 top ! S" Kestrel-2" text
22 left !  8 top ! S" Home-Made Computer Built From Scratch" text
31 left ! 10 top ! S" Samuel A. Falvo II" text
35 left ! 11 top ! S" 2013-Jan-07" text

slide S" Vision" title

15 left !  7 top ! S" Restore trust, transparency, elegance, robustness," text
           8 top ! S" and fun in home computer design." text

slide S" Untrustworthy" title

2 left ! 3 top ! S" Windows 8 Secure Boot Would 'Exclude' Linux" text
4 left ! 4 top ! S" http://www.theregister.co.uk/2011/09/21/" text
         5 top ! S" secure_boot_firmware_linux_exclusion_fears/" text

2 left ! 7 top ! S" Intel wants to charge $50 to unlock stuff your CPU can already do" text
4 left ! 8 top ! S" http://www.engadget.com/2010/09/18/" text
         9 top ! S" intel-wants-to-charge-50-to-unlock-stuff-your-cpu-can-already-d/" text

slide S" Opacity" title
2 left ! 3 top ! S" Lack of Broadcom documentation" text
4 left ! 4 top ! s" http://www.raspberrypi.org/phpBB3/viewtopic.php?f=9&t=1313" text

2 left ! 6 top ! S" Linux Device Drivers, 2nd Edition" text
4 left ! 7 top ! s" http://www.xml.com/ldd/chapter/book/" text

2 left ! 9 top ! S" Opaque Documentation (Forum Post)" text
4 left ! 10 top ! s" http://www.velocityreviews.com/forums/t350824-opaque-documentation.html" text

slide S" Clumsiness" title
2 left ! 3 top ! S" Misc. Linux Questions" text
4 left ! 4 top ! S" http://braid-game.com/news/2008/08/misc-linux-questions/" text

2 left ! 6 top ! S" I Hate Linux Graphics" text
4 left ! 7 top ! S" http://linuxhaters.blogspot.com/2008/06/" text
         8 top ! S" nitty-gritty-shit-on-open-source.html" text

slide S" Fragility" title
2 left ! 3 top ! s" Smart ship testbed (USS Yorktown (CG-48))" text
4 left ! 4 top ! s" http://en.wikipedia.org/wiki/USS_Yorktown_%28CG-48%29" text

2 left ! 6 top ! s" Automobile computer systems successfully hacked" text
4 left ! 7 top ! s" http://www.gizmag.com/vehicle-computer-systems-hacks/15156/" text

slide S" Just Plain Not Fun Anymore" title
2 left ! 3 top ! S" Programming Isn't Fun Any More" text
4 left ! 4 top ! S" http://www.neophilic.com/b2evo/blogs/blog4.php/2011/09/02/" text
         5 top ! S" programming-isnt-fun-any-more" text

slide S" Mission" title
7 left ! 7 top ! S" Employ the simplicity of Forth software and hardware to demonstrate" text
         8 top ! S" a working alternative." text

slide S" Trustworthy" title
S" No pecuniary interests involved." bullet
S" Open source rules apply." bullet
S" Forth strongly encourages formal verification and testing." bullet
S" Meritocracy" bullet
S" MMU and 'real OS' coming eventually." bullet

slide S" Transparency" title
S" Everything hosted on http://bitbucket.org/kc5tja/kestrel" bullet
S" 'Hardware' Datasheets (available now)" bullet
S" Tutorials (eventually)" bullet
S" References (eventually)" bullet
S" App-notes (eventually)" bullet
S" and more to come..." bullet

slide S" Elegance" title
S" S16X4 Microprocessor Programming Model" bullet
S" No interrupts or pipeline." bullet
S" 3-Deep, 16-Bit Data Stack" bullet
S" 15-Bit Program Counter (boots to $0000)" bullet
S" 12 Opcodes, packed four wide per instruction word:" bullet

2 left !
 9 top ! S"         --00    --01    --10    --11" text
10 top ! S" 00--    NOP     #       @       !" text
11 top ! S" 01--    +       AND     XOR     ZGO" text
12 top ! S" 10--                    C@      C!" text
13 top ! S" 11--                    GO      NZGO" text

slide S" Robustness" title
S" No types.  No runtime.  No frameworks.  Just two stacks and your brain." bullet
S" Rely heavily upon formal verification." bullet
S" Rely heavily upon test-driven development." bullet
S" Formal methods and tests compliment each other." bullet

slide S" Fun" title
28 left ! 7 top ! S" Man days, not man months." text
34 left ! 9 top ! S" Zero budget." text

slide S" But, . . ." title
30 left ! 7 top ! S" Enough about Forth!" text

slide S" S16X4 Microprocessor" title

slide S" Memory Map" title
14 left !
 7 top ! S" 0000-3FFF	RAM 0 (16K; installed) \" text
 8 top ! S" 4000-7FFF	RAM 1 (16K; expansion)  > 44KB contiguous" text
 9 top ! S" 8000-AFFF	RAM 2 (12K; expansion) /" text
10 top ! S" B000-BFFF	I/O Resources" text
11 top ! S" C000-FFFF	RAM 3 (16K; MGIA frame buffer)" text

slide S" Keyboard Interface Adapter" title
13 left !
 7 top ! S"                    +---+---+---+---+---+---+---+---+" text
 8 top ! S" $B000  R/O KQSTAT  | 0 | 0 | 0 | 0 | 0 | 0 | F | E |" text
 9 top ! S"                    +---+---+---+---+---+---+---+---+" text
10 top ! S" $B002  R/O KQDATA  |            data byte          |" text
11 top ! S"                    +---+---+---+---+---+---+---+---+" text
12 top ! S" $B002  W/O KQPOP   | - | - | - | - | - | - | - | - |" text
13 top ! S"                    +---+---+---+---+---+---+---+---+" text

slide S" Monochrome Graphics Interface Adapter" title
S" 640x200 Bitmapped Graphics" bullet
S" Black and White" bullet
S" Zero Configuration" bullet
S" No frills." bullet

slide S" General Purpose Interface Adapter" title
13 left !
 7 top ! S"                     \---+-----+------+----+-----+" text
 8 top ! S" $B010  R/O  GPIP    / 0 |  0  | MISO | CD | WP  |" text
 9 top ! S"                     \---+-----+------+----+-----+" text
10 top ! S" $B012  R/W  GPOP    / 0 | CLK | MOSI | CS | LED |" text
11 top ! S"                     \---+-----+------+----+-----+" text

slide S" Future Directions" title
13 left !
 7 top ! S" *** KESTREL FORTH SYSTEM 1 V1" text
 9 top ! S" OK" text
10 top ! S" CR .( Hello World!)" text
11 top ! S" Hello World!" text
12 top ! S" OK" text
13 top ! S" _" text

slide S" The End" title
S" Q&A" bullet

end done
out" slides.bin"

