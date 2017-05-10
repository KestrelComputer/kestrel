\ Bootstrap entry point.  The DEFER must always be the first thing compiled.
defer, entry-point

\ Unit Testing Support
int, test
int, p
:, incp		p @, 2 #, +, p !, ;,
:, halt		again, ;,
:, testid	test @, $C000 #, !,  test @, -1 #, xor, $C050 #, !, $1111 #, $C0A0 #, !, ;,
:, (cls0)	p @, if, 0 #, p @, !, incp again, then, ;,
:, cls		$C000 #, p !, (cls0) ;,
:, fail		cls testid halt ;,

\ Dependencies needed for timer.fs
3 const, BLINK_TICKS

int, toggle-called
:, toggle	toggle-called @, 1 #, +, toggle-called !, ;,

\ Module Under Test
pibptr @
include timer.fs
pibptr @ swap - . .( bytes in module compiled) cr

\ Timer tests
:, s		test !,  0 #, toggle-called !,  0timer ;,
:, t010		$0010 #, s  toggle-called @, if, fail then, ;,
:, t011		$0011 #, s tick  toggle-called @, if, fail then, ;,
:, t012		$0012 #, s tick tick toggle-called @, if, fail then, ;,
:, t013		$0013 #, s tick tick tick toggle-called @, if, exit, then, fail ;,

:, all-tests
	t010 t011 t012 t013
	$FFFF #, test !, fail
	;,

' all-tests >body @ is, entry-point
