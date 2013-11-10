#! /usr/bin/gforth

\ Assembler for the S16X4A (written in ANS Forth)

\ \ \ PROGRAM IMAGE BUFFER, and how to read and write from/to it.

: TWORDS		2* ;

\ Number of words in the assemble buffer itself.  This determines how long
\ a program you can compile before you encounter a buffer overflow and crash
\ your assembler.
8192 CONSTANT #WORDS

\ The number of words for the largest program you can assemble.
\ This is set independently because, although the Kestrel-2A can
\ address 16KB of program memory, it's really only convenient to
\ copy-and-paste Verilog defparams for 4KB.  The limit, then,
\ helps avoid a bug where you're assembling more code than you're
\ pasting into the Verilog source code.  Useful only for bootstrap
\ code.
\ 
\ It also is useful to avoid the buffer overflow that I mentioned
\ above.  Thus, #LIMIT <= #WORDS.
8192 CONSTANT #LIMIT

: check		#WORDS #LIMIT U< ABORT" #WORDS must be at least equal to #LIMIT, if not greater." ;
check

\ The byte-size of the PIB.
#WORDS TWORDS CONSTANT /pib

\ Number of entries in the relocation offset buffer
#WORDS CONSTANT /relocb

\ Number of initialization lines to produce per defparam block.
64 CONSTANT #INITS

CREATE pib	/pib CHARS ALLOT
pib /pib $CD FILL

CREATE relocb	/relocb CELLS ALLOT
relocb /relocb CELLS $CD FILL

VARIABLE pibptr

: align,	pibptr @ 1+ -2 AND pibptr ! ;
: >pib		pib + ;
: even		DUP 1 AND ABORT" Attempt to write a word to an odd address." ;
: inside	DUP [ #LIMIT TWORDS ] LITERAL u>= ABORT" Attempt to write outside the Program Image Buffer." ;
: le!		2DUP C! 1+ SWAP 8 RSHIFT SWAP C! ;
: le@		DUP C@ $FF AND SWAP 1+ C@ 8 LSHIFT OR ;
: pib!		even inside >pib le! ;
: pib@		even inside >pib le@ ;
: pibc!		inside >pib c! ;
: pibc@		inside >pib c@ ;
: pib,		pibptr @ pib!  1 TWORDS pibptr +! ;
: pibc,		pibptr @ pibc!	1 pibptr +! ;
: allot,	pibptr +! align, ;

\ \ \ VERILOG DUMPER

variable ptr
variable param
variable even?
variable bank
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
: 64*		2* 2* 2* 2* 2* 2* ;
: ptr0		param @ bank @ 64* OR 64* 62 OR even? @ OR ptr ! ;
: .eq		ptr0 .program .eod ." .INIT_" .param ."  = 256'h" .32bytes ?., CR ;
: image		0 param ! BEGIN param @ #INITS = IF EXIT THEN .eq 1 param +! AGAIN ;
: even		0 even? ! ;
: odd		1 even? ! ;
: program	32 parse /program_name min dup #program_name ! program_name swap move ;

0 bank !

\ \ \ INSTRUCTION ACCUMULATOR/BUILDER

variable iptr
variable slot
variable relocptr
0 relocptr !

: enforce	pibptr @ iptr !  0 pib,  $F000 slot ! ;
: bblk		slot @ $F000 XOR IF align, enforce THEN ;
: eject		0 slot ! ;
: slot>>	slot @ 2/ 2/ 2/ 2/ $0FFF AND slot ! ;
: repl		15 AND DUP 2* 2* 2* 2* OR DUP $0100 * OR ;
: pack		repl slot @ AND iptr @ pib@ OR iptr @ pib! slot>> ;
: opc ( n -- )	slot @ 0= IF bblk THEN pack ;
: #, ( n -- )	1 opc pib, ;
: reloc,	pibptr @  relocb relocptr @ + !  1 cells relocptr +! ;
: &, ( n -- )   slot @ 0= IF bblk THEN reloc, #, ;
: prim		CREATE , DOES> DUP @ opc @ 12 15 WITHIN IF bblk THEN ;

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

12 prim LCALL,  ( -- )
13 prim ICALL,  ( -- )
14 prim GO,	( -- )
15 prim NZGO,	( -- )

\ \ \ SYMBOL TABLE (or, something that emulates one, more or less)
\ \ \ Also, SUBROUTINE PRIMITIVES (in this case, it makes sense to
\ \ \ combine the two into a single layer).

VARIABLE rpa ( Return Pointer Address )
defer again,

: call,		bblk &, ICALL, ;
: DEFER,	bblk CREATE iptr @ , 0 &, GO, DOES> @ call, ;
: IS,		' >body @ 1 TWORDS + pib! ;
: preamble	iptr @ -1 TWORDS + &, !, bblk ;
: rtnword	bblk iptr @ rpa ! 1 TWORDS iptr +! 0 pib, ;
: loop,		rpa @ 3 TWORDS + &, go, ;
: :,		['] loop, is again,  CREATE rtnword iptr @ , preamble DOES> @ call, ;
: EXIT,		rpa @ &, @, GO, ;
: ;,		EXIT, ;

\ \ \ Structured Programming Primitives

: if,		lit, pibptr @ reloc, 0 pib, zgo, ;
		\ pibptr @ 0 #, zgo, doesn't work because the assembler is lazy about
		\ starting new instruction packets.
: else,		lit, pibptr @ reloc, 0 pib, go,  swap  bblk iptr @ swap pib! ;
: then,		bblk iptr @ swap pib! ;
: (again,)	&, go, ;
: begin,	['] (again,) is again,  bblk iptr @ ;
: while,	if, swap ;
: repeat,	&, go,  then, ;
: until,	&, zgo, ;

: int,		align, CREATE pibptr @ ,  eject  0 pib, DOES> @ &, ;
: char,		CREATE pibptr @ ,  eject  0 pibc, DOES> @ &, ;
: create,	CREATE pibptr @ ,  eject  DOES> @ &, ;
: const,	CREATE , DOES> @ #, ;

\ \ \ Support for recursive subroutine calls.

$FFFE const, %fp

: callr,	bblk pibptr @ 4 TWORDS + &, %fp @, !, &, GO, ;
: icallr,	bblk pibptr @ 3 TWORDS + &, %fp @, !, GO, ;

: +fp@,		TWORDS #, %fp @, +, @, ;
: +fp!,		TWORDS #, %fp @, +, !, ;
: fp+!,		TWORDS #, %fp @, +, %fp !, ;

: sub:		CREATE bblk iptr @ , DOES> @ callr, ;
: rfs,		%fp @, @, go, ;

\ \ \ Miscellanious

: origin	pibptr !  eject ;
: C,,		pibc, ;
: ,,		pib, ;
: C",		34 parse dup c,, pibptr @ >pib swap dup allot, move ;

\ \ \ Support for binary file inclusion

4096 constant /incbuf
create incbuf	/incbuf allot
variable #bytes
variable fh

: copy		incbuf pibptr @ >pib #bytes @ MOVE  #bytes @ pibptr +!  eject ;
: close		fh @ CLOSE-FILE THROW ;
: ?fit		pibptr @ #bytes @ + /pib U>= IF close -1 ABORT" too big" THEN ;
: ?eof		DUP IF #bytes ! EXIT THEN  close r> drop ;
: ?err		DUP IF close THROW THEN DROP ;
: get		incbuf /incbuf fh @ READ-FILE ;
: open		[CHAR] " PARSE R/O BIN OPEN-FILE THROW fh ! ;
: incbin"	open BEGIN get ?err ?eof ?fit copy AGAIN ;

\ \ \ Support for binary file creation

: write		pib pibptr @ fh @ WRITE-FILE THROW ;
: _create	[CHAR] " PARSE R/W BIN CREATE-FILE THROW fh ! ;
: out"		_create write close ;

\ \ \ Support for Hunk-format file creation (relocatable)

880 constant T_HUNK
881 constant T_CODE
882 constant T_END
883 constant T_RELOC

variable wrd
: wrword	wrd 2 fh @ WRITE-FILE THROW ;
: thunk		T_HUNK wrd !  wrword ;
: tcode		T_CODE wrd !  wrword  pibptr @ wrd !  wrword ;
: treloc	T_RELOC wrd !  wrword  relocptr @ 1 CELLS / wrd !  wrword ;
: tend		T_END wrd !  wrword ;
: relocs	0 BEGIN DUP relocptr @ < WHILE  DUP relocb + @ wrd ! wrword  CELL+ REPEAT DROP ;
: reloc"	_create thunk tcode write treloc relocs tend close ;


