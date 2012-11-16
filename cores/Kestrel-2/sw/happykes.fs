$3C00 origin

defer, happyboot

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
decimal

:, z		0 #, q @, !, ;,
:, cls0		q @, if, z q @, 2 #, +, q !, again, then, ;,
:, cls		$C000 #, q !, cls0 ;,
:, r		q @, @, p @, !,  p @, 80 #, +, p !,  q @, 2 #, +, q !, ;,
:, 16r		r r r r  r r r r  r r r r  r r r r ;,
:, icon		$D334 #, p !, happyicon q !, 16r ;,
:, deadlock	again, ;,
:, happy 	cls icon deadlock ;,
' happy >body @ is, happyboot

pib $3C00 +  pib  $0400 move
out" happy.bin"

