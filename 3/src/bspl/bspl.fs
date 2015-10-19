#! /usr/bin/env gforth

warnings off

\ Utility words that have no better place to go.
: inc		1 swap +! ;

S" bspl.fm/syms.fs" included

S" bspl.fm/pass1.fs" included
S" bspl.fm/lgp.fs" included
S" bspl.fm/prolog-epilog.fs" included
S" bspl.fm/regs.fs" included
S" bspl.fm/asm.fs" included

\ External definitions have symbol table entries, but don't exist in the
\ current program listing.  Therefore, we fake such definitions by injecting
\ a name directly into the symbol table, and using the resulting ordinal to
\ fake a word which, when invoked, compiles a call to that routine.
: extern	>in @ bl word count define swap >in ! create , does> @ call, ;

\ Jump tables are important structures, permitting polymorphic
\ program execution.  Note that these constructs exist outside
\ of any colon definition; therefore, they emit raw assembly
\ language immediately!

  ( I'd like to find a better place to put this code. )
  ( Unfortunately, I have a bit of a circular dependency if )
  ( I place it where it logically should go. )

: jtasm		."  align 8" cr 32 word count type ." :" cr
		."  jal t0, __jumptable__" cr ;
: jump-table,	>in @ jtasm >in ! extern ;
: entry,	32 word count 2dup S" ;" compare if ."  jal x0, " type cr 1 else 0 then ;
: jump-entries,	begin entry, 0= until ;

target definitions

:: jump-table:		jump-table, ;
:: jump-entries:	jump-entries, ;

host definitions

\ The new colon compiler starts here.  It's technically part of
\ pass 1 implementation, but ; drives subsequent passes as well.

host definitions

: :0		buf0 fi0 ni0 esp0 regmask0 ;
: pass1		:0 extern ;
: passes	lgp prolog epilogs reg asm ;
: ;,		rfs, passes ;
: (bye)		bye ;

target definitions

:: :		pass1 ;;
:: ;		;, ;;

host definitions

strlitctr0 gvpofs0 label0
target
next-arg included
host
(bye)

