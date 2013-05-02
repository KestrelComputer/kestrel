\ Bootstrap entry point.  The DEFER must always be the first thing compiled.
defer, entry-point

\ Not technically part of the CMD, but useful for Kestrel-specific testing.
$C000 16000 + const, gap

\ Character Map Descriptor Accessors
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


\ Framebuffer Control Block Locators
\ 
\ Private fields included so that the code can be re-used in an environment
\ with more than one FBCB structure.  In this case, you'd have a variable
\ that pointed to the current FBCB, and accessors defined as follows:
\ 
\ int, current_fbcb
\ : Left   current_fbcb @ ;
\ : Top    current_fbcb @ cell+ ;
\ : Right  current_fbcb @ [ 2 cells ] literal + ;
\ 
\ and so on.
int, ToLeft
int, ToTop
int, Left
int, Top
int, Right
int, Bottom
int, Glyph
int, Stride
int, ErrFlag
  ( Private state )
int, p			( general memory pointer )
int, q			( general memory pointer )
int, w			( width counter )
int, y			( current row counter )
int, y'			( alternate row counter )
int, r			( current raster counter )


\ Module Under Test
pibptr @
include framebuffer.fs
pibptr @ swap - . .( bytes in module compiled) cr


\ Re-used and useful phrases
:, incp		p @, 2 #, +, p !, ;,


\ Unit Testing Support
int, test

:, halt		again, ;,
:, testid	test @, $C000 #, !,  test @, -1 #, xor, $C050 #, !, $1111 #, $C0A0 #, !, ;,
:, (cls0)	p @, if, 0 #, p @, !, incp again, then, ;,
:, cls		bitplane p !, (cls0) ;,
:, fail		cls testid halt ;,

\ Edge case negative tests (remaining tests serve as positive tests)

:, =AAAA	p @, @, $AAAA #, xor, if, fail then, ;,
:, (scrAA)	p @, gap xor, if, =AAAA incp again, then, ;,
:, (scr00)	p @, gap xor, if, p @, @, if, fail then, incp again, then, ;,
:, (scr55)	p @, gap xor, if, p @, @, $5555 #, xor, if, fail then, incp again, then, ;,
:, (gap0)	p @, if, =AAAA incp again, then, ;,
:, scrAA	bitplane p !, (scrAA) ;,
:, scr00	bitplane p !, (scr00) ;,
:, scr55	bitplane p !, (scr55) ;,
:, gapAA	gap p !, (gap0) ;,
:, (setup0)	p @, if, $AAAA #, p @, !, incp again, then, ;,
:, setup	bitplane p !, (setup0) ;,

:, t		if, scrAA gapAA exit, then, fail ;,
:, t10		$0017 #, test !,  setup 0 #, Left !, #rows Top !, #ch/row Right !, #rows -1 #, +, Bottom !,  BlackRect  ErrFlag @, $20 #, and, t ;,
:, t20		$0037 #, test !,  setup 0 #, Left !, 0 #, Top !, #ch/row Right !, #rows 1 #, +, Bottom !,  BlackRect  ErrFlag @, $10 #, and, t ;,
:, t30		$0027 #, test !,  setup 0 #, Left !, #rows 1 #, +, Top !, #ch/row Right !, #rows Bottom !,  BlackRect  ErrFlag @, $08 #, and, t ;,
:, t40		$0047 #, test !,  setup #ch/row Left !, 0 #, Top !, #ch/row -1 #, +, Right !, #rows Bottom !, BlackRect  ErrFlag @, $04 #, and, t ;,
:, t50		$0057 #, test !,  setup 0 #, Left !, 0 #, Top !, #ch/row 1 #, +, Right !,  #rows Bottom !,  BlackRect  ErrFlag @, $02 #, and, t ;,
:, t60		$0067 #, test !,  setup #ch/row 1 #, +, Left !, 0 #, Top !, #ch/row Right !,  #rows Bottom !,  BlackRect  ErrFlag @, $01 #, and, t ;,

\ Zero-width tests

:, noerr	ErrFlag @, if, ErrFlag @, $C00A #, !, ErrFlag @, -1 #, xor, $C05A #, !, fail then, ;,
:, t		noerr scrAA gapAA ;,
:, t100		$0107 #, test !,  setup  0 #, Left !,  0 #, Top !,  0 #, Right !,  #rows Bottom !,  BlackRect  t ;,
:, t110		$0117 #, test !,  setup  10 #, Left !, 0 #, Top !,  10 #, Right !, #rows Bottom !,  BlackRect  t ;,
:, t120		$0127 #, test !,  setup  #ch/row Left !,  0 #, Top !,  #ch/row Right !,  #rows Bottom !,  BlackRect  t ;,

\ Zero-height tests
:, t200		$0207 #, test !,  setup  0 #, Left !,  0 #, Top !,  #ch/row Right !,  0 #, Bottom !,  BlackRect  t ;,
:, t210		$0217 #, test !,  setup  0 #, Left !, 10 #, Top !,  #ch/row Right !,  10 #, Bottom !,  BlackRect  t ;,
:, t220		$0227 #, test !,  setup  0 #, Left !, #rows Top !,  #ch/row Right !,  #rows Bottom !,  BlackRect  t ;,

\ Positive tests
:, 1glyph00	$C000 #, @, $00AA #, xor, if, fail then,		( only a single glyph should be cleared )
                $C050 #, @, $00AA #, xor, if, fail then,
                $C0A0 #, @, $00AA #, xor, if, fail then,
                $C0F0 #, @, $00AA #, xor, if, fail then,
                $C140 #, @, $00AA #, xor, if, fail then,
                $C190 #, @, $00AA #, xor, if, fail then,
                $C1E0 #, @, $00AA #, xor, if, fail then,
                $C230 #, @, $00AA #, xor, if, fail then, ;,

:, t300		$0307 #, test !,  setup  0 #, Left !,  0 #, Top !,  1 #, Right !,  1 #, Bottom !,  BlackRect  noerr 1glyph00 gapAA ;,
:, t310		$0317 #, test !,  setup  0 #, Left !,  0 #, Top !,  #ch/row Right !,  #rows Bottom !,  BlackRect  noerr scr00 gapAA ;,

\ Reverse Video tests
:, 1glyph55	$C000 #, @, $55AA #, xor, if, fail then,		( only a single glyph should be cleared )
                $C050 #, @, $55AA #, xor, if, fail then,
                $C0A0 #, @, $55AA #, xor, if, fail then,
                $C0F0 #, @, $55AA #, xor, if, fail then,
                $C140 #, @, $55AA #, xor, if, fail then,
                $C190 #, @, $55AA #, xor, if, fail then,
                $C1E0 #, @, $55AA #, xor, if, fail then,
                $C230 #, @, $55AA #, xor, if, fail then, ;,

:, t400		$0407 #, test !,  setup  0 #, Left !,  0 #, Top !,  1 #, Right !,  1 #, Bottom !,  ReverseVideo  noerr  1glyph55 gapAA ;,
:, t410		$0417 #, test !,  setup  0 #, Left !,  0 #, Top !,  #ch/row Right !,  #rows Bottom !,  ReverseVideo  noerr  scr55 gapAA ;,

\ Glyph Painting tests
create, myGlyph
	$50 c,, $51 c,, $52 c,, $53 c,, $54 c,, $55 c,, $56 c,, $57 c,,

:, tile
	$C000 #, @, $50AA #, xor, if, fail then,
	$C050 #, @, $51AA #, xor, if, fail then,
	$C0A0 #, @, $52AA #, xor, if, fail then,
	$C0F0 #, @, $53AA #, xor, if, fail then,
	$C140 #, @, $54AA #, xor, if, fail then,
	$C190 #, @, $55AA #, xor, if, fail then,
	$C1E0 #, @, $56AA #, xor, if, fail then,
	$C230 #, @, $57AA #, xor, if, fail then, ;,

:, t500		$0500 #, test !,  setup  #ch/row Left !, 0 #, Top !,  Stamp  ErrFlag @, 1 #, and, if, exit, then, fail ;,
:, t510		$0510 #, test !,  setup  0 #, Left !,  #rows Top !,  Stamp  ErrFlag @, 8 #, and, if, exit, then, fail ;,
:, t520		$0520 #, test !,  setup  0 #, Left !, 0 #, Top !,  myGlyph Glyph !,  1 #, Stride !,  Stamp  ErrFlag @, if, fail then, ;,
:, t530		$0530 #, test !,  setup  0 #, Left !, 0 #, Top !,  myGlyph Glyph !,  1 #, Stride !,  Stamp  tile ;,

\ Scroll test

:, line1	0 #, Left !, 1 #, Top !, myGlyph Glyph !, 1 #, Stride !, Stamp ;,

:, blank	( Heuristic; if the first word is clear, assume the rest of the line is clear too. )
	$FC00 #, @, if, fail then,
	$FC50 #, @, if, fail then,
	$FCA0 #, @, if, fail then,
	$FCF0 #, @, if, fail then,
	$FD40 #, @, if, fail then,
	$FD90 #, @, if, fail then,
	$FDE0 #, @, if, fail then,
	$FE30 #, @, if, fail then, ;,

:, t600		$0600 #, test !,  setup line1 Scroll  tile ;,
:, t610		$0610 #, test !,  setup line1 Scroll  blank ;,

:, all-tests
	t10 t20 t30 t40 t50 t60
	t100 t110 t120
	t200 t210 t220
	t300 t310
	t400 t410
	t500 t510 t520 t530
	t600 t610
	0 #, test !, fail ;,

' all-tests >body @ is, entry-point

\ gforth ../asm.fs sd-test-framebuffer.fs
