\ Utilities and useful constants.  Some of these will be machine-specific.

1 cells constant /cell
1 chars constant /char

/cell negate constant -/cell
/cell 1- constant CellMask

$FFFFFFFFFFF00000 constant RomBase

\ Memory is laid out as follows:
\ 
\ +-----------+------+-------------+
\ | code -->  | //// | <-- headers |
\ +-----------+------+-------------+
\             ^      ^
\     dictp --+      +-- headp
\ 
\ dictp increases as code/data space is consumed.
\ As new words are defined, headp decrements.
\ Note that this space does not include data or return stacks.

1048576 constant /dict		\ space to store compiled code and headers
create dict
  /dict allot
dict /dict + constant dictEnd
variable dictp			\ ptr to next byte to compile code or data to
variable headp			\ ptr to last created dictionary header
variable tcontext		\ ptr to last defined header that's visible
variable dictOrg		\ base address for the dictionary image

: torg			dictOrg ! ;
: safe			dictp @ headp @ u>= abort" out of header space" ;
: dict0			dict dictp !  dictEnd headp !  dictEnd tcontext ! ;
: h>t ( a - ta )	dict - dictOrg @ + ;
: t>h ( ta - a )	dictOrg @ - dict + ;

dict0
RomBase torg			\ Kestrel-3's ROM sits at -1MB.


\ \ \ \ \ \
\ Definition constructors

: there ( - a )		dictp @ h>t ;
: talign ( n - )	dup 1- dictp @ + swap negate and dictp ! ;
: tallot ( n - )	dictp +! safe ;
: t! ( n ta - )		t>h ! ;
: tc! ( n ta - )	t>h c! ;
: t@ ( ta - n )		t>h @ ;
: tc@ ( ta - n )	t>h c@ ;
: t, ( n - )		8 talign  there t!  /cell tallot ;
: tc, ( n - )		there tc!  /char tallot ;

\ \ \ \ \ \
\ Headers
\ 
\ Headers take on the following structure:
\ 
\ +0	Code field address
\ +8	Parameter field address
\ +16	Name length
\ +17..	Name
\ 
\ To construct a header, you typically invoke
\ tname, to place the name in memory first, followed by
\ two calls to th, to construct the CFA and PFA.  After
\ doing that, headp will point to the new header.
\ The new word will be "smudged" though, since the
\ search context will not have been updated yet.


: round			CellMask + -/cell and ;
: dec ( a u - a u )	dup 1+ round negate headp +! ;
: place ( a u - )	dup headp @ c!  headp @ 1+ swap move ;
: tname, ( a u - )	dec safe place ;
: th, ( n - )		-/cell headp +!  safe  headp @ ! ;
: thead, ( cfa a u - )	tname, there th, th, ;
: treveal		headp @ tcontext ! ;

: skip ( a - a' )	2 cells + dup c@ round + ;
: 3dup ( abc - abcabc)	>r 2dup r@ -rot r> ;
: tfind ( a u - x T | a u F )
  tcontext @ begin
    dup dictEnd u>= if drop 0 exit then
    3dup 2 cells + count compare 0= if nip nip -1 exit then
    skip
  again ;

