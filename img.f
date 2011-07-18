include asm.f
0symtab
0 org target

0 [if]  The J1 program counter starts at $0000 after reset.  Therefore, we
        need a vector to our actual system software entry point.
[then]

defer _main

0 [if]  The J1's @ instruction is too fast for use with synchronous RAM
        blocks in the Xilinx FPGA.  The synchronous RAM introduces a one-
        cycle latency to the data.  Fortunately, wrapping the @ instruction
        inside a subroutine introduces a one-cycle latency in software.
[then]

: @     @, ;

0 [if]  A text buffer comprises a matrix of character glyphs.  An octet
        identifies each glyph, providing up to 256 glyphs in a font.  With
        each glyph consuming 8 bits horizontally and 8 rows on the screen,
        a font consumes 2KiB of ROM allotment.
[then]

create  font
include font.inc

0 [if]  The J1/Ace provides a bitmapped, 640x200, monochrome display.
        With each glyph of a textual display consuming eight pixels, we
        have enough space for 80 columns of text.  With eight pixel tall
        glyphs, we have enough vertical space for 25 rows of text.  Thus,
        a text buffer consumes 2000 octets of memory, while the bitmapped
        display consumes 16000 octets.

        The video display in J1/Ace is hard-wired to appear at $8000.
[then]


: -1        $FFFF ;
: cyc       dup if -1 + recurse exit then drop ;
: 64kcyc    dup if -1 + $FFFF cyc recurse exit then drop ;
: 1sec      8 64kcyc ;
: c@        dup 1 and if @ 255 and exit then @ 8 rshift 255 and ;
: even!     swap 8 lshift over @ 255 and or swap ! ;
: odd!      swap 255 and over @ $FF00 and or swap ! ;
: c!        dup 1 and if odd! exit then even! ;
: r         over c@ over c! 80 + swap 256 + swap ;
: plch      font + $8000 r r r r r r r r 2drop ;
: pl        plch 1sec ;
: chrs      dup 256 xor if dup pl 1 + recurse exit then drop ;
: main      35 chrs recurse ;

0 [if]  Having defined the system software, we now point the J1's boot
        vector to our entry point.
[then]

' main is _main

0 [if]  Create the ROM file, to be used by both the emulator and the Verilog
        J1/Ace circuit description.
[then]

host
romfile
bye

