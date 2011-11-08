create buffer   16384 allot

\ Read the romfile into the buffer.

variable romfileHandle
: name          S" romfile" ;
: openRomFile   name r/o open-file throw romfileHandle ! ;
: closeRomFile  romfileHandle @ close-file throw ;
: readRomFile   openRomFile  buffer 16384 romfileHandle @ read-file throw drop closeRomFile ;
readRomFile

\ Create a hex dump of a single 32-byte run.  The format of the dump
\ is opposite most memory dumps -- most significant byte first.  Verilog
\ treats the value as a 256-bit integer, hence the weirdness.

: .byte     s>d hex <# # # #> type ;
: by         1- dup c@ .byte ;
: 8by        by by by by  by by by by ;
: run       ." 256'h" 32 + 8by 8by 8by 8by ;

\ Having that, we can dump the contents of a 2KB section of the ROM image.

variable ctr
variable unitLow
variable unitHigh

: indent    ."     " ;
: module    ." pm" ;
: dash      ." -" ;
: unit      ." ram" unitLow @ .byte dash unitHigh @ .byte ;
: init      ." INIT_" ctr @ .byte ;
: dot       ." ." ;
: comma     ." ," ;
: semi      ." ;" ;
: .run      indent module dot unit dot init ."  = " ;
: r         .run run comma cr  32 +  1 ctr +! ;
: r;        .run run semi  cr  32 +  1 ctr +! ;
: 8r        r r r r  r r r r ;
: 8r;       r r r r  r r r r; ;
: 2k        0 ctr !  ." defparam" cr 8r 8r 8r 8r  8r 8r 8r 8r;  8 unitLow +!  8 unitHigh +! ;

\ Now that we have the ability to render a 2K chunk, we can compose this
\ to get the 16K image we need.

: 16k       cr 0 unitLow ! 7 unitHigh ! 2k 2k 2k 2k  2k 2k 2k 2k drop ;

\ Finally, let's just convert from romfile to our defparam chunks on stdout, and end
\ the program there.  Let the user cut and paste the results into the verilog file.

buffer 16k bye

