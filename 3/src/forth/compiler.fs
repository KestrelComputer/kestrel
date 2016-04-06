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

tcode doLIT
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
: nbr		over c@ nbr? if evaluate [t'] doLIT t, t, else err then ;
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

tcode EXIT
	0 rsp ip ld,
	8 rsp rsp addi,
	next,
tend-code

: ~;		[t'] EXIT t, treveal r> r> 2drop ;

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

\ (douser) implements the handler for USER and CUSER
\ variables.  The semantics of such variables are to push
\ the address of the variable on the data stack.  Unlike
\ GLOBAL variables, user variables are relative to the
\ current address found in the UP (user-pointer) register.
\ 
\ The PFA of a USER variable does not point to the
\ parameter field of the word.  Instead, it contains
\ the byte offset from the current value of UP.
\ 
\ The global variable /USER contains the current
\ number of bytes allocated to globals.
tcode (douser)
	8 w x9 ld,
	up x9 x9 add,
	-8 dsp dsp addi,
	0 dsp x9 sd,
	next,
tend-code

variable /user
/user off

: douser	[t'] (douser) t>h @ ;
: uhead,	douser 32 word count thead, treveal ;
: ualign	dup 1- /user @ + swap negate and /user ! ;
: u!pfa		/user @ headp @ cell+ ! ;

: tn		headp @ CELL+ CELL+ CELL+ count type ;
: tuser		uhead, 8 ualign u!pfa 8 /user +! ;
: twuser	uhead, 4 ualign u!pfa 4 /user +! ;
: thuser	uhead, 2 ualign u!pfa 2 /user +! ;
: tcuser	uhead, u!pfa 1 /user +! ;

tglobal /USER

\ (dovar) implements the semantics for VARIABLEs.
\ These differ from globals in that their storage appears
\ inline in the dictionary with the code, as per more
\ traditional Forth behaviors.  They are treated just like
\ GLOBAL variables, except for where their storage is found.
\ GLOBALs exist because of a circular dependency: we need
\ variables to store important Forth runtime information
\ before we have enough machinery in place to handle normal
\ VARIABLEs.
\ 
\ (dovar) is also the default handler for CREATE'd words,
\ since a variable is just a CREATE-d word with a single-cell
\ buffer after it.
tcode (dovar)
	8 w x9 ld,
	-8 dsp dsp addi,
	0 dsp x9 sd,
	next,
tend-code

: tcreate	[t'] (dovar) t>h @ 32 word count thead, treveal ;

\ LSHIFT and RSHIFT are low-level bit manipulators.
\ Note that RSHIFT is a *logical* right shift, not an
\ arithmetic right shift.
tcode LSHIFT
	0 dsp x8 ld,
	8 dsp x9 ld,
	x8 x9 x9 sll,
	8 dsp x9 sd,
	8 dsp dsp addi,
	next,
tend-code

tcode RSHIFT
	0 dsp x8 ld,
	8 dsp x9 ld,
	x8 x9 x9 srl,
	8 dsp x9 sd,
	8 dsp dsp addi,
	next,
tend-code

