0 origin
program progmem.ram00
defer, bootstrap


\ By convention, words with an ellipsis suffix never return.

defer, validate...
defer, bad...


int, invalid
int, cardtype
int, sector1
int, dct
int, #read
int, p
int, q


$0001 const, CARD_MMC
$0002 const, CARD_V1
$0004 const, CARD_V2
$0008 const, CARD_HC

$0003 const, CARD_V1MMC
$000C const, CARD_V2HC
$000D const, -CARD_V1

$B010 const, gpip
  $0001 const, kSDCD
  $0002 const, kSDWP
  $0004 const, kMISO

$B012 const, gpop
  $FFFE const, kSDLEDOFF
  $0001 const, kSDLEDON


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


:, -v1?		cardtype @, -CARD_V1 and, ;,
:, v1|mmc?	cardtype @, CARD_V1MMC and, ;,


\ STUBS
:, read1k	1023 #, #read !, ;,
:, 50ms		;,

:, cmd0		;,
:, cmd1		;,
:, cmd8		;,
:, cmd16	;,
:, acmd41	;,
:, cmd58	;,

:, -idle?	1 #, ;,
:, idle?	-idle? 1 #, xor, ;,
:, illegal?	0 #, ;,
:, -ready?	1 #, ;,
:, timeout?	0 #, ;,
:, ccs?		0 #, ;,

:, miso		gpip @, kMISO and, ;,



:, clk0		gpop @, $FFF7 #, and, gpop !, ;,
:, mosi0	gpop @, $FFFB #, and, gpop !, ;,
:, cs0		gpop @, $FFFD #, and, gpop !, ;,

:, clk+-	gpop @, 8 #, xor, gpop !, ;,
:, mosi1	mosi0  gpop @, 4 #, xor, gpop !, ;,
:, cs1		cs0 gpop @, 2 xor, gpop !, ;,

:, sleep	dct @, -1 #, +, dct !,   dct @, if, again, then, ;,
:, 5ms		100 #, dct !, sleep ;,
:, clk		clk+- 5ms ;,
:, 10cyc	clk clk clk clk clk  clk clk clk clk clk ;,
:, 80cyc	10cyc 10cyc 10cyc 10cyc  10cyc 10cyc 10cyc 10cyc ;,
:, stabilize	clk0 mosi1 cs1 80cyc ;,


:, -valid 	1 #, invalid !, ;,

: to. 		timeout? if, -valid ;, then, ;
: valid		invalid @, if, ;, then, ;

:, size		valid  cmd16 to.  -ready? if, -valid then, ;,
:, bytes	512 #, sector1 !, ;,
:, sdhc		CARD_HC cardtype !,    1 #, sector1 !, ;,
:, sdsc		CARD_V2 cardtype !,  bytes ;,
:, check	cmd58 to.  -ready? if, -valid ;, then,  ccs? if, sdhc ;, then,  sdsc ;,
:, addressing	valid  v1|mmc? if, bytes ;, then, check ;,
:, cmd		cardtype @, CARD_MMC xor, if, acmd41 ;, then, cmd1 ;,
:, poll		cmd to. ;,
:, wait		valid  50ms  poll
                illegal? if,
		  -v1? if, -valid ;, then,
                  v1|mmc? if, CARD_MMC cardtype !, again, then,
		then,
		idle? if, again, then,
		-ready? if, -valid then, ;,
:, verify	valid  cmd58 to.  illegal? if, -valid then, ;,
:, kind		illegal? if, CARD_V1MMC ;, then, CARD_V2HC ;,
:, v1v2		valid  cmd8 to. kind cardtype !, ;,
:, controller	cmd0 to.  -idle? if, -valid then, ;,
:, initialize	0 #, cardtype !,  0 #, invalid !, stabilize
		miso if, controller v1v2 verify wait addressing size ;, then, -valid $FF #, invalid !, ;,

:, (cls)	q @, if, 0 #, q @, !,  q @, 2 #, +, q !, again, then, ;,
:, cls		$C000 q !, (cls) ;,
:, r		p @, @, q @, !,  p @, 2 #, +, p !,  q @, 80 #, +, q !, ;,
:, 4r		r r r r ;,
:, 16r		4r 4r 4r 4r ;,
:, icon		$D336 #, q !, 16r ;,
:, present	gpip @, kSDCD and, kSDCD xor, ;,
:, off		gpop @, kSDLEDOFF and, gpop !, ;,
:, on		off gpop @, kSDLEDON xor, gpop !, ;,

:, wait		present if, validate... then, again, ;,
:, wait...	off sd p !, icon wait ;,

:, start	off cls 15360 #, go, ;,
:, boot...	read1k  present if, #read @, 1024 #, xor, if, bad... then, start then, wait... ;,

:, bad		present if, invalid @, $C000 #, !, again, then, wait... ;,
:, b		off sdx p !, icon bad ;,
' b >body @ is, bad...

:, val		on cls initialize  present if, invalid @, if, bad... then, boot... then, wait... ;,
' val >body @ is, validate...

:, power...	cls  present if, validate... then, wait... ;,
' power... >body @ is, bootstrap

