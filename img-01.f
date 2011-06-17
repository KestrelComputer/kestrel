0 [if]
0 org
defer _main
: gfx       dup $2000 xor if dup @ $5555 xor over ! cell+ exit then drop $1000 ;
: main      $1000 begin gfx again ;
' main is _main
[then]

target

0 org
defer _main

include font.inc

: cell+     2 + ;
: flip      dup @ $5555 xor over ! ;
: main0     dup $9000 xor if flip cell+ recurse exit then ;
: main      $8000 main0 drop recurse ;
' main is _main

host

