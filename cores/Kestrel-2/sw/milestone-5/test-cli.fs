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

\ Dependencies needed for cli.fs

\ Module Under Test
pibptr @
include cli.fs
pibptr @ swap - . .( bytes in module compiled) cr

\ Timer tests
:, s		test !,  ;,

:, all-tests
	$FFFF #, test !, fail
	;,

' all-tests >body @ is, entry-point
