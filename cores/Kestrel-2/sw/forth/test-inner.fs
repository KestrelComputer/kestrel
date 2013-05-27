\ Bootstrap entry point.
defer, entry-point

\ Module Dependencies
int, pc
int, rc
int, w

create, rstack
	16 allot,

' rstack >body @ 16 + const, rstop

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
include inner.fs
pibptr @ swap - . .( bytes in module compiled) cr

defer, t010
defer, t021
defer, pass

create, t010-cfa
	' t010 >body @ ,,

create, t021-cfa
	' t021 >body @ ,,

create, exit-cfa
	' doexit >body @ ,,

create, t020-cfa
	' docolon >body @ ,,  0 ,, 0 ,, 0 ,,
	' t021-cfa >body @ ,,
	' exit-cfa >body @ ,,

create, pass-cfa
	' pass >body @ ,,

create, insn0
	' t010-cfa >body @ ,,
	' t020-cfa >body @ ,,
	' pass-cfa >body @ ,,

:, (pass)	$FFFF #, test !, fail ;,
' (pass) >body @ is, pass

:, (t010)	$0010 #, test !, pc @, insn0 2 #, +, xor, if, fail then, _nxt ;,
' (t010) >body @ is, t010

:, (t021)	$0021 #, test !, rc @, rstop -2 #, +, xor, if, fail then, _nxt ;,
' (t021) >body @ is, t021

:, tests	insn0 pc !,  rstop rc !,  $0005 #, test !,  _nxt  fail ;,
' tests >body @ is, entry-point

\ gforth ../asm.fs sd-test-inner.fs

