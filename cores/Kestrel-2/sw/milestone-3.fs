0 origin
program progmem.ram00
defer, bootstrap


\ By convention, words with an ellipsis suffix never return.

defer, validate...
defer, bad...


int, invalid
int, #read
int, p
int, q


$B010 const, gpip
  $0001 const, kSDCD

$B012 const, gpop
  $0001 const, kSDLEDOFF
  $FFFE const, kSDLEDON


2 base !
create, sd
0000111111111111 ,,
0001100000000011 ,,
0011001010101011 ,,
0110001010101011 ,,
1100101010101011 ,,
1100100000000011 ,,
1100100000000011 ,,
1100000000000011 ,,
1100000000000011 ,,
1100111111110011 ,,
1101000000001011 ,,
1101000000001011 ,,
1101000000001011 ,,
1101000000001011 ,,
1101000000001011 ,,
1111111111111111 ,,

create, sdx
0000111111111111 ,,
0001100000000011 ,,
0011001010101011 ,,
0110001010101011 ,,
1100101010101011 ,,
1100100000000011 ,,
1100100000000011 ,,
1100000000000011 ,,
1100000000000011 ,,
1100111111110011 ,,
1101011001101011 ,,
1101001111001011 ,,
1101000110001011 ,,
1101001111001011 ,,
1101011001101011 ,,
1111111111111111 ,,

decimal

\ STUBS
:, initialize	1 #, invalid !, ;,
:, read1k	1023 #, #read !, ;,


:, (cls)	q @, if, 0 #, q @, !,  q @, 2 #, +, q !, again, then, ;,
:, cls		$C000 q !, (cls) ;,
:, r		p @, @, q @, !,  p @, 2 #, +, p !,  q @, 80 #, +, q !, ;,
:, 4r		r r r r ;,
:, 16r		4r 4r 4r 4r ;,
:, icon		$D336 #, q !, 16r ;,
:, present	gpip @, kSDCD and, kSDCD xor, ;,
:, on		gpop @, kSDLEDON and, gpop !, ;,
:, off		on gpop @, kSDLEDOFF xor, gpop !, ;,

:, wait		present if, validate... then, again, ;,
:, wait...	off sd p !, icon wait ;,

:, start	off cls 15360 #, go, ;,
:, boot...	read1k  present if, #read @, 1024 #, xor, if, bad... then, start then, wait... ;,

:, bad		present if, again, then, wait... ;,
:, b		off sdx p !, icon bad ;,
' b >body @ is, bad...

:, val		on cls initialize  present if, invalid @, if, bad... then, boot... then, wait... ;,
' val >body @ is, validate...

:, power...	cls  present if, validate... then, wait... ;,
' power... >body @ is, bootstrap

