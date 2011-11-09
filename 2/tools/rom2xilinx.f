16384 constant /buffer
create buffer   /buffer allot

\ Read the romfile into the buffer.

variable romfileHandle
: name          S" romfile" ;
: openRomFile   name r/o open-file throw romfileHandle ! ;
: closeRomFile  romfileHandle @ close-file throw ;
: readRomFile   openRomFile  buffer /buffer romfileHandle @ read-file throw drop closeRomFile ;
readRomFile

\ If we create a simple byte dump of our buffer, we will find ourselves
\ executing bad code.  This is because the Xilinx products interprets its
\ initialization vectors for 16-bit wide memories in chunks of 16 bits.
\ However, if you do a dumb dump of the freshly filled buffer, you'll find
\ that we need to swap even and odd bytes throughout the buffer in order
\ for the RAM's initialization to make any kind of sense.

: swapb         >r r@ c@ r@ 1+ c@ r@ c! r@ 1+ c! r> ;
: -end          dup buffer /buffer + u< if exit then r> drop ;
: swapAll       begin -end swapb 2 + again ;
: swapBytes     buffer swapAll drop ;
swapBytes

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
: uscr      ." _" ;
: unit      ." ram" unitLow @ .byte uscr unitHigh @ .byte ;
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

