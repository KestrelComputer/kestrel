S" pass1.fs" included

\ The new colon compiler starts here.  It's technically part of
\ pass 1 implementation, but ; drives subsequent passes as well.

host definitions

: :0		buf0 fi0 ni0 label0 ;
: :,		:0 bl word drop ;
: ;,		rfs, ;

target definitions

:: :		:, ;;
:: ;		;, ;;

host definitions
