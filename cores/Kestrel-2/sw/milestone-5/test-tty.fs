\ Bootstrap entry point.
defer, entry-point

\ Module Dependencies

( The number of times these words have been called )
int, homes
int, hides
int, reveals
int, mvrights
int, stamps
int, returns
int, mvdowns
int, scrolls

int, x
int, y
int, Left
int, Top
int, chr
int, Glyph
int, Stride

int, &redge?
int, &bedge?

:, 0state	0 #, homes !, 0 #, hides !, 0 #, reveals !, 0 #, mvrights !, 0 #, stamps !, 0 #, returns !, 0 #, mvdowns !, 0 #, scrolls !, 0 #, &redge? !, 0 #, &bedge? !, ;,

:, home		homes @, 1 #, +, homes !, ;,
:, hide		hides @, 1 #, +, hides !, ;,
:, reveal	reveals @, 1 #, +, reveals !, ;,
:, mvright	mvrights @, 1 #, +, mvrights !, ;,
:, stamp	stamps @, 1 #, +, stamps !, ;,
:, return	returns @, 1 #, +, returns !, ;,
:, mvdown	mvdowns @, 1 #, +, mvdowns !, ;,
:, scroll	scrolls @, 1 #, +, scrolls !, ;,

:, getxy	;,
:, redge	-1 #, &redge? !, ;,
:, bedge	-1 #, &bedge? !, ;,
:, REdge?   &redge? @, ;,
:, BEdge?	&bedge? @, ;,

create, fontBase

\ Unit Testing Support
int, test
int, p
:, incp		p @, 2 #, +, p !, ;,
:, halt		again, ;,
:, testid	test @, $C000 #, !,  test @, -1 #, xor, $C050 #, !, $1111 #, $C0A0 #, !, ;,
:, (cls0)	p @, if, 0 #, p @, !, incp again, then, ;,
:, cls		$C000 #, p !, (cls0) ;,
:, fail		cls testid halt ;,

\ Module Under Test
pibptr @
include tty.fs
pibptr @ swap - . .( bytes in module compiled) cr

:, t		test !, 0state 0tty ;,

:, t010		$0010 #, t  homes @, if, exit, then, fail ;,
:, t020		$0020 #, t PrintCh  hides @, 1 #, xor, if, fail then, ;,
:, t030		$0030 #, t PrintCh  reveals @, 1 #, xor, if, fail then, ;,
:, t040		$0040 #, t PrintCh  mvrights @, 1 #, xor, if, fail then, ;,
:, t050		$0050 #, t PrintCh  stamps @, 1 #, xor, if, fail then, ;,
:, t060		$0060 #, t PrintCh PrintCh mvrights @, 2 #, xor, if, fail then, ;,

:, t070		$0070 #, t redge PrintCh  returns @, 1 #, xor, if, fail then, ;,
:, t080		$0080 #, t redge PrintCh  mvdowns @, 1 #, xor, if, fail then, ;,

:, t090		$0090 #, t redge bedge PrintCh  returns @, 1 #, xor, if, fail then, ;,
:, t100		$0100 #, t redge bedge PrintCh  mvdowns @, if, fail then, ;,
:, t110		$0110 #, t redge bedge PrintCh  scrolls @, 1 #, xor, if, fail then, ;,

:, tests
	t010 t020 t030 t040 t050 t060 t070
	t080 t090 t100 t110
	$0000 #, test !, fail
;,

' tests >body @ is, entry-point

\ gforth ../asm.fs sd-test-tty.fs
