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

\ Miscellaneous must-haves.

t: 2*		1 LSHIFT ;
t: 1-		-1 + ;

\ I/O device drivers.
S" v-mgia.fs" included	( MGIA video )
S" k-sdl.fs" included	( SDL2 keyboard emulation )
( S" k-ps2.fs" included	( KIA PS/2 keyboard )

\ !io is responsible for initializing all the I/O devices
\ for Forth to run.  This includes clearing the keyboard
\ queue, initializing the video display hardware, etc.
t: !io		0kia ;

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

