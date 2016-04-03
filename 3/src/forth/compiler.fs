tcode (next)
	0 ip w ld,
	8 ip ip addi,
	0 w x9 ld,
	0 x9 x0 jalr,
tend-code

: next,		S" (next)" tfind drop @ there - x0 jal, ;

tcode (enter)
	-8 rsp rsp addi,
	0 rsp ip sd,
	8 w ip ld,
	next,
tend-code

tcode (dolit)
	0 ip x9 ld,
	8 ip ip addi,
	-8 dsp dsp addi,
	0 dsp x9 sd,
	next,
tend-code

: err		cr cr type -1 abort" ?" ;
: hex?		[char] $ over = swap ;
: char?		[char] ' over = swap ;
: negative?	[char] - over = swap ;
: digit?	$30 $3A within ;
: nbr?		hex? char? negative? digit? or or or ;
: nbr		over c@ nbr? if evaluate [t'] (dolit) t, t, else err then ;
: docolon	[t'] (enter) t>h @ ;
: :head,	docolon 32 word count thead, ;
: ?refill	>in @ source nip = if refill 0= abort" EOF?" then ;

create macrobuf 32 allot
: prefix	[char] ~ macrobuf 1+ c! ;
: suffix	dup 1+ macrobuf c! macrobuf 2 + swap move ;
: >macro	prefix count 30 min suffix macrobuf ;

: word,
  32 word dup >macro find if
    nip execute
  else
    drop count tfind if h>t t, else nbr then
  then
;

: t:		8 talign :head, begin ?refill word, again ;

tcode exit
	0 rsp ip ld,
	8 rsp rsp addi,
	next,
tend-code

: ~;		[t'] exit t, treveal r> r> 2drop ;

\ Comment support inside of colon definitions.
: ~(		postpone ( ;
: ~\		postpone \ ;

\ (doglobal) implements the handler for GLOBAL and CGLOBAL
\ variables.  The semantics of such variables are to push
\ the address of the variable on the data stack.  Unlike
\ USER variables, globals are relative to address 0.
\ 
\ The PFA of a GLOBAL variable does not point to the
\ parameter field of the word.  Instead, it contains
\ the byte offset from the globals pool (currently 0).
\ 
\ The global variable /GLOBALS contains the current
\ number of bytes allocated to globals.  Since /GLOBALS
\ is itself a global variable, /GLOBALS must always be
\ at least one cell in size.  The current version of
\ Forth permits up to 1024 bytes of global variables.
\ Remember that a single cell is 8 bytes wide.
tcode (doglobal)
	8 w x9 ld,
	-8 dsp dsp addi,
	0 dsp x9 sd,
	next,
tend-code

variable /globals
/globals off

: doglob	[t'] (doglobal) t>h @ ;
: ghead,	doglob 32 word count thead, treveal ;
: galign	dup 1- /globals @ + swap negate and /globals ! ;
: g!pfa		/globals @ headp @ cell+ ! ;

: tglobal	ghead, 8 galign g!pfa 8 /globals +! ;
: twglobal	ghead, 4 galign g!pfa 4 /globals +! ;
: thglobal	ghead, 2 galign g!pfa 2 /globals +! ;
: tcglobal	ghead, g!pfa 1 /globals +! ;

tglobal /GLOBALS

