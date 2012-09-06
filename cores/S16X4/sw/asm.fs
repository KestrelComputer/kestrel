#! /usr/bin/gforth

\ Assembler for the S16X4 (written in ANS Forth)

\ \ \ PROGRAM IMAGE BUFFER, and how to read and write from/to it.

: TWORDS		2* ;

2048 CONSTANT #WORDS
#WORDS TWORDS CONSTANT /pib

CREATE pib	/pib CHARS ALLOT

VARIABLE pibptr

: align,	pibptr @ 1+ -2 AND pibptr ! ;
: >pib		pib + ;
: even		DUP 1 AND ABORT" Attempt to write a word to an odd address." ;
: inside	DUP /pib u>= ABORT" Attempt to write outside the Program Image Buffer." ;
: le!		2DUP C! 1+ SWAP 8 RSHIFT SWAP C! ;
: le@		DUP C@ $FF AND SWAP 1+ C@ 8 LSHIFT OR ;
: pib!		even inside >pib le! ;
: pib@		even inside >pib le@ ;
: pibc!		inside >pib c! ;
: pibc@		inside >pib c@ ;
: pib,		pibptr @ pib!  1 TWORDS pibptr +! ;
: pibc,		pibptr @ pibc!	1 pibptr +! ;

\ \ \ VERILOG DUMPER

variable ptr
variable param
variable even?
30 constant /program_name
create   program_name	/program_name allot
variable #program_name

: b		ptr @ pibc@ HEX S>D <# # # #> TYPE -1 TWORDS ptr +! ;
: 16bytes	b b b b  b b b b  b b b b  b b b b ;
: ?.,		[CHAR] ;  param @ 31 <> $17 AND XOR EMIT ;
: .32bytes	16bytes 16bytes ;
: .param	param @ S>D HEX <# # # #> TYPE ;
: .eod		[CHAR] _ EMIT ptr @ 1 AND S" EO" DROP + C@ EMIT ;
: .program	program_name #program_name @ TYPE ;
: ptr0		param @ 2* 2* 2* 2* 2* 2* 62 OR even? @ OR ptr ! ;
: .eq		ptr0 .program .eod ." .INIT_" .param ."  = 256'h" .32bytes ?., CR ;
: image		0 param ! BEGIN param @ 32 = IF EXIT THEN .eq 1 param +! AGAIN ;
: even		0 even? ! ;
: odd		1 even? ! ;
: program	32 parse /program_name min dup #program_name ! program_name swap move ;

\ \ \ INSTRUCTION ACCUMULATOR/BUILDER

variable iptr
variable slot

: enforce	pibptr @ iptr !  0 pib,  $F000 slot ! ;
: bblk		slot @ $F000 XOR IF align, enforce THEN ;
: eject		0 slot ! ;
: slot>>	slot @ 2/ 2/ 2/ 2/ $0FFF AND slot ! ;
: repl		15 AND DUP 2* 2* 2* 2* OR DUP $0100 * OR ;
: pack		repl slot @ AND iptr @ pib@ OR iptr @ pib! slot>> ;
: opc ( n -- )	slot @ 0= IF bblk THEN pack ;
: #, ( n -- )	1 opc pib, ;
: prim		CREATE , DOES> DUP @ opc @ 14 = IF bblk THEN ;

\ \ \ BASIC CPU PRIMITIVES

 0 prim nop,	( -- )
 1 prim lit,	( -- )
 2 prim @,	( -- )
 3 prim !,	( -- )

 4 prim +,	( -- )
 5 prim AND,	( -- )
 6 prim XOR,	( -- )
 7 prim ZGO,	( -- )

10 prim C@,	( -- )
11 prim C!,	( -- )
14 prim GO,	( -- )
15 prim NZGO,	( -- )

\ \ \ SYMBOL TABLE (or, something that emulates one, more or less)
\ \ \ Also, SUBROUTINE PRIMITIVES (in this case, it makes sense to
\ \ \ combine the two into a single layer).

VARIABLE rpa ( Return Pointer Address )

: call,		bblk pibptr @ 2 TWORDS + #, #, GO, ;
: DEFER,	bblk CREATE iptr @ , 0 #, GO, DOES> @ call, ;
: IS,		' >body @ 1 TWORDS + pib! ;
: preamble	iptr @ -1 TWORDS + #, !, bblk ;
: rtnword	bblk iptr @ rpa ! 1 TWORDS iptr +! 0 pib, ;
: :,		CREATE rtnword iptr @ , preamble DOES> @ call, ;
: EXIT,		rpa @ #, @, GO, ;
: ;,		EXIT, ;

\ \ \ Structured Programming Primitives

: if,		lit, pibptr @ 0 pib, zgo, ;
		\ pibptr @ 0 #, zgo, doesn't work because the assembler is lazy about
		\ starting new instruction packets.
: then,		bblk iptr @ swap pib! ;
: again,	rpa @ 3 TWORDS + #, go, ;
: int,		align, CREATE pibptr @ ,  eject  0 pib, DOES> @ #, ;
: char,		CREATE pibptr @ ,  eject  0 pibc, DOES> @ #, ;
: create,	CREATE pibptr @ ,  eject  DOES> @ #, ;
: const,	CREATE , DOES> @ #, ;

\ \ \ Miscellanious

: origin	pibptr !  eject ;
: C,,		pibc, ;
: ,,		pib, ;

