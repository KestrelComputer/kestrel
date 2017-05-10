start slide

29 left !  7 top ! S" Flight of the Kestrel-2" text
31 left !  9 top ! S" Samuel A. Falvo II" text
35 left ! 10 top ! S" 2013-Nov-16" text

slide S" When We Last Saw The Kestrel-2 . . ." title

S" CPU: 16-bit S16X4 (Steamer16 superset)" bullet
S" Program memory: 16KB" bullet
S" Video: Monochrome, bitmapped graphics only" bullet
S" Video memory: 16KB" bullet
S" PS/2 keyboard interface" bullet
1 top +!
S" No subroutine call instruction!" bullet
S" No interrupts!" bullet
S" Software always ran on bare metal." bullet

slide
28 left !  8 top ! S" And now, the continuation" text
28 left ! 10 top ! S" of the Kestrel-2 Project." text

slide S" Forth Casualty" title

S" Indirect-threaded as a means to work around lack of CALL instruction." bullet
S" Tried keeping names very short to fit in available memory space." bullet
S" Single dictionary chain for immediate, non-immediate words." bullet
S" Over 10KB just to get line of input, parse words, and print them." bullet
S" 7KB for font, console I/O alone." bullet
2 left +!
  S" 2KB for font." bullet
  S" Roughly 2KB for glyph painting, basic terminal emulation." bullet
  S" Roughly 3KB for keyboard look-up tables, driver, line editor." bullet
-2 left +!
S" Clearly not enough memory to finish compiler, editor, BLOCKs, etc." bullet
S" Maybe, an OS can help by managing resources more directly?" bullet
S" (It seemend to work for IBM back in 1960s!)" bullet

slide S" Single Tasking System" title

S" A very simple operating system inspired somewhat by BOS/360, CP/M, Tripos" bullet
S" Kernel memory budget: 8KB.  Actual memory used to date: 4.5KB" bullet
S" Sectors 0, 1 bootstraps kernel in sectors 2 through 15." bullet
S" Filing system API supports read operations only." bullet
S" Guarantees safety during OS development." bullet
S" Use explicitly loaded library to write to or update files." bullet
S" Single address space; no memory protection." bullet
S" Prgs must free memory, unload segments before exiting." bullet

slide S" STS Versions" title

S" STS V1.0 for 16KB Kestrel-2" bullet
S" 16KB STILL not enough to load some programs from shell!" bullet
S" Both Forth and STS experience leads to one conclusion: 32KB required" bullet
S" STS V1.1 for 32KB Kestrel-2" bullet

slide S" STS System Calls" title
S" Filesystem: open, close, read, seekblk" bullet
S" Memory: getmem, fremem" bullet
S" Programs: loadseg, unloadseg, exec, exit. (period part of name)" bullet

slide S" Entrypoint Vectors" title
2 left +!
S" $0400 origin" text                   1 top +!
S" ..." text                            1 top +!
S" defer, coldstart" text               1 top +!
S" ..." text                            1 top +!
S" defer, getmem-epv" text              1 top +!
S" defer, relmem-epv" text              1 top +!
S" defer, open-epv" text                1 top +!
S" defer, close-epv" text               1 top +!
S" defer, read-epv" text                1 top +!
S" defer, loadseg-epv" text             1 top +!
S" defer, unloadseg-epv" text           1 top +!
S" defer, exec-epv" text                1 top +!
S" ..." text                            1 top +!
-2 left +!

slide S" SD Card Compatibility" title
S" STS mounts SD card at boot-time only." bullet
S" STS V1.1 will not reinitialize SD card after removal, insertion." bullet
S" `remount' command needs to be internal to STS shell if/when implemented." bullet
S" After removal, SD card access deadlocks, since SD card isn't initialized." bullet
S" Treat SD card like harddrive!" bullet
S" Detecting SD card insertions requires interrupts." bullet

slide S" Filesystem Overview" title
S" A Typical filename:" bullet
1 top +!
S" SYS:prefix.prefix.name" text 1 top +!
S" --- ------------- ----" text 1 top +!
S"  |        |         |" text 1 top +!
S"  |        |         +--- Name of the data set." text 1 top +!
S"  |        +------------- One or more prefixes scoping the data set." text 1 top +!
S"  +---------------------- Volume on which dataset may be found." text 1 top +!

slide S" Filesystem Details (1/3)" title
S" Volume Table of Contents = flat directory." bullet
S" VTOC starts on sector 16." bullet
S" Typical Directory Entry (64 bytes)" bullet
1 top +!
S" +-----+-------------------------------------+" text 1 top +!
S" | Len | Filename (1 <= length <= Len <= 47) |" text 1 top +!
S" +-----+-----+-----+-------------------------+" text 1 top +!
S" | Typ | Fst | Lst | /////////////////////// |" text 1 top +!
S" +-----+-----+-----+-------------------------+" text 1 top +!
S"          |     |" text 1 top +!
S"          |     +--- Last sector of the dataset (>= Fst)" text 1 top +!
S"          +--------- First sector of the dataset" text 1 top +!

slide S" Filesystem Details (2/3)" title
S" 0002000: 0424 4449 52cc cccc cccc cccc cccc cccc  .$DIR..........." text 1 top +!
S" 0002010: cccc cccc cccc cccc cccc cccc cccc cccc  ................" text 1 top +!
S" 0002020: cccc cccc cccc cccc cccc cccc cccc cccc  ................" text 1 top +!
S" 0002030: 0100 1000 1700 0000 0000 0000 0000 0000  ................" text 1 top +!
S" 0002040: 0857 6f72 6b44 6973 6bcc cccc cccc cccc  .WorkDisk......." text 1 top +!
S" 0002050: cccc cccc cccc cccc cccc cccc cccc cccc  ................" text 1 top +!
S" 0002060: cccc cccc cccc cccc cccc cccc cccc cccc  ................" text 1 top +!
S" 0002070: 0200 0000 0000 0000 0000 0000 0000 0000  ................" text 1 top +!
S"         .        .        .        .        .        ." text 1 top +!
S" 00021c0: 0670 7267 2e6d 32cc cccc cccc cccc cccc  .prg.m2........." text 1 top +!
S" 00021d0: cccc cccc cccc cccc cccc cccc cccc cccc  ................" text 1 top +!
S" 00021e0: cccc cccc cccc cccc cccc cccc cccc cccc  ................" text 1 top +!
S" 00021f0: 0100 5800 6300 0000 0000 0000 0000 0000  ..X.c..........." text 1 top +!

slide S" Filesystem Details (3/3)" title
S" Prefix system inspired by OS/360." bullet
S" prg.app files: programs invoked from STS shell." bullet
S" lib.xxx files: libraries." bullet
S" app.xxx files: data or executable files belonging to application APP." bullet
S" Case sensitive!" bullet
S" SYS: versus VolumeName:" bullet

slide S" Kestrel-2 Today: Dream vs. Reality" title
S" Dream       -----------------------------+" text 1 top +!
S" Today       --------------------+        |" text 1 top +!
S" Last Year   -----------+        |        |" text 1 top +!
S"                        |        |        |" text 1 top +!
S" +------------------+-------+--------+--------+" text 1 top +!
S" | CPU              | S16X4 | S16X4A | S16X4A |" text 1 top +!
S" | RAM              |  16KB |  32KB  |  32KB  |" text 1 top +!
S" | Working OS       |  n/a  |   STS  |  Forth |" text 1 top +!
S" | Interrupts       |   N   |    N   |    Y   |" text 1 top +!
S" | Auto Remount     |  n/a  |    N   |    Y   |" text 1 top +!
S" | VSYNC            |   N   |    N   |    Y   |" text 1 top +!
S" | Timers           |   N   |    N   |    Y   |" text 1 top +!
S" +------------------+-------+--------+--------+" text 1 top +!

slide S" S16X4A: New Instructions" title
S" Two new instructions:" bullet
S" Opcode $C: LCALL (+/- 4KB from current PC; slot 1 only)." bullet
S" Opcode $D: ICALL (anywhere)." bullet
S" Both leave return address in Z on entry to subroutine." bullet
1 top +!
S"      S16X4          ------S16X4A------" text 1 top +!
S"    (6 bytes)     (4 bytes)     (2 bytes)" text 1 top +!
S" +-------------+-------------+----------------+" text 1 top +!
S" | LI retnAddr | LI subrAddr | LCALL subrAddr |" text 1 top +!
S" | LI subrAddr | ICALL       |                |" text 1 top +!
S" | GO          |             |                |" text 1 top +!
S" +-------------+-------------+----------------+" text 1 top +!

slide S" S16X4A: New Signals" title
S" ABORT_I signal, when asserted externally, stops CPU from updating regs." bullet
S" Used by external debugging and/or memory management unit hardware." bullet
S" ABORT_I also FORCES instruction fetch in next cycle, guaranteed." bullet
S" MMU traps instruction PC using VPA, VDA signals." bullet
S" Not used for Kestrel-2, but will be for Kestrel-3 development." bullet

slide S" S16X4A: Interrupt Injection Support" title
S" S16X4(A) always qualifies each bus cycle with VDA_O, VPA_O" bullet
S" Assume bus control if VDA=0, VPA=1 to inject LI/ICALL to handler" bullet
1 top +!
S" +-----+-----+---------------------------+" text 1 top +!
S" | VDA | VPA | Cycle Type                |" text 1 top +!
S" +-----+-----+---------------------------+" text 1 top +!
S" |  0  |  0  | Idle or internal cycle    |" text 1 top +!
S" |  0  |  1  | Instruction word fetch    |" text 1 top +!
S" |  1  |  0  | Data word access          |" text 1 top +!
S" |  1  |  1  | Instruction operand fetch |" text 1 top +!
S" +-----+-----+---------------------------+" text 1 top +!

slide S" Kestrel-2 Future Interrupt Sources" title
S" VSYNC" bullet
S" Raster compare" bullet
S" Keyboard" bullet
S" Programmable timers" bullet
S" A push-button (a la Commodore 64's RESTORE key)" bullet
S" SD card insertion detection" bullet

slide S" Future Directions" title
S" Kestrel-3 work already in flight" bullet
S" Change of strategy: Evolution, not Revolution" bullet
S" Kestrel-2 will continue to evolve too!" bullet
S" All new website with better curation on the way" bullet
S" New blog" bullet

slide S" Websites of Interest" title
S" http://sam-falvo.github.io" bullet
S" http://sam-falvo.github.io/kestrel (not yet, but eventually)" bullet
S" https://github.com/sam-falvo/kestrel" bullet

slide S" Fin" title
S" Q & A" bullet

end done
out" sts/imgs/m2.slides"

