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

\ Dependencies needed for keyboard.fs

char, ps2code

int, #waits
int, #acks
int, ps2p
int, ckey

:, 0ctrs	0 #, #waits !,  0 #, #acks !, ;,

:, waitps2	#waits @, 1 #, +, #waits !, ;,
:, ackps2	#acks @, 1 #, +, #acks !, ;,
:, headps2	ps2p @, c@, ps2code c!,  ps2p @, 1 #, +, ps2p !, ;,

int, shiftst

\ Module Under Test
pibptr @
include keyboard.fs
pibptr @ swap - . .( bytes in module compiled) cr

\ Keyboard Driver tests

create, left-ctrl-down
	$14 c,, $1C c,,

create, left-ctrl-up
	$14 c,, $F0 c,, $14 c,, $1C c,,

create, right-ctrl-down
	$E0 c,, $14 c,, $1C c,,

create, right-ctrl-up
	$E0 c,, $14 c,, $F0 c,, $E0 c,, $14 c,, $1C c,,

create, left-shift-down
	$12 c,, $1C c,,

create, left-shift-up
	$12 c,, $F0 c,, $12 c,, $1C c,,

create, right-shift-down
	$59 c,, $1C c,,

create, right-shift-up
	$59 c,, $F0 c,, $59 c,, $1C c,,

create, lowercase-a
	$1C c,, 0 c,, ( padding)
	
create, uppercase-a
	$59 c,, $1C c,,

create, a-up
	$F0 c,, $1C ,,

create, esc-1
	$76 c,, $F0 c,, $76 c,, $16 c,, $F0 c,, $16 c,,


:, s1		test !,  0ctrs 0keyboard  left-ctrl-down ps2p !, ;,
:, s2		test !,  0ctrs 0keyboard  left-ctrl-up ps2p !, ;,
:, s3		test !,  0ctrs 0keyboard  right-ctrl-down ps2p !, ;,
:, s4		test !,  0ctrs 0keyboard  right-ctrl-up ps2p !, ;,
:, s5		test !,  0ctrs 0keyboard  left-shift-down ps2p !, ;,
:, s6		test !,  0ctrs 0keyboard  left-shift-up ps2p !, ;,
:, s7		test !,  0ctrs 0keyboard  right-shift-down ps2p !, ;,
:, s8		test !,  0ctrs 0keyboard  right-shift-up ps2p !, ;,
:, s9		test !,  0ctrs 0keyboard  lowercase-a ps2p !, ;,
:, s10		test !,  0ctrs 0keyboard  uppercase-a ps2p !, ;,
:, s11		test !,  0ctrs 0keyboard  a-up ps2p !, ;,
:, s12		test !,  0ctrs 0keyboard  esc-1 ps2p !, ;,


:, t010		$0010 #, s1  getkey  #waits @, if, exit, then, fail ;,
:, t020		$0020 #, s1  getkey  #acks @, #waits @, xor, if, fail then, ;,
:, t030		$0030 #, s1  getkey  shiftst @, 1 #, and, 1 #, xor, if, fail then, ;,
:, t040		$0040 #, s2  getkey  shiftst @, 1 #, and, if, fail then, ;,
:, t050		$0050 #, s3  getkey  shiftst @, 1 #, and, 1 #, xor, if, fail then, ;,
:, t060		$0060 #, s4  getkey  shiftst @, 1 #, and, if, fail then, ;,
:, t070		$0070 #, s5  getkey  shiftst @, 2 #, and, 2 #, xor, if, fail then, ;,
:, t080		$0080 #, s6  getkey  shiftst @, 2 #, and, if, fail then, ;,
:, t090		$0090 #, s7  getkey  shiftst @, 2 #, and, 2 #, xor, if, fail then, ;,
:, t0A0		$00A0 #, s8  getkey  shiftst @, 2 #, and, if, fail then, ;,
:, t0B0		$00B0 #, s9  getkey  ckey @, $61 #, xor, if, fail then, ;,
:, t0C0		$00C0 #, s10 getkey  ckey @, $41 #, xor, if, fail then, ;,
:, t0D0		$00D0 #, s11 translate  ckey @, if, fail then, ;,
:, t0E0		$00E0 #, s12 getkey  ckey @, $1B #, xor, if, fail then, ;,
:, t0E1		$00E1 #, s12 getkey getkey  ckey @, $31 #, xor, if, fail then, ;,

:, all-tests
	t010  t020 t030  t040 t050 t060  t070 t080 t090 t0A0 t0B0 t0C0 t0D0
	t0E0 t0E1
	$FFFF #, test !, fail
	;,

' all-tests >body @ is, entry-point
