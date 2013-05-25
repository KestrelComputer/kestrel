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
include stackops.fs
pibptr @ swap - . .( bytes in module compiled) cr

( DUP )
:, t		test !,  dstop dc !,  $ABCD #, dt !, ;,
:, t010		$0010 #, t  dup,  dstop -2 #, +, dc @, xor, if, fail then, ;,
:, t011		$0011 #, t  dup,  dt @, $ABCD #, xor, if, fail then, ;,
:, t012		$0012 #, t  dup,  dc @, @, $ABCD #, xor, if, fail then, ;,

( OVER )
:, t		test !,  dstop -2 #, +, dc !,  $ABCD #, dt !,  $4567 #, dc @, !, ;,
:, t020		$0020 #, t  over,  dstop -4 #, +, dc @, xor, if, fail then, ;,
:, t021		$0021 #, t  over,  dt @, $4567 #, xor, if, fail then, ;,
:, t022		$0022 #, t  over,  dc @, 0 #, +, @, $ABCD #, xor, if, fail then, ;,

( SWAP )
:, t030		$0030 #, t  swap,  dstop -2 #, +, dc @, xor, if, fail then, ;,
:, t031		$0031 #, t  swap,  dt @, $4567 #, xor, if, fail then, ;,
:, t032		$0032 #, t  swap,  dc @, @, $ABCD #, xor, if, fail then, ;,

( ROT )
:, t		test !,  dstop -4 #, +, dc !,  $ABCD #, dt !,  $4567 #, dc @, !,  $0123 #, dc @, 2 #, +, !, ;,
:, t040		$0040 #, t  rot,  dt @, $0123 #, xor, if, fail then, ;,
:, t041		$0041 #, t  rot,  dc @, 0 #, +, @, $ABCD #, xor, if, fail then, ;,
:, t042		$0042 #, t  rot,  dc @, 2 #, +, @, $4567 #, xor, if, fail then, ;,

( DROP )
:, t050		$0050 #, t  drop,  dt @, $4567 #, xor, if, fail then, ;,
:, t051		$0051 #, t  drop,  dstop -2 #, +, dc @, xor, if, fail then, ;,

( NIP )
:, t070		$0070 #, t  nip,  $ABCD #, dt @, xor, if, fail then, ;,
:, t071		$0071 #, t  nip,  dc @, @, $0123 #, xor, if, fail then, ;,
:, t072		$0072 #, t  nip,  dstop -2 #, +, dc @, xor, if, fail then, ;,

( DOLIT )

create, literal-pgm
	$7654 ,,

:, t		test !,  $ABCD #, dt !,  dstop dc !,  literal-pgm pc !, ;,
:, t060		$0060 #, t  dolit,  dt @, $7654 #, xor, if, fail then, ;,
:, t061		$0061 #, t  dolit,  dstop -2 #, +, dc @, xor, if, fail then, ;,
:, t062		$0062 #, t  dolit,  dc @, @, $ABCD #, xor, if, fail then, ;,
:, t063		$0063 #, t  dolit,  pc @, literal-pgm 2 #, +, xor, if, fail then, ;,

:, tests
	t010 t011 t012
	t020 t021 t022
	t030 t031 t032
	t040 t041 t042 
	t050 t051
	t060 t061 t062 t063
	t070 t071 t072
	$FFFF #, test !, fail
;,

' tests >body @ is, entry-point

\ gforth ../asm.fs sd-test-stackops.fs

