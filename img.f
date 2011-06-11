0 org
defer _main
: gfx       dup $2000 xor if dup @ $5555 xor over ! cell+ exit then drop $1000 ;
: main      $1000 begin gfx again ;
' main is _main

