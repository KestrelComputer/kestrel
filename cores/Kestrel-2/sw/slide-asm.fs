#! /usr/bin/gforth

\ Assembler for the Milestone-2 Slide Projector

\ \ \ PROGRAM IMAGE BUFFER, and how to read and write from/to it.

: TWORDS		2* ;

2048 CONSTANT #WORDS
#WORDS TWORDS CONSTANT /pib
64 CONSTANT #INITS

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
: ?.,		[CHAR] ;  param @ [ #INITS 1- ] LITERAL <> $17 AND XOR EMIT ;
: .32bytes	16bytes 16bytes ;
: .param	param @ S>D HEX <# # # #> TYPE ;
: .eod		[CHAR] _ EMIT ptr @ 1 AND S" EO" DROP + C@ EMIT ;
: .program	program_name #program_name @ TYPE ;
: ptr0		param @ 2* 2* 2* 2* 2* 2* 62 OR even? @ OR ptr ! ;
: .eq		ptr0 .program .eod ." .INIT_" .param ."  = 256'h" .32bytes ?., CR ;
: image		0 param ! BEGIN param @ #INITS = IF EXIT THEN .eq 1 param +! AGAIN ;
: even		0 even? ! ;
: odd		1 even? ! ;
: program	32 parse /program_name min dup #program_name ! program_name swap move ;

: origin	pibptr ! ;
: C,,		pibc, ;
: ,,		pib, ;

\ \ \ DSL

variable ssf	( slides so far )
32 constant #slides
#slides cells constant /slidetab
create slidetab	/slidetab allot

: sl,		cells slidetab + @ ,, ;
: slidetab,	0 begin dup ssf @ xor while dup sl, 1+ repeat drop ;

variable left
variable top

: end		$0001 ,, ;
: text		>r $10 c,, top @ c,, left @ c,, r@ c,, pibptr @ >pib r@ move r> pibptr +! align, ;

: start		4 origin  0 ssf ! ;
: done		ssf @ 0 pib!  pibptr @ 2 pib!  slidetab, ;
: slide		end 1 ssf +!  pibptr @ ssf @ 1- cells slidetab + ! ;

\ \ \ Useful utilities and "macros"

: home		left off  top off ;
: org		2 left ! 2 top ! ;
: title		home text org ;

: bullet	S" * " text 2 left +! text -2 left +! 1 top +! ;

