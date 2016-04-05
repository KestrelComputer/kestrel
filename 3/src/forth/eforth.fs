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
tuser _ctx1
tuser _ctx2
tuser _ctx3
tuser _ctx4
tuser _ctx5
tuser _ctx6
tuser _ctx7
tuser CURRENT	\ Pointer to vocabulary currently being extended
tuser CP	\ Pointer to next available space for code
tuser NP	\ Pointer to bottom of name dictionary
tuser LAST	\ Pointer to last name in the dictionary

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
t: PACK$
  ALIGNED DUP >R OVER DUP 0 8 UM/MOD DROP - OVER + 0 SWAP !
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
t: TYPE		FOR AFT DUP C@ EMIT 1 + THEN NEXT DROP ;
t: CR		13 EMIT 10 EMIT ;

: do$		R> R@ R> COUNT + ALIGNED >R SWAP >R ;
: $"| ( -- a )	do$ ;
: ."| ( -- )	do$ COUNT TYPE ;

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

t: .(		41 PARSE TYPE ;
t: (		41 PARSE 2DROP ;
t: \		#TIB @ >IN ! ;

t: CHAR		BL PARSE DROP C@ ;
t: TOKEN ( -- a ; <string> )
  BL PARSE 31 MIN NP @ OVER - CELL- PACK$ ;
t: WORD ( c -- a ; <string> ) PARSE HERE PACK$ ;


\ Miscellaneous must-haves.

t: 2*		1 LSHIFT ;
t: 1-		-1 + ;
t: OCTAL	8 BASE ! ;
t: BINARY	2 BASE ! ;

\ I/O device drivers.
S" v-mgia.fs" included	( MGIA video )
S" k-sdl.fs" included	( SDL2 keyboard emulation )
( S" k-ps2.fs" included	( KIA PS/2 keyboard )

\ !io is responsible for initializing all the I/O devices
\ for Forth to run.  This includes clearing the keyboard
\ queue, initializing the video display hardware, etc.
t: !io		0kia 0mgia ;

\ __BOOT__ is the Forth half of the cold bootstrap for the
\ Forth runtime environment.  The __RESET__ word handles
\ setting up the basic Forth virtual machine registers;
\ __BOOT__ handles everything else.
t: __BOOT__	!io PANIC ;

\ __RESET__ is the RISC-V half of the cold bootstrap for
\ the Forth runtime environment.  It's responsible for
\ initializing the Forth virtual machine registers.  Once
\ initialized, it defers to __BOOT__ for higher-level
\ initialization tasks.
8 talign
tcode __RESET__
	0 x9 auipc,
	24 x9 ip ld,
	0 x0 up addi,
	1024 up dsp addi,
	1024 dsp rsp addi,
	next,
	t' __BOOT__ t>h cell+ @ t,
tend-code

\ BYE terminates the current Forth session, and returns
\ the user to the host operating system.  However, since
\ we *are* the host operating system, BYE simply restarts
\ the environment as if the user had reset the computer.
t: BYE		__RESET__ ;

