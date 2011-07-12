include asm.f
0symtab
0 org target
defer _main

0 [if]
: plhm      $3CFF $8000 ! $66FF $8050 ! $6EFF $80A0 ! $6EFF $80F0 ! $60FF $8140 ! $66FF $8190 ! $3CFF $81E0 ! $00FF $8230 ! recurse ;
[then]

0 [if]
: plrw      over ! 80 + ;
: plhm      $8000  $3C plrw $66 plrw $6E plrw $6E plrw $60 plrw $66 plrw $3C plrw $00 plrw drop   recurse ;
[then]

create atsign
    $3C , $66 , $6E , $6E , $60 , $66 , $3C , $00 ,

: @         @, ;
: plrw      over @ over ! 80 + swap 2 + swap ;
: plhm      atsign $8000 plrw plrw plrw plrw  plrw plrw plrw plrw 2drop recurse ;
' plhm is _main

0 [if]
create font
include font.inc

: @         @, ;
: -1        $FFFF ;
: cyc       dup if -1 + recurse exit then drop ;
: 64kcyc    dup if -1 + $FFFF cyc recurse exit then drop ;
: 1sec      8 64kcyc ;
: c@        dup 1 and if @ 255 and exit then @ 8 rshift 255 and ;
: even!     swap 8 lshift over @ 255 and or swap ! ;
: odd!      swap 255 and over @ $FF00 and or swap ! ;
: c!        dup 1 and if odd! exit then even! ;
: r         over c@ over c! 80 + swap 256 + swap ;
: plch      font + $8000 r r r r r r r r 2drop ;
: pl        plch 1sec ;
: chrs      dup 256 xor if dup pl 1 + recurse exit then drop ;
: main      33 chrs recurse ;

' main is _main
[then]

host
romfile
bye

