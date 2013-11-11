defer, happyboot

include INC.STS.SYS.fs

int, p
int, q

2 base !
create, happyicon
0001100000011000 ,,
0111111001111110 ,,
1000000000000001 ,,
0001100000011000 ,,
0000100000001000 ,,
0000000010000000 ,,
0000000100000000 ,,
0000001100000000 ,,
0000000110000000 ,,
0000000000000000 ,,
0011000000001100 ,,
0000111111110000 ,,
0000001111000000 ,,
0000000000000000 ,,
0000000000000000 ,,
0000000000000000 ,,

create, sadicon
0001100000011000 ,,
0111111001111110 ,,
1000000000000001 ,,
0001100000011000 ,,
0000100000001000 ,,
0000000010000000 ,,
0000000100000000 ,,
0000001100000000 ,,
0000000110000000 ,,
0000000000000000 ,,
0000001111000000 ,,
0000111111110000 ,,
0011000000001100 ,,
0000000000000000 ,,
0000000000000000 ,,
0000000000000000 ,,
decimal

$B000 const, kqstat
$B002 const, kqdata

:, z		0 #, q @, !, ;,
:, cls0		q @, if, z q @, 2 #, +, q !, again, then, ;,
:, cls		$C000 #, q !, cls0 ;,
:, r		q @, @, p @, !,  p @, 80 #, +, p !,  q @, 2 #, +, q !, ;,
:, 16r		r r r r  r r r r  r r r r  r r r r ;,
:, yay		$D334 #, p !, happyicon q !, 16r ;,
:, boo		$D334 #, p !, sadicon q !, 16r ;,
:, wait		kqstat c@, 1 #, and, if, again, then, ;,
:, d		kqdata c!, ;,
:, drain	d d d d d d d d d d d d d d d d d ;,
:, waitkey	drain wait drain ;,
:, happy 	-4 fp+!, cls yay waitkey boo exit. ;,
' happy >body @ is, happyboot
reloc" imgs/prg.happy"

