S" pass1.fs" included
S" lgp.fs" included
S" prolog-epilog.fs" included
S" regs.fs" included

\ The new colon compiler starts here.  It's technically part of
\ pass 1 implementation, but ; drives subsequent passes as well.

host definitions

: :0		buf0 fi0 ni0 label0 esp0 regmask0 ;
: pass1		:0 bl word drop ;
: ;,		rfs, lgp prolog epilogs reg ;

target definitions

:: :		pass1 ;;
:: ;		;, ;;

host definitions
