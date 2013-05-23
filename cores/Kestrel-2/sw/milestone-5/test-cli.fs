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
create, ib	32 allot,
32 const, /ib
int, #ib
:, 0ib		0 #, ib !,  0 #, ib 2 #, +, !,  0 #, ib 4 #, +, !, ;,

int, ckey
int, #k
int, kp
int, #reveal
int, #setbm
int, strp
int, strl
int, chr

:, 0ctrs	0 #, #reveal !,  0 #, #setbm !, ;,

:, (gk)		kp @, @, ckey !,  kp @, 2 #, +, kp !,  #k @, -1 #, +, #k !, ;,
:, getkey	#k @, if, (gk) exit, then, test @, $1000 #, xor, test !, fail ;,

:, reveal	#reveal @, 1 #, +, #reveal !, ;,
:, hide		;,
:, setbm	#setbm @, 1 #, +, #setbm !, ;,
:, resetbm	;,

:, PrintStr	;,
:, PrintCh ;,
:, ClearEol ;,


\ Module Under Test
pibptr @
include cli.fs
pibptr @ swap - . .( bytes in module compiled) cr

\ CLI tests

:, buf=A		ib c@, $41 #, xor, if, fail then, ;,
:, buf=B		ib c@, $42 #, xor, if, fail then, ;,
:, buf=C		ib c@, $43 #, xor, if, fail then, ;,
:, buf=AB		buf=A  ib 1 #, +, c@, $42 #, xor, if, fail then, ;,
:, buf=AC		buf=A  ib 1 #, +, c@, $43 #, xor, if, fail then, ;,
:, buf=CA		buf=C  ib 1 #, +, c@, $41 #, xor, if, fail then, ;,
:, buf=ACB		buf=AC  ib 2 #, +, c@, $42 #, xor, if, fail then, ;,
:, buf=CAB		buf=CA  ib 2 #, +, c@, $42 #, xor, if, fail then, ;,

( Zero-length input buffer results )

create, 0-tab
	$000D ,,

:, s		test !,  0ctrs  1 #, #ib !,  0-tab kp !,  1 #, #k !, ;,
:, t010		$0010 #, s  accept  #ib @, if, fail then, ;,
:, t020		$0020 #, s  accept  #k @, if, fail then, ;,
:, t030		$0030 #, s  accept  kp @, -2 #, +, @, $000D #, xor, if, fail then, ;,
:, t040		$0040 #, s  accept  #reveal @, 1 #, xor, if, fail then, ;,

( graphic characters )

create, 1-tab
	$0041 ,, $000D ,,

create, 2-tab
	$0041 ,, $0042 ,, $000D ,,

create, ggLg-tab
	$0041 ,, $0042 ,, $0100 ,, $0043 ,, $000D ,,

create, ggLLg-tab
	$0041 ,, $0042 ,, $0100 ,, $0100 ,, $0043 ,, $000D ,,

:, s1		test !,  0ctrs 0ib  1-tab kp !,  2 #, #k !, ;,
:, s2		test !,  0ib  2-tab kp !,  3 #, #k !, ;,
:, s3		test !,  ggLg-tab kp !,  5 #, #k !, ;,
:, s4		test !,  ggLLg-tab kp !,  6 #, #k !, ;,

:, t080		$0080 #, s1 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t081		$0081 #, s1 accept  ib c@, $41 #, xor, if, fail then, ;,
:, t082		$0082 #, s1 accept	#setbm @, 1 #, xor, if, fail then, ;,
:, t090		$0090 #, s2 accept  #ib @, 2 #, xor, if, fail then, ;,
:, t091		$0091 #, s2 accept  buf=AB ;, 
:, t0A0		$00A0 #, s3 accept  #ib @, 3 #, xor, if, fail then, ;,
:, t0A1		$00A1 #, s3 accept  buf=ACB ;,
:, t0B0		$00B0 #, s4 accept  #ib @, 3 #, xor, if, fail then, ;,
:, t0B1		$00B1 #, s4 accept  buf=CAB ;,

( Backspace tests )

create, <-tab
	$0008 ,, $000D ,,

create, g<-tab
	$0041 ,, $0008 ,, $000D ,,

create, gg<-tab
	$0041 ,, $0042 ,, $0008 ,, $000D ,,

create, gL<-tab
	$0041 ,, $0100 ,, $0008 ,, $000D ,,

create, ggL<-tab
	$0041 ,, $0042 ,, $0100 ,, $0008 ,, $000D ,,

create, ggLL<-tab
	$0041 ,, $0042 ,, $0100 ,, $0100 ,, $0008 ,, $000D ,,
	
:, s1		test !, <-tab kp !,  2 #, #k !, ;,
:, s2		test !, g<-tab kp !,  3 #, #k !, ;,
:, s3		test !, gg<-tab kp !,  4 #, #k !, ;,
:, s4		test !, gL<-tab kp !,  4 #, #k !, ;,
:, s5		test !, ggL<-tab kp !,  5 #, #k !, ;,
:, s6		test !, ggLL<-tab kp !,  6 #, #k !, ;,

:, t100		$0100 #, s1 accept  #ib @, if, fail then, ;,
:, t110		$0110 #, s2 accept  #ib @, if, fail then, ;,
:, t120		$0120 #, s3 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t130		$0130 #, s4 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t131		$0131 #, s4 accept  buf=A ;,
:, t140		$0140 #, s5 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t141		$0141 #, s5 accept  buf=B ;,
:, t150		$0150 #, s6 accept	#ib @, 2 #, xor, if, fail then, ;,

( DEL tests )

create, >-tab
	$007F ,, $000D ,,

create, g>-tab
	$0041 ,, $007F ,, $000D ,,

create, gg>-tab
	$0041 ,, $0042 ,, $007F ,, $000D ,,

create, gL>-tab
	$0041 ,, $0100 ,, $007F ,, $000D ,,

create, ggL>-tab
	$0041 ,, $0042 ,, $0100 ,, $007F ,, $000D ,,

create, ggLL>-tab
	$0041 ,, $0042 ,, $0100 ,, $0100 ,, $007F ,, $000D ,,

:, s1		test !, >-tab kp !,  2 #, #k !, ;,
:, s2		test !, g>-tab kp !,  3 #, #k !, ;,
:, s3		test !, gg>-tab kp !,  4 #, #k !, ;,
:, s4		test !, gL>-tab kp !,  4 #, #k !, ;,
:, s5		test !, ggL>-tab kp !,  5 #, #k !, ;,
:, s6		test !, ggLL>-tab kp !,  6 #, #k !, ;,

:, t180		$0180 #, s1 accept  #ib @, if, fail then, ;,
:, t190		$0190 #, s2 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t1A0		$01A0 #, s3 accept  #ib @, 2 #, xor, if, fail then, ;,
:, t1A1		$01A1 #, s3 accept  buf=AB ;,
:, t1B0		$01B0 #, s4 accept  #ib @, if, fail then, ;,
:, t1C0		$01C0 #, s5 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t1C1		$01C1 #, s5 accept  buf=A ;,
:, t1D0		$01D0 #, s6 accept  #ib @, 1 #, xor, if, fail then, ;,

( Cursor Left tests )

create, L-tab
	$0100 ,, $000D ,,

create, gL-tab
	$0041 ,, $0100 ,, $000D ,,

create, ggL-tab
	$0041 ,, $0042 ,, $0100 ,, $000D ,,

create, gLg-tab
	$0041 ,, $0100 ,, $0042 ,, $000D ,,

create, gLL-tab
	$0041 ,, $0100 ,, $0100 ,, $000D ,,

create, ggLL-tab
	$0041 ,, $0042 ,, $0100 ,, $0100 ,, $000D ,,

create, ggLLL-tab
	$0041 ,, $0042 ,, $0100 ,, $0100 ,, $0100 ,, $000D ,,

:, s1		test !, L-tab kp !,  2 #, #k !, ;,
:, s2		test !, gL-tab kp !,  3 #, #k !, ;,
:, s3		test !, ggL-tab kp !,  4 #, #k !, ;,
:, s4		test !, gLg-tab kp !,  4 #, #k !, ;,
:, s5		test !, gLL-tab kp !,  4 #, #k !, ;,
:, s6		test !, ggLL-tab kp !,  5 #, #k !, ;,
:, s7		test !, ggLLL-tab kp !,  6 #, #k !, ;,

:, t200		$0200 #, s1 accept  #ib @, if, fail then, ;,
:, t210		$0210 #, s2 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t220		$0220 #, s3 accept  #ib @, 2 #, xor, if, fail then, ;,
:, t221		$0221 #, s3 accept  buf=AB ;,
:, t230		$0230 #, s4 accept  #ib @, 2 #, xor, if, fail then, ;,
:, t240		$0240 #, s5 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t250		$0250 #, s6 accept  #ib @, 2 #, xor, if, fail then, ;,
:, t260		$0260 #, s7 accept  #ib @, 2 #, xor, if, fail then, ;,

( Cursor Right tests )

create, R-tab
	$0101 ,, $000D ,,

create, gR-tab
	$0041 ,, $0101 ,, $000D ,,

create, ggR-tab
	$0041 ,, $0042 ,, $0101 ,, $000D ,,

create, gLR-tab
	$0041 ,, $0100 ,, $0101 ,, $000D ,,

create, ggLR-tab
	$0041 ,, $0042 ,, $0100 ,, $0101 ,, $000D ,,

create, ggLLR-tab
	$0041 ,, $0042 ,, $0100 ,, $0100 ,, $0101 ,, $000D ,,

:, s1		test !, R-tab kp !,  2 #, #k !, ;,
:, s2		test !, gR-tab kp !,  3 #, #k !, ;,
:, s3		test !, ggR-tab kp !,  4 #, #k !, ;,
:, s4		test !, gLR-tab kp !,  4 #, #k !, ;,
:, s5		test !, ggLR-tab kp !,  5 #, #k !, ;,
:, s6		test !, ggLLR-tab kp !,  6 #, #k !, ;,

:, t280		$0280 #, s1 accept  #ib @, if, fail then, ;,
:, t290		$0290 #, s2 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t2A0		$02A0 #, s3 accept  #ib @, 2 #, xor, if, fail then, ;,
:, t2B0		$0290 #, s4 accept  #ib @, 1 #, xor, if, fail then, ;,
:, t2C0		$02C0 #, s5 accept  #ib @, 2 #, xor, if, fail then, ;,
:, t2D0		$02D0 #, s6 accept  #ib @, 2 #, xor, if, fail then, ;,

:, all-tests
	t010 t020 t030 t040
	t080 t081 t082 t090 t091 t0A0 t0A1 t0B0
	t100 t110 t120 t130 t131 t140 t141 t150
	t180 t190 t1A0 t1A1 t1B0 t1C0 t1D0
	t200 t210 t220 t221 t230 t240 t250 t260
	t280 t290 t2A0 t2B0 t2C0 t2D0

	$FFFF #, test !, fail
	;,

' all-tests >body @ is, entry-point
