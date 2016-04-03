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
: nbr?		[char] $ over = swap [char] ' over = swap $30 $3A within or or ;
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

