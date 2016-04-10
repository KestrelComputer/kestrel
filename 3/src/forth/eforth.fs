\ Kestrel Forth V1.0
\ Copyright 2016 Samuel A. Falvo II
\ 
\ This Source Code Form is subject to the terms of the
\ Mozilla Public License, v. 2.0.  If a copy of the MPL
\ was not distributed with this file, You can obtain one
\ at https://mozilla.org/MPL/2.0/.
\ 
\ This file contains the eForth high-level words as
\ documented by Dr. C. H. Ting and Juergen Pintaske,
\ as of 2013-Apr-20. See
\ http://www.exemark.com/FORTH/eForthOverviewv5.pdf
\ 
\ NOTE: Some words are still implemented as assembly
\ language primitives, only because we have no choice
\ but to lay them down in memory *after* the their
\ high-level dependencies.  These exceptions are typically
\ related to IRQ and reset entry points.

t: VER		$0101 ;

\ User variables
tuser SP0	\ pointer to bottom of data stack
tuser RP0	\ pointer to bottom of return stack
tuser '?KEY	\ execution vector of ?KEY
tuser 'EMIT	\ execution vector of EMIT
tuser 'EXPECT	\ execution vector of EXPECT
tuser 'TAP	\ execution vector of TAP
tuser 'ECHO	\ execution vector of ECHO
tuser 'PROMPT	\ execution vector of PROMPT
tuser BASE	\ Numeric base
tuser tmp	\ temporary used by PARSE and FIND
tuser SPAN	\ Character count received by EXPECT
tuser >IN	\ Character offset while parsing input stream
tuser #TIB	\ Character count of terminal input buffer
tuser _tib	\ Character pointer of terminal input buffer
tuser CSP	\ Stack pointer for error checking
tuser 'EVAL	\ execution vector of EVAL
tuser 'NUMBER	\ execution vector of NUMBER
tuser HLD	\ Pointer used while building numeric output strings
tuser HANDLER	\ Holds return stack for error handling
tuser CONTEXT	\ Area for vocabulary search order.  This is the first to search.
7 CELLS /user +! \ reserve space for 7 more search contexts
tuser CURRENT	\ Pointer to descriptor of vocabulary currently being extended
tuser CP	\ Pointer to next available space for code
tuser NP	\ Pointer to bottom of name dictionary
tuser LAST	\ Pointer to last name in the dictionary
tuser TIBB	\ The actual terminal input buffer.
80 /user +!
tuser 'TYPE	\ execution vector of TYPE
tuser forthVoc	\ Forth vocabulary descriptor
1 CELLS /user +!


\ pg 19

t: ?DUP		DUP IF DUP THEN ;
t: ROT		>R SWAP R> SWAP ;
t: 2DROP	DROP DROP ;
t: 2DUP		OVER OVER ;
t: +		UM+ DROP ;
t: NOT		-1 XOR ;
t: INVERT	-1 XOR ;
t: NEGATE	-1 XOR 1 + ;
t: DNEGATE	NOT >R NOT 1 UM+ R> + ;
t: D+		>R SWAP >R UM+ R> R> + + ;
t: -		NEGATE + ;
t: ABS		DUP 0< IF NEGATE THEN ;

t: -ROT		ROT ROT ;

\ pg 20

t: NIP		SWAP DROP ;
t: =		XOR IF 0 EXIT THEN -1 ;
t: U<		2DUP XOR 0< IF NIP 0< EXIT THEN - 0< ;
t: <		2DUP XOR 0< IF DROP 0< EXIT THEN - 0< ;
t: MAX		2DUP < IF SWAP THEN DROP ;
t: MIN		2DUP SWAP < IF SWAP THEN DROP ;
t: WITHIN	OVER - >R - R> U< ;

\ pg 21

t: UM/MOD ( ud u -- ur uq )
  2DUP U< IF
    NEGATE
    63 FOR
      >R DUP UM+ >R >R DUP UM+ R> + DUP R> R@ 
      SWAP >R UM+  R> OR IF
        >R DROP 1 + R>
      ELSE DROP
      THEN R>
    NEXT DROP SWAP EXIT
  THEN DROP 2DROP -1 DUP ;

t: M/MOD ( d n -- r q ) \ floored division
  DUP 0<  DUP >R IF
    NEGATE >R DNEGATE R>
  THEN
  >R DUP 0< IF
    R@ +
  THEN
  R> UM/MOD R> IF
    SWAP NEGATE SWAP
  THEN ;

t: /MOD ( n n -- r q ) OVER 0< SWAP M/MOD ;
t: MOD ( n n -- r ) /MOD DROP ;
t: / ( n n -- q ) /MOD NIP ;

\ pg 22 words

t: UM* ( u u -- ud )
  0 SWAP ( u1 0 u2 ) 63 FOR
    DUP UM+ >R >R DUP UM+ R> + R> IF
      >R OVER UM+ R> +
    THEN
  NEXT ROT DROP ;

t: * ( n n -- n )	UM* DROP ;
t: M* ( n n -- d )	2DUP XOR 0< >R ABS SWAP ABS UM* R> IF DNEGATE THEN ;
t: */MOD ( n n n -- r q ) >R M* R> M/MOD ;
t: */ ( n n n -- q )	*/MOD SWAP DROP ;

\ pg 23 words

t: 1+		1 + ;
t: CELL-	-8 + ;
t: CELL+	8 + ;
t: CELLS	8 * ;
t: ALIGNED	DUP 0 8 UM/MOD DROP DUP IF 8 SWAP - THEN + ;
t: BL		32 ;
t: >CHAR	$7F AND DUP 127 BL WITHIN IF DROP 95 THEN ;
t: DEPTH	SP@ SP0 @ SWAP - 8 / ;
t: PICK		CELLS CELL+ SP@ + @ ;

\ Miscellaneous must-haves.

t: 2*		1 LSHIFT ;
t: 1-		-1 + ;
t: OCTAL	8 BASE ! ;
t: BINARY	2 BASE ! ;


\ pg 24 words

t: +!		SWAP OVER @ + SWAP ! ;
t: 2!		SWAP OVER ! CELL+ ! ;
t: 2@		DUP CELL+ @ SWAP @ ;
t: COUNT	DUP 1+ SWAP C@ ;
t: HERE		CP @ ;
t: PAD		HERE 80 + ;
t: TIB		#TIB CELL+ @ ;
t: @EXECUTE	@ ?DUP IF EXECUTE THEN ;
t: CMOVE	FOR AFT >R DUP C@ R@ C! 1+ R> 1+ THEN NEXT 2DROP ;
t: FILL		SWAP FOR SWAP AFT 2DUP C! 1+ THEN NEXT 2DROP ;
t: -TRAILING	FOR AFT BL OVER R@ + C@ < IF R> 1+ EXIT THEN THEN NEXT 0 ;
t: PACK$ ( b u a -- a )
  ALIGNED DUP >R
    2DUP C!
    1+ SWAP CMOVE
  R> ;

t: oldPACK$  ALIGNED DUP >R OVER DUP 0 8 UM/MOD DROP - OVER + 0 SWAP !
  2DUP C! 1+ SWAP CMOVE R> ;

\ pg 27 words

t: DIGIT	9 OVER < 7 AND + 48 + ;
t: EXTRACT	0 SWAP UM/MOD SWAP DIGIT ;
t: <#		PAD HLD ! ;
t: HOLD		HLD @ 1 - DUP HLD ! C! ;
t: #		BASE @ EXTRACT HOLD ;
t: #S		BEGIN # DUP WHILE REPEAT ;
t: SIGN		0< IF 45 HOLD THEN ;
t: #>		DROP HLD @ PAD OVER - ;
t: str		DUP >R ABS <# #S R> SIGN #> ;
t: HEX		16 BASE ! ;
t: DECIMAL	10 BASE ! ;

\ pg 31 words

t: ?KEY		'?KEY @EXECUTE ;
t: KEY		BEGIN ?KEY UNTIL ;
t: EMIT		'EMIT @EXECUTE ;
t: NUF?		?KEY DUP IF 2DROP KEY 13 = THEN ;
t: PACE		11 EMIT ;
t: SPACE	BL EMIT ;
t: CHARS ( ANS Conflict )
   SWAP 0 MAX FOR AFT DUP EMIT THEN NEXT DROP ;
t: SPACES	BL CHARS ;
t: (TYPE)	FOR AFT DUP C@ EMIT 1 + THEN NEXT DROP ;
t: TYPE		'TYPE @EXECUTE ;
t: CR		13 EMIT 10 EMIT ;

t: do$		R> R@ R> COUNT + ALIGNED >R SWAP >R ;
t: $"| ( -- a )	do$ ;
t: ."| ( -- )	do$ COUNT TYPE ; tcompile-only

\ pg 28 words

t: .R		>R str R> OVER - SPACES TYPE ;
t: U.R		>R <# #S #> R> OVER - SPACES TYPE ;
t: U.		<# #S #> SPACE TYPE ;
t: .		BASE @ 10 XOR IF U. EXIT THEN str SPACE TYPE ;
t: ?		@ . ;

\ pg 29 words

t: DIGIT? ( c base -- u t )
  >R 48 - 9 OVER <
  IF 7 - DUP 10 < OR THEN DUP R> U< ;

t: NUMBER? ( a -- n T | a F )
  BASE @ >R 0 OVER COUNT ( a 0 b n)
  OVER C@ 36 =
  IF HEX SWAP 1 + SWAP 1 - THEN ( a 0 b' n')
  OVER C@ 45 = >R ( a 0 b n)
  SWAP R@ - SWAP R@ + ( a 0 b" n")
  ?DUP IF
    1 - ( a 0 b n)
    FOR DUP >R C@ BASE @ DIGIT? WHILE
        SWAP BASE @ * + R> 1 +
      NEXT
      DROP R@ ( b ?sign) IF NEGATE THEN SWAP
    ELSE R> R> ( b index) 2DROP ( digit number) 2DROP 0
    THEN DUP
  THEN
  R> ( n ?sign) 2DROP R> BASE ! ;

\ pg 32 words

t: parse ( b u c -- b u delta ; <string> )
  tmp ! OVER >R DUP ( b u u )
  IF   1 - tmp @ BL =
       IF   ( b u' \ 'skip' )
            FOR   BL OVER C@ - 0< NOT
            WHILE 1 +
            NEXT ( b)
            R> DROP 0 DUP EXIT \ all delim
            THEN R>
       THEN OVER SWAP ( b' b' u' \ 'scan' )
            FOR  tmp @ OVER C@ - tmp @ BL =
            IF   0<
            THEN WHILE 1 +
            NEXT DUP >R ELSE R> DROP DUP 1 + >R
            THEN OVER - R> R> - EXIT
  THEN ( b u) OVER R> - ;

t: PARSE ( c -- b u ; <string> )
  >R TIB >IN @ + #TIB @ >IN @ - R> parse >IN +! ;

t: .(		41 PARSE TYPE ; timmediate
t: (		41 PARSE 2DROP ; timmediate
t: \		#TIB @ >IN ! ; timmediate

t: CHAR		BL PARSE DROP C@ ;
t: TOKEN ( -- a ; <string> )
  BL PARSE 31 MIN NP @ OVER - CELL- PACK$ ;
t: WORD ( c -- a ; <string> ) PARSE HERE PACK$ ;

\ pg 33-34 words

t: NAME> ( a -- xt ) CELL- CELL- CELL- ;
t: >NAME ( xt -- a ) CELL+ CELL+ CELL+ ;

t: SAME? ( a a u -- a a f \ -0+ )
  FOR AFT
    OVER C@ OVER C@ - ?DUP IF R> DROP EXIT THEN
    1+ SWAP 1+ SWAP
  THEN NEXT 0 ;

t: find ( a va -- xt na | a F )
  ( TODO Find a better way to scan the dictionary. )
  BEGIN DUP WHILE
    2DUP >NAME DUP C@ 1+ ( a va a na l)
    SAME? 0 = IF
      2DROP NIP DUP >NAME EXIT
    THEN
    2DROP CELL+ CELL+ @ -8 AND
  REPEAT ;

t: NAME? ( a -- xt na | a F )
  CONTEXT @ DUP 2@ XOR IF CELL- THEN >R \ context<>also
  BEGIN R> CELL+ DUP >R @ ?DUP WHILE
  find ?DUP UNTIL R> DROP EXIT THEN R> DROP 0 ;


\ pg 35 words

t: echo  'ECHO @EXECUTE ;
t: ^H ( b b b -- b b b ) \ backspace
  >R OVER R> SWAP OVER XOR IF
  8 echo 32 echo 8 echo 1- THEN ;
t: TAP ( bot eot cur c -- bot eot cur )
  DUP echo OVER C! 1 + ;
t: kTAP ( bot eot cur c -- bot eot cur )
  DUP 13 XOR IF 8 XOR IF BL TAP ELSE ^H THEN EXIT
  THEN DROP NIP DUP ;
t: accept ( b u -- b u )
  OVER + OVER
  BEGIN 2DUP XOR
  WHILE KEY DUP BL 127 WITHIN 
  IF TAP ELSE 'TAP @EXECUTE THEN
  REPEAT NIP OVER - ;
t: EXPECT ( b u -- ) 'EXPECT @EXECUTE SPAN ! DROP ;
t: QUERY ( -- )
  TIB 80 'EXPECT @EXECUTE #TIB ! DROP 0 >IN ! ;

\ pg 36-37 words

t: CATCH ( xt -- 0 | err# )
  SP@ >R  HANDLER @ >R  RP@ HANDLER ! EXECUTE R> HANDLER !  R> DROP  0 ;

t: THROW ( err# -- err# )
  HANDLER @ RP! R> HANDLER ! R> SWAP >R SP! DROP R> ;

tcreate NULL$ 0 t,

t: ABORT ( --) NULL$ THROW ;

t: abort" ( f --) IF do$ THROW THEN do$ DROP ;
( " to restore syntax highlighting )
: tplace	dup tc, begin dup while over c@ tc, 1 /string repeat 2drop ;
: ",		[char] " word count tplace /cell talign ;
: ~ABORT"	[t'] abort" t, ", ;
: ~."		[t'] ."| t, ", ;

t: .S ( --) CR DEPTH DUP . ': EMIT SPACE FOR AFT R@ PICK . THEN NEXT ."  <sp" ;

\ pg 38 words

t: $INTERPRET ( a --)
  NAME? IF
    DUP CELL+ CELL+ @ 2 AND ABORT" Compile-only"
    EXECUTE EXIT
  THEN
  'NUMBER @EXECUTE IF EXIT THEN
  THROW ;

t: [ ( --) doLIT $INTERPRET 'EVAL ! ; timmediate
t: .OK ( --) doLIT $INTERPRET 'EVAL @ = IF ."  ok" ELSE ." >>" THEN CR ;
t: ?STACK ( --) DEPTH 0< ABORT" underflow" ;
t: EVAL ( --)
  BEGIN TOKEN DUP C@ WHILE
    'EVAL @EXECUTE ?STACK
  REPEAT DROP 'PROMPT @EXECUTE ;

\ pg 47 words

t: _TYPE ( b u --) FOR AFT DUP C@ >CHAR EMIT 1 + THEN NEXT DROP ;
t: dm+ ( b u -- b ) OVER 4 U.R SPACE FOR AFT DUP C@ 3 U.R 1 + THEN NEXT ;
t: DUMP ( b u --)
  BASE @ >R 
  HEX  16 /
  FOR CR 16 2DUP dm+ ROT ROT 2 SPACES _TYPE NUF? NOT WHILE
  NEXT ELSE R> DROP THEN DROP  R> BASE ! ;

\ I/O device drivers.

S" v-mgia.fs" included	( MGIA video )
S" k-sdl.fs" included	( SDL2 keyboard emulation )
( S" k-ps2.fs" included	( KIA PS/2 keyboard )

\ !io is responsible for initializing all the I/O devices
\ for Forth to run.  This includes clearing the keyboard
\ queue, initializing the video display hardware, etc.
t: !io		0kia 0mgia ;
t: FORTH	forthVoc CONTEXT ! ;
t: DEFINITIONS	CONTEXT @ CURRENT ! ;
t: PRESET	TIBB 80 #TIB 2!  -16 @ /GLOBALS ! -24 @ /USER ! ;

\ Shell

tcode RP0!  ( MUST TRACK __reset__ BELOW! )
	1024 x0 x9 addi, ( user pointer )
	1024 x9 x9 addi, ( data stack )
	1024 x9 rsp addi, ( return stack )
	next,
tend-code

t: QUIT
  RP0! BEGIN
    BEGIN QUERY doLIT EVAL CATCH ?DUP UNTIL
    'PROMPT @ SWAP NULL$ OVER XOR IF
      CR #TIB 2@ TYPE CR >IN @ 94 CHARS CR COUNT TYPE ."  ?" CR
    THEN doLIT .OK XOR IF
      $1B EMIT  ( ?? )
    THEN PRESET
  AGAIN ;

t: U0		SP@ SP0 !
		doLIT ?rx '?KEY !
		doLIT EMIT 'EMIT !
		doLIT accept 'EXPECT !
		doLIT kTAP 'TAP !
		doLIT EMIT 'ECHO !
		doLIT .OK 'PROMPT !
		DECIMAL
		doLIT $INTERPRET 'EVAL !
		doLIT NUMBER? 'NUMBER !
		65536 CP !
		$FF0000 NP !
		doLIT mgia-type 'TYPE !
		-8 @ DUP forthVoc 2!
		0 CONTEXT !  0 CONTEXT CELL+ !
;

t: .VER		BASE @ HEX VER <# # # '. HOLD # #> TYPE BASE ! ;
t: .FREE	CP 2@ - U. ;

t: hi
  !io
  ."                         **** Kestrel-3 Forth V" .VER ."  ****" CR CR
  ."                     " .FREE ."  bytes free.   Licensed MPLv2." CR CR
  .OK ;

t: .CREDITS	CR ." Copyright 2016 Samuel A. Falvo II.  This software is provided" CR
		." under the Mozilla Public License V2.0.  If you have not received" CR
		." a copy of the license, you may find a copy online at:" CR CR
		." https://www.mozilla.org/en-US/MPL/2.0/" CR CR
		." Based on eForth V1.01 by Bill Muench, C. H. Ting" CR ;

\ COLD is the Forth half of the cold bootstrap for the
\ Forth runtime environment.

t: COLD		BEGIN U0 PRESET hi FORTH DEFINITIONS QUIT AGAIN ;

\ pg 40 words

t: '		TOKEN NAME? IF EXIT THEN THROW ;
t: ALLOT	CP +! ;
t: ,		HERE !  1 CELLS ALLOT ;
t: C,		HERE C!  1 ALLOT ;
t: [COMPILE]	' , ; timmediate
t: COMPILE	R> DUP @ , CELL+ >R ;
t: LITERAL	COMPILE doLIT , ; timmediate
t: $,"		34 WORD COUNT ALIGNED ALLOT DROP ;
t: RECURSE	LAST @ , ;

: ~[COMPILE]	t' t, ;

\ pg 42-43 words

t: <MARK	HERE ;
t: <RESOLVE	, ;
t: >MARK	HERE 0 , ;
t: >RESOLVE	<MARK SWAP ! ;

t: FOR		COMPILE >R <MARK ; timmediate tcompile-only
t: BEGIN	<MARK ; timmediate tcompile-only
t: NEXT		COMPILE ?next <RESOLVE ; timmediate tcompile-only
t: UNTIL	COMPILE ?branch <RESOLVE ; timmediate tcompile-only
t: AGAIN	COMPILE branch <RESOLVE ; timmediate tcompile-only
t: IF		COMPILE ?branch >MARK ; timmediate tcompile-only
t: AHEAD	COMPILE branch >MARK ; timmediate tcompile-only
t: REPEAT	[COMPILE] AGAIN >RESOLVE ; timmediate tcompile-only
t: THEN		>RESOLVE ; timmediate tcompile-only
t: AFT		DROP [COMPILE] AHEAD [COMPILE] BEGIN SWAP ; timmediate tcompile-only
t: ELSE		[COMPILE] AHEAD SWAP [COMPILE] THEN ; timmediate tcompile-only
t: WHEN		[COMPILE] IF OVER ; timmediate tcompile-only
t: WHILE	[COMPILE] IF SWAP ; timmediate tcompile-only
t: DO		COMPILE SWAP COMPILE >R COMPILE >R <MARK ; timmediate tcompile-only
t: LOOP		COMPILE (doloop) <RESOLVE ; timmediate tcompile-only
t: +LOOP	COMPILE (do+loop) <RESOLVE ; timmediate tcompile-only

t: ABORT"	COMPILE abort" $," ; timmediate tcompile-only

t: $"		COMPILE $"| $," ; timmediate
t: ."		COMPILE ."| $," ; timmediate

: ~$"		[t'] $"| t, 34 word count dup tc, romp @ over tallot swap move /cell talign ;

\ pg 44-45 words

t: ?UNIQUE	DUP NAME? IF ."  redef " OVER COUNT TYPE THEN DROP ;
t: $,n
  DUP C@ IF
    ?UNIQUE DUP LAST ! HERE ALIGNED SWAP CELL- CURRENT @ @ OVER !
    CELL- DUP NP ! ! EXIT
  THEN $" name" THROW ;
t: imm?		CELL+ CELL+ @ 1 AND ;
t: $COMPILE	NAME? IF DUP imm? IF EXECUTE ELSE , THEN EXIT THEN
		'NUMBER @EXECUTE IF [COMPILE] LITERAL EXIT THEN
		THROW ;
t: ]		doLIT $COMPILE 'EVAL ! ; timmediate
t: OVERT	LAST @ CURRENT @ ! ;
t: ;		COMPILE EXIT [COMPILE] [ OVERT ; timmediate
t: ?safe	CP @ NP @ U< 0 = ABORT" out of space" ;
t: n,		-8 NP +!  ?safe  NP @ ! ;
t: dec		DUP 1+ ALIGNED NEGATE NP +! ;
t: padded	NP @ OVER 8 + -8 AND 0 FILL ;
t: nplace	padded DUP NP @ C! NP @ 1+ SWAP CMOVE ;
t: nname,	dec ?safe nplace ;
t: nhead,	nname, CURRENT @ @ n, HERE n, n, NP @ LAST ! ;
t: :		doLIT (enter) @ BL PARSE nhead, [COMPILE] ] ;
t: or-nfa	LAST @ CELL+ CELL+ @ OR LAST @ CELL+ CELL+ ! ;
t: IMMEDIATE	1 or-nfa ;
t: COMPILE-ONLY	2 or-nfa ;

t: !pfa		LAST @ CELL+ ! ;
t: !user	/USER @ ALIGNED DUP !pfa 8 + /USER ! ;
t: !cuser	/USER @ DUP !pfa 1+ /USER ! ;

t: CREATE	doLIT (dovar) @ BL PARSE nhead, OVERT ;
t: VARIABLE	CREATE 0 , ;
t: CONSTANT	doLIT (doglobal) @ BL PARSE nhead, OVERT !pfa ;
t: GLOBAL	/GLOBALS @ ALIGNED DUP CONSTANT  8 + /GLOBALS ! ;
t: CGLOBAL	/GLOBALS @ DUP CONSTANT 1+ /GLOBALS ! ;
t: USER		doLIT (douser) @ BL PARSE nhead, OVERT !user ;
t: CUSER	doLIT (douser) @ BL PARSE nhead, OVERT !cuser ;

t: .BASE	BASE @ DECIMAL DUP . BASE ! ;
t: !CSP		SP@ CSP ! ;
t: ?CSP		SP@ CSP @ XOR ABORT" stack imbalance" ;

t: .ID		?DUP IF >NAME COUNT _TYPE EXIT THEN ." {no name}" ;
t: WORDS
  CR CONTEXT @ @
  BEGIN ?DUP
  WHILE DUP SPACE .ID
	CELL+ CELL+ @ -8 AND NUF?
  UNTIL DROP THEN ;

\ __RESET__ is the RISC-V half of the cold bootstrap for
\ the Forth runtime environment.  It's responsible for
\ initializing the Forth virtual machine registers.  Once
\ initialized, it defers to __BOOT__ for higher-level
\ initialization tasks.
8 talign
tcode __RESET__
	0 x9 auipc,
	24 x9 ip ld,
	1024 x0 up addi,
	1024 up dsp addi,
	1024 dsp rsp addi,
	next,
	t' COLD t>h cell+ @ t,
tend-code

\ BYE terminates the current Forth session, and returns
\ the user to the host operating system.  However, since
\ we *are* the host operating system, BYE simply restarts
\ the environment as if the user had reset the computer.
t: BYE		__RESET__ ;

