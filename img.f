include asm.f
0symtab
0 org target
defer _main

: @         @, ;
: -1        $FFFF ;
: cyc       dup if -1 + recurse exit then drop ;
: 64kcyc    dup if -1 + $FFFF cyc recurse exit then drop ;
: 1sec      8 64kcyc ;
: wtf       $8000 @ invert $8000 ! $8002 @ 1 + $8002 ! 1sec recurse ;
: plch      drop 32768 @ -1 xor 32768 ! ;
: pl        plch 1sec ;
: chrs      dup 256 xor if dup pl 1 + recurse exit then drop ;
: main      0 chrs recurse ;

' wtf is _main

host
romfile
bye
