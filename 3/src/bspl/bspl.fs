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

