\ Utilities and useful constants.  Some of these will be machine-specific.

1 cells constant /cell
1 chars constant /char
4 chars constant /word

/cell negate constant -/cell
/cell 1- constant CellMask

$FFFFFFFFFFF00000 constant romOrg

\ Memory is laid out as follows:
\ 
\ $0FFFFFFFFFFF00000			 $0FFFFFFFFFFFFFF00
\ |							  |
\ V							  V
\ +-----------+------+-------------+-----------------/ /--+---------+
\ | code -->  | //// | <-- headers | IRQ vectors ... \ \  | Linkage |
\ +-----------+------+-------------+-----------------/ /--+---------+
\	      ^      ^		   ^
\	      |      |		   |
\      romp --+      +-- headp	   +-- $0FFFFFFFFFFFFFE00
\ 
\ romp increases as code/data space is consumed.
\ As new words are defined, headp decrements.
\ Note that this space does not include data or return stacks.
\ Linkage information is stored in last 256 bytes of ROM, like so:
\ 
\	+----------------------+
\ +0	| JAL to bootstrap     | (cold-boot entry point)
\	+----------------------+
\ +8	| unused	       |
\ ...	:		       :
\	+----------------------+
\ +248	| addr of first header | (value of "headp @ h>t" after assembly )
\	+----------------------+

1048576 constant /rom		\ space to store compiled code and headers
create rom
  /rom allot
rom /rom + constant romEnd	\ end of ROM ($10000000000000000 mod 64-bits)
romEnd 512 - constant headEnd	\ end of dictionary headers
variable romp			\ ptr to next byte to compile code or data to
variable headp			\ ptr to last created dictionary header
variable tcontext		\ ptr to last defined header that's visible
variable safety			\ TRUE to enable bounds checks.
safety on

: check			romp @ headp @ u>= abort" out of header space" ;
: safe			safety @ if check then ;
: rom0			rom /rom $CC fill  rom romp ! headEnd headp ! 0 tcontext ! ;
: h>t ( a - ta )	rom - romOrg + ;
: t>h ( ta - a )	romOrg - rom + ;

rom0


\ \ \ \ \ \
\ Definition constructors

: there ( - a )		romp @ h>t ;
: talign ( n - )	dup 1- romp  @ + swap negate and romp  ! ;
: tallot ( n - )	romp  +! safe ;
: t! ( n ta - )		t>h ! ;
: tc! ( n ta - )	t>h c! ;
: t@ ( ta - n )		t>h @ ;
: tc@ ( ta - n )	t>h c@ ;
: t, ( n - )		/cell talign  there t!	/cell tallot ;
: (tc) ( n - )		dup there tc!  /char tallot  8 rshift ;
: tc, ( n - )		(tc) drop ;
: tw, ( n - )		/word talign (tc) (tc) (tc) (tc) drop ;

\ \ \ \ \ \
\ Headers
\ 
\ Headers take on the following structure:
\ 
\       +--------------------------+
\ +0	| Code field address       |
\       +--------------------------+
\ +8	| Parameter field address  |
\       +--------------------------+
\ +16	| Link address | 0 | C | I |
\       +--------------------------+
\ +24   | Len | Name               |
\ ...   \                          \
\ ...	| ...name | opt. padding   |
\       +--------------------------+
\
\ The code field address points to the executor or handler
\ for the word; this must be a chunk of RISC-V machine code.
\ It's what provides the run-time semantics for the word.
\ 
\ The parameter field address really depends on the nature
\ of the handler for the word.  For USER and GLOBAL variables,
\ the parameter field address is really a byte offset from some
\ base address or register.  For most other words, it points
\ into the dictionary space, usually at either a buffer of some
\ kind, or a list of other header references ("execution
\ tokens").
\ 
\ The link address points to the next most recently defined
\ word in the current vocabulary.  Since headers are always
\ aligned to 8 bytes, the lower three bits are re-used as flags.
\ 
\ The C bit is set for a word which is to be used only when
\ compiling.  It's typically asserted by the COMPILE-ONLY word.
\ The I bit is set for a word which is to be invoked, rather
\ than compiled, during compilation.  The word IMMEDIATE sets
\ this flag.
\ 
\ The Name field consists of a single byte containing the
\ length of the name that follows, then following that,
\ the actual bytes of the name.  Up to 255 characters are
\ supported in this version of Forth.  Note that names are
\ padded with NULs to make the total name field an even
\ multiple of eight in length.
\ 
\ To construct a header, you typically invoke
\ tname, to place the name in memory first, followed by
\ three calls to th, to construct the CFA, PFA, and link.
\ After doing that, headp will point to the new header.
\ The new word will be "smudged" though, since the
\ search context will not have been updated yet.


: round			CellMask + -/cell and ;
: dec ( a u - a u )	dup 1+ round negate headp +! ;
: padded		headp @ over 8 + -8 and 0 fill ;
			( 8 + instead of 7 + to acct. for length byte )
: place ( a u - )	padded dup headp @ c! headp @ 1+ swap move ;
: tname, ( a u - )	dec safe place ;
: th, ( n - )		-/cell headp +!  safe  headp @ ! ;
: thead, ( cfa a u - )	tname, tcontext @ th, there th, th, ;
: treveal		headp @ h>t tcontext ! ;

: lfa			tcontext @ t>h 2 cells + ;
: timmediate		lfa dup @ 1 or swap ! ;
: tcompile-only		lfa dup @ 2 or swap ! ;

: skip ( a - a' )	2 cells + @ -8 and ;

: 3dup ( abc - abcabc)	>r 2dup r@ -rot r> ;
: tfind ( a u - x T | a u F )
  tcontext @
  begin dup while
    t>h 3dup 3 cells + count compare 0= if nip nip -1 exit then
    skip
  repeat ;

: t'	32 word count tfind 0= if type -1 abort" ?" then h>t ;
: [t']	t' postpone literal ; immediate

