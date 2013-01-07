program progmem.ram10
start slide

31 left !  7 top ! S" MILESTONE-2 Update" text
28 left !  8 top ! S" Bootstrapped from SD Card" text
31 left ! 10 top ! S" Samuel A. Falvo II" text
35 left ! 11 top ! S" 2012-Dec-15" text

slide S" Bootstrap Pseudocode" title

S" On power-on, initialize the SD card." bullet
S" If card is not present, produce SD card icon and wait." bullet
S" If card is present, blank the screen and try to initialize the card." bullet
S" If card cannot be initialized, produce SD ``X'' icon, and wait." bullet
S" If card initializes OK, load first 1024 bytes into address $3C00." bullet
S" Jump to $3C00." bullet

slide S" Inside the Boot Block" title

S" Set up a loop to read in 15 more blocks, starting at $0400." bullet
S" Code placed at $0400 is also assembled for address $0400." bullet
S" Be careful not to load so much that you overwrite your bootstrap!" bullet
S" When done, jump to $0400." bullet

slide S" Changes to Milestone-2" title

S" Moved SDA origin pointer to $4000." bullet
S" You'll now find the slide-deck table of contents at block 16." bullet
S" ``start'' now reads TOC at block 16, then desired slide at block N+16." bullet
S" Slide assembler now places each slide at block boundaries." bullet
S" With SDSC cards, this means I can show 64 slides." bullet

slide S" Performance" title

S" SD card throughput is just about 50kbps." bullet
S" 2.1 times faster than Commodore 128 / 1571 Burst Mode speed." bullet
S" Changing a `3' to `1' in delay loop grants 150kbps: CD-ROM x1 speed!" bullet

slide S" Timing Diagrams" title

\  0123456789012345678901234567890123456789012345678901234567890123456789"
S"       ____                                                   _________" bullet
S" CS#       \_________________________________________________/" bullet
S"            _________________________________________________" bullet
S" LED   ____/                                                 \_________" bullet
S"       ________________________________________________________________" bullet
S" MOSI         \_ cmd _/" bullet
S"       ________________________________________________________________" bullet
S" MISO  _____/___/        \_ R1 _/   \________ DATA ________/" bullet

slide S" Next Steps" title

S" Subroutine CALL instruction to +/- 2KiB relative to PC" bullet
S" Programmable Interval Timers" bullet
S" CPU-external Return Stack Unit" bullet
S" 32KB RAM expansion" bullet
S" Interrupts?" bullet

slide S" ok" title

S" Fin." bullet
S" Q & A" bullet
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

