include asm.f
0symtab
0 org
target
defer _main
: 8*        3 lshift ;
: 16*       4 lshift ;
: 80*       4 lshift dup 2 lshift + ;
: 256*      8 lshift ;
: 640*      80* 8* ;
: 0<        $8000 and ;
: max       2dup - 0< if nip exit then drop ;
: min       2dup - 0< if drop exit then nip ;
: @     @, ;

: c@        dup 1 and if @ 255 and exit then @ 8 rshift 255 and ;
: even!     swap 8 lshift over @ 255 and or swap ! ;
: odd!      swap 255 and over @ $FF00 and or swap ! ;
: c!        dup 1 and if odd! exit then even! ;

: +!            2dup @ + swap ! drop ;
variable x
variable y
variable TdfChrMtx
variable raster

create font
include font.inc

: chradr    y @ 80* x @ + TdfChrMtx @ + ;
: glyph     font + raster @ 256* + ;
: bmadr     y @ 640* raster @ 80* + x @ + $8000 + ;
: s         chradr c@ glyph c@ bmadr c!  1 raster @ + raster ! ;
: c         0 raster !  s s s s  s s s s  1 x @ + x ! ;
: 10c       c c c c c  c c c c c ;
: 80c       10c 10c 10c 10c  10c 10c 10c 10c ;
: r         80c  0 x ! 1 y @ + y ! ;
: 8r        r r r r  r r r r ;
: 25r       8r 8r 8r r ;
: commit    0 x !  0 y !  25r ;

variable x
variable y
: confine   x @ 0 max 79 min x !   y @ 0 max 24 min y ! ;
: at-xy     y ! x ! confine ;
: up        -1 y +! confine ;
: down       1 y +! confine ;
: left      -1 x +! confine ;
: right      1 x +! confine ;
: address       y @ 640* x @ + $8000 + ;
variable blst
: b             dup dup c@ invert swap c! 80 + ;
: blink         address b b b b b b b b drop  blst @ -1 xor blst ! ;
: coff          blst @ if blink then ;
variable blct
: blinker       1 blct @ + dup 49152 xor if blct ! exit then drop blink 0 blct ! ;
variable commit?
: ?commit       commit? @ if coff commit blink 0 commit? ! then ;
create scrn
    2000 allot
: clr           dup if swap 32 over c! 1 + swap -1 + recurse exit then 2drop ;
: page          TdfChrMtx @ 2000 clr  0 x !  0 y ! ;
: plot          TdfChrMtx @ y @ 80* x @ + + c! ;
: emit          plot right -1 commit? !  ;
: type          dup if over c@ emit -1 + swap 1 + swap recurse exit then 2drop ;
: cr            0 x ! down ;
: dstack        $3F00 ;
: rstack        dstack 64 + ;
variable memptr
: GO
  $3F7E @ >r $3F7C @ >r $3F7A @ >r $3F78 @ >r
  $3F76 @ >r $3F74 @ >r $3F72 @ >r $3F70 @ >r
  $3F6E @ >r $3F6C @ >r $3F6A @ >r $3F68 @ >r
  $3F66 @ >r $3F64 @ >r $3F62 @ >r $3F60 @ >r
  $3F5E @ >r $3F5C @ >r $3F5A @ >r $3F58 @ >r
  $3F56 @ >r $3F54 @ >r $3F52 @ >r $3F50 @ >r
  $3F4E @ >r $3F4C @ >r $3F4A @ >r $3F48 @ >r
  $3F46 @ >r $3F44 @ >r $3F42 @ >r $3F40 @ >r
  $3F3E @    $3F3C @    $3F3A @    $3F38 @
  $3F36 @    $3F34 @    $3F32 @    $3F30 @
  $3F2E @    $3F2C @    $3F2A @    $3F28 @
  $3F26 @    $3F24 @    $3F22 @    $3F20 @
  $3F1E @    $3F1C @    $3F1A @    $3F18 @
  $3F16 @    $3F14 @    $3F12 @    $3F10 @
  $3F0E @    $3F0C @    $3F0A @    $3F08 @
  $3F06 @    $3F04 @    $3F02 @    $3F00 @ ;
: space         $20 emit ;
: .n            $F and S" 0123456789ABCDEF" drop + c@ emit ;
: .b            dup 4 rshift .n .n ;
: .w            dup 8 rshift .b .b space ;
: w             dup @ .w 2 + ;
: words         w w w w w w w w ;
: c             dup c@ emit 1 + ;
: chars         c c c c c c c c  c c c c c c c c ;
: dump          words S" -- " type -16 + chars cr drop ;
: d00           S" D+ 00  " type $3F00 dump ;
: d10           S" D+ 10  " type $3F10 dump ;
: d20           S" D+ 20  " type $3F20 dump ;
: d30           S" D+ 30  " type $3F30 dump ;
: dstk          d00 d10 d20 d30 cr ;
: r00           S" R+ 00  " type $3F40 dump ;
: r10           S" R+ 10  " type $3F50 dump ;
: r20           S" R+ 20  " type $3F60 dump ;
: r30           S" R+ 30  " type $3F70 dump ;
: rstk          r00 r10 r20 r30 cr ;
: m             S" M+ " type dup .b space space dup memptr @ + dump 16 + ;
: mem           S" M= " type memptr @ .w cr 0 m m m m m m m m drop cr ;
: banner        S" Kestrel Preen 1A" type cr cr ;
: display
  page banner
  dstk rstk mem
  S" GO" type cr ;
variable tib
variable #tib
variable >in
: pch           >in @ tib @ + ;
: ch            pch c@ ;
: -eoln         >in @ #tib @ - 0< if exit then r> drop ;
: ws?           ch $21 - 0< ;
: ws            -eoln ws? if 1 >in +! recurse exit then ;
: txt           -eoln ws? if exit then 1 >in +! recurse ;
: word          ws pch txt pch over - ;
variable v
: digit         -48 + dup -10 + 0< if exit then -7 + ;
: d             over c@ digit v @ 4 lshift or v ! ;
: hex>n         dup if d -1 + swap 1 + swap recurse exit then 2drop ;
: nbr           0 v ! word hex>n v @ ;
: w             nbr over !  2 + ;
: chg           w w w w w w w w drop ;
: D+            nbr dstack + chg ;
: R+            nbr rstack + chg ;
: M+            nbr memptr @ + chg ;
: M=            nbr memptr ! ;
create wproc
    ' D+ >body 2/ ,  ' R+ >body 2/ , ' M= >body 2/ , ' M+ >body 2/ , ' GO >body 2/ ,
create wtab
    $442B , $522B , $4D3D , $4D2B , $474F ,
: proc          wtab - wproc + @ ;
: -fnd          2dup @ xor if 2 + exit then nip proc r> r> 2drop ;
: -found        wtab -fnd -fnd -fnd -fnd -fnd nop, ;
create display'
    ' display >body 2/ ,
: find          drop @ -found drop display' @ ;
: +valid        dup if exit then r> drop ;
: interpret     word +valid find >r nop, ;
: complete      y @ 80* TdfChrMtx @ + tib !  80 #tib !  0 >in !  interpret display ;
create rawcodes
    $0045 , $0016 , $001E , $0026 ,
    $0025 , $002E , $0036 , $003D ,
    $003E , $0046 , $001C , $0032 ,
    $0021 , $0023 , $0024 , $002B ,
create cookedcodes
    $0030 , $0031 , $0032 , $0033 ,
    $0034 , $0035 , $0036 , $0037 ,
    $0038 , $0039 , $0041 , $0042 ,
    $0043 , $0044 , $0045 , $0046 ,
: >ascii        rawcodes - cookedcodes + @ ;
: kbhit         >ascii emit 2drop drop ;
: -match        2dup @ xor if exit then kbhit r> r> 2drop r> r> drop ;
: r             -match 2 + ;
: -found        r r r r  r r r r  r r r r  r r r r ;
: -valid        dup rawcodes -found 2drop ;
: -up           dup $0175 xor if exit then up r> 2drop ;
: -down         dup $0172 xor if exit then down r> 2drop ;
: -left         dup $016B xor if exit then left r> 2drop ;
: -right        dup $0174 xor if exit then right r> 2drop ;
: -enter        dup $005A xor if exit then complete r> 2drop ;
: dispatch      -up -down -left -right -enter -valid drop ;
: keycode       coff dispatch blink ;
variable s
: -$E0          dup $E0 xor if exit then $0100 s @ or s !  r> 2drop ;
: -$F0          dup $F0 xor if exit then $8000 s @ or s !  r> 2drop ;
: filter        -$E0 -$F0 s @ or keycode 0 s ! ;
: available?    $FFFE @ 0< ;
: mbc           $FFFE @ $00FF and ;
: ack           $0300 $FFFE ! ;
: keyboard      available? if mbc filter ack then ;
: ui...         ?commit blinker keyboard recurse ;
: ui            0 s !  0 blst !  ui... coff ;
: breakpoint
  $3F00 !  $3F02 !  $3F04 !  $3F06 !
  $3F08 !  $3F0A !  $3F0C !  $3F0E !
  $3F10 !  $3F12 !  $3F14 !  $3F16 !
  $3F18 !  $3F1A !  $3F1C !  $3F1E !
  $3F20 !  $3F22 !  $3F24 !  $3F26 !
  $3F28 !  $3F2A !  $3F2C !  $3F2E !
  $3F30 !  $3F32 !  $3F34 !  $3F36 !
  $3F38 !  $3F3A !  $3F3C !  $3F3E !
  r> $3F40 !  r> $3F42 !  r> $3F44 !  r> $3F46 !
  r> $3F48 !  r> $3F4A !  r> $3F4C !  r> $3F4E !
  r> $3F50 !  r> $3F52 !  r> $3F54 !  r> $3F56 !
  r> $3F58 !  r> $3F5A !  r> $3F5C !  r> $3F5E !
  r> $3F60 !  r> $3F62 !  r> $3F64 !  r> $3F66 !
  r> $3F68 !  r> $3F6A !  r> $3F6C !  r> $3F6E !
  r> $3F70 !  r> $3F72 !  r> $3F74 !  r> $3F76 !
  r> $3F78 !  r> $3F7A !  r> $3F7C !  r> $3F7E !
scrn TdfChrMtx !  display ui ;
: b breakpoint  recurse ;
' b is _main
host  there . s" bytes compiled" type cr  romfile  bye
