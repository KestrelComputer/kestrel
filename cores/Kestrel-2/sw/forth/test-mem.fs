\ Bootstrap entry point.
defer, entry-point

\ Module Dependencies

create, dstack
  16 allot,
' dstack >body @ 16 + const, dstop

int, dt \ data-stack top cache
int, dc \ data-stack counter
int, pc \ program counter

:, _nxt ;,

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
include mem.fs
pibptr @ swap - . .( bytes in module compiled) cr

create, membuf@
	$1234 ,,

create, membuf!
	0 ,,

( @ )
:, t		test !,  membuf@ dt !,  dstop dc !, ;,
:, t010		$0010 #, t  fetch,  dc @, dstop xor, if, fail then, ;,
:, t011		$0011 #, t  fetch,  dt @, $1234 #, xor, if, fail then, ;,

( C@ )
:, t020		$0020 #, t  cfetch,  dc @, dstop xor, if, fail then, ;,
:, t021		$0021 #, t  cfetch,  dt @, $0034 #, xor, if, fail then, ;,

( ! )
:, t		test !,  dstop -2 #, +, dc !,  $1234 #, dc @, !,  1 #, membuf! !,
			 dc @, -2 #, +, dc !,  $5678 #, dc @, !,  membuf! dt !, ;,
:, t030		$0030 #, t  store,  dc @, dstop xor, if, fail then, ;,
:, t031		$0031 #, t  store,  dt @, $1234 #, xor, if, fail then, ;,
:, t032		$0032 #, t  store,  membuf! @, $5678 #, xor, if, fail then, ;,

( C! )
:, t040		$0040 #, t  cstore,  dc @, dstop xor, if, fail then, ;,
:, t041		$0041 #, t  cstore,  dt @, $1234 #, xor, if, fail then, ;,
:, t042		$0042 #, t  cstore,  membuf! @, $0078 #, xor, if, fail then, ;,

( +! )
:, t050		$0050 #, t  +store,  dc @, dstop xor, if, fail then, ;,
:, t051		$0051 #, t  +store,  dt @, $1234 #, xor, if, fail then, ;,
:, t052		$0052 #, t  +store,  membuf! @, $5679 #, xor, if, fail then, ;,

:, tests
	t010 t011
	t020 t021
	t030 t031 t032
	t040 t041 t042
	t050 t051 t052
	$FFFF #, test !, fail
;,

' tests >body @ is, entry-point

\ gforth ../asm.fs sd-test-mem.fs

