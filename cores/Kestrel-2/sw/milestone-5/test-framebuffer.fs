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
int, Left
int, Top
int, Right
int, Bottom
int, ErrFlag
  ( Private state )
int, p			( general memory pointer )
int, w			( width counter )
int, y			( current row counter )
int, r			( current raster counter )


\ Module Under Test
include framebuffer.fs


\ Re-used and useful phrases
:, incp		p @, 2 #, +, p !, ;,


\ Unit Testing Support
int, test

:, halt		again, ;,
:, testid	test @, $C000 #, !,  test @, -1 #, xor, $C050 #, !, ;,
:, (cls0)	p @, if, 0 #, p @, !, incp again, then, ;,
:, cls		bitplane p !, (cls0) ;,
:, fail		cls testid halt ;,

\ Edge case negative tests (remaining tests serve as positive tests)

:, =AAAA	p @, @, $AAAA #, xor, if, fail then, ;,
:, (screen0)	p @, gap xor, if, =AAAA incp again, then, ;,
:, (gap0)	p @, if, =AAAA incp again, then, ;,
:, scrAA	bitplane p !, (screen0) ;,
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
\ Zero-height tests
\ Positive tests

:, all-tests
	t10 t20 t30 t40 t50 t60
\	t100 t110 t120
\	t200 t210 t220
\	t300 t310
	0 #, test !, fail ;,

' all-tests >body @ is, entry-point

