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

include framebuffer.fs
include font.fs
include cursor.fs
include tty.fs

\ Main entry point.

:, clr		0 #, Left !,
			0 #, Right !,
			#ch/row Right !,
			#rows Bottom !,
			BlackRect ;,

:, hellos	char H #, chr c!, PrintCh
			char e #, chr c!, PrintCh
			char l #, chr c!, PrintCh PrintCh
			char o #, chr c!, PrintCh
			32 #, chr c!, PrintCh again, ;,

:, reset	0cursor 0tty ;,
:, ep		reset clr home hellos ;,

' ep >body @ is, entry-point