\ Basic Input/Output System for Kestrel-2
\ Built for S16X4 microprocessor, 16KiB RAM system.

defer, entry-point

\ Frame Buffer Control Block.

$C000 const, bitplane
   80 const, #ch/row
   25 const, #rows
    8 const, #px/row

create, mt/rows		( multiplication table for character row offsets in the bitplane )
  0 ,, 640 ,, 1280 ,, 1920 ,, 2560 ,, 3200 ,, 3840 ,, 4480 ,,
  5120 ,, 5760 ,, 6400 ,, 7040 ,, 7680 ,, 8320 ,, 8960 ,, 9600 ,,
  10240 ,, 10880 ,, 11520 ,, 12160 ,, 12800 ,, 13440 ,, 14080 ,, 14720 ,,
  15360 ,,

create, mt/px		( multiplication table for pixel row offsets within a single row )
  0 ,, 80 ,, 160 ,, 240 ,, 320 ,, 400 ,, 480 ,, 560 ,,

\ State needed by modules referenced below.

int, x
int, y
int, y'
int, chr
int, Glyph
int, Stride
int, ToLeft
int, ToTop
int, Left
int, Top
int, Right
int, Bottom
int, ErrFlag
int, w
int, p
int, q
int, r
int, strp
int, strl
int, #ib
int, ckey
int, shiftst
char, ps2code

$FF00 const, ib
256 const, /ib

include framebuffer.fs
include font.fs
include cursor.fs
include tty.fs

$B000 const, kqstat
$B002 const, kqdata

:, waitps2	kqstat c@, 1 #, and, if, again, then, ;,
:, ackps2	kqdata c!, ;,
:, headps2	kqdata c@, ps2code c!, ;,

include keyboard.fs
include cli.fs

\ Main entry point.

:, clr		0 #, Left !,
			0 #, Right !,
			#ch/row Right !,
			#rows Bottom !,
			BlackRect ;,

create, rdymsg
	char R c,, char e c,, char a c,, char d c,, char y c,, char . c,,
6 const, /rdymsg

:, rdy		rdymsg strp !,  /rdymsg strl !, PrintStr .cr ;,
:, reset	0cursor 0tty 0keyboard ;,
:, spc		32 #, chr c!, PrintCh ;,
:, prompt	char > #, chr c!, PrintCh spc ;,
:, lines	prompt accept .cr again, ;,
:, ep		reset clr home rdy lines ;,

' ep >body @ is, entry-point