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
int, max
int, #read
int, p
int, q
char, cmdbyte
char, crcbyte
int, paraml
int, paramh
char, out
char, in
char, _r1
int, _r3h
int, _r3l
int, inw
int, outw
int, t.o.
int, count


$C000 const, BootBuffer

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
:, v2hc?	cardtype @, CARD_V2HC and, ;,

:, clk0		gpop @, $FFF7 #, and, gpop !, ;,
:, mosi0	gpop @, $FFFB #, and, gpop !, ;,
:, cs0		gpop @, $FFFD #, and, gpop !, ;,

:, clk+-	gpop @, 8 #, xor, gpop !, ;,
:, mosi1	mosi0  gpop @, 4 #, xor, gpop !, ;,
:, cs1		cs0 gpop @, 2 xor, gpop !, ;,

:, miso		gpip @, kMISO and, ;,


:, sleep	dct @, -1 #, +, dct !,   dct @, if, again, then, ;,
:, 50ms		1000 #, dct !, sleep ;,
:, 5ms		3 #, dct !, sleep ;,
:, clk		5ms clk+- ;,

:, mosi		if, mosi1 ;, then, mosi0 ;,
:, b		out c@, $80 #, and, mosi clk clk   out c@, out c@, +, out c!, ;,
:, snd		b b b b b b b b ;,
:, sndw		outw 1 #, +, c@, out c!, snd  outw c@, out c!, snd ;,
:, send		cmdbyte c@, out c!, snd paramh @, outw !, sndw paraml @, outw !, sndw crcbyte c@, out c!, snd ;,
:, pad		$FF #, out c!, snd ;,

:, (wait)	max @, if,
		  miso if, clk clk  -1 #, max @, +, max !, again, then,
		  0 #, t.o. !, ;,
		then, 1 #, t.o. !, ;,
:, wait		8192 #, max !, mosi1 (wait) ;,
:, issue	send wait ;,
:, timeout?	t.o. @, ;,
:, -timeout?	timeout? 1 #, xor, ;,

:, idle?	_r1 c@, $01 #, and, ;,
:, -idle?	idle? 1 #, xor, ;,
:, illegal?	_r1 c@, $04 #, and, ;,
:, -illegal?	illegal? 1 #, xor, ;,
:, -ready?	_r1 c@, ;,
:, ccs?		_r3h @, $4000 #, and, ;,

:, b		in c@, in c@, +, in c!,  miso if, in c@, 1 #, xor, in c!, then,  clk clk ;,
:, r1		0 #, in c!,  b b b b b b b b in c@, _r1 c!, ;,
:, rcv		0 #, in c!,  b b b b b b b b ;,
:, rcvw		rcv in c@, inw 1 #, +, c!,  rcv in c@, inw c!, ;,
:, (r3)		rcvw inw @, _r3h !,  rcvw inw @, _r3l !, ;,
:, r3		r1 _r1 c@, $7C #, and, if, ;, then, (r3) ;,
:, r7		r3 ;,
:, bytes	count @, if, rcv in c@, p @, c!,  p @, 1 #, +, p !,  #read @, 1 #, +, #read !,  count @, -1 #, +, count !, again, then, ;,
:, data		512 #, count !, bytes ;,
:, start	rcv in c@, $FF #, xor, if, ;, then, again, ;,
:, 512bytes	start data rcv rcv ;,
:, sector	-ready? if, ;, then,  512bytes ;,

:, param0	0 #, paraml !, 0 #, paramh !, ;,
:, cmd0		cs0 $40 #, cmdbyte c!, param0 $95 #, crcbyte c!, issue -timeout? if, r1 then, cs1 pad ;,
:, cmd1		cs0 $41 #, cmdbyte c!, param0 issue -timeout? if, r1 then, cs1 pad ;,
:, cmd8		cs0 $48 #, cmdbyte c!, param0 $01AA paraml !, issue -timeout? if, r7 then, cs1 pad ;,
:, cmd16	cs0 $50 #, cmdbyte c!, 512 #, paraml !, 0 #, paramh !, issue -timeout? if, r1 then, cs1 pad ;,
:, cmd17	cs0 $51 #, cmdbyte c!, param0 q @, paraml !, issue -timeout? if, r1 sector then, cs1 pad ;,
:, cmd55	cs0 $77 #, cmdbyte c!, param0 issue -timeout? if, r1 then, cs1 pad ;,
:, hcs		v2hc? if, $4000 #, ;, then, 0 #, ;,
:, acmd41	cmd55 cs0 $69 #, cmdbyte c!, hcs paramh !, 0 #, paraml !, issue -timeout? if, r1 then, cs1 pad ;,
:, cmd58	cs0 $7A #, cmdbyte c!, param0 issue -timeout? if, r3 then, cs1 pad ;,

:, 10cyc	clk clk clk clk clk  clk clk clk clk clk ;,
:, 80cyc	10cyc 10cyc 10cyc 10cyc  10cyc 10cyc 10cyc 10cyc ;,
:, stabilize	clk0 mosi1 cs1 80cyc ;,


:, -valid 	1 #, invalid !, ;,

: to. 		timeout? if, -valid $8001 #, invalid !, ;, then, ;
: valid		invalid @, if, ;, then, ;

:, read1k	BootBuffer p !,  0 #, #read !,  0 #, q !, cmd17  sector1 @, q !, cmd17 ;,
:, size		valid  cmd16 to.  -ready? if, -valid $A001 #, invalid !, then, ;,
:, bytes	512 #, sector1 !, ;,
:, sdhc		CARD_HC cardtype !,    1 #, sector1 !, ;,
:, sdsc		CARD_V2 cardtype !,  bytes ;,
:, check	cmd58 to.  -ready? if, -valid $E001 #, invalid !, ;, then,  ccs? if, sdhc ;, then,  sdsc ;,
:, addressing	valid  v1|mmc? if, bytes ;, then, check ;,
:, cmd		cardtype @, CARD_MMC xor, if, acmd41 ;, then, cmd1 ;,
:, poll		cmd to. ;,
:, inca		$C0A0 #, @, 1 #, +, $C0A0 #, !, ;,
:, incb		$C0A2 #, @, 1 #, +, $C0A2 #, !, ;,
:, wait		valid  inca 50ms incb poll
                illegal? if,
		  cardtype @, CARD_V2HC and, if, $98F1 #, invalid !, ;, then,
		  -v1? if, -valid $98A1 #, invalid !, ;, then,
                  v1|mmc? if, CARD_MMC cardtype !, again, then,
		then,
		idle? if, again, then,
		-ready? if, -valid $9801 #, invalid !, then, ;,
:, verify	valid  cmd58 to.  illegal? if, -valid $0C01 #, invalid !, then, ;,
:, kind		illegal? if, CARD_V1MMC ;, then, CARD_V2HC ;,
:, v1v2		valid  cmd8 to. kind cardtype !, ;,
:, controller	cmd0 to.  -idle? if, -valid $FF01 #, invalid !, then, ;,
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

:, start	off cls BootBuffer go, ;,
:, boot...	read1k  present if, #read @, 1024 #, xor, if, $AAAA #, invalid !, bad... then, start then, wait... ;,

:, bad		present if, invalid @, $C000 #, !,  _r1 c@, $C002 #, c!,  _r1 c@, -1 #, xor, $C052 #, c!, again, then, wait... ;,
:, b		off sdx p !, icon bad ;,
' b >body @ is, bad...

:, val		on cls initialize  present if, invalid @, if, $CCCC #, invalid !, bad... then, boot... then, wait... ;,
' val >body @ is, validate...

:, power...	cls  present if, validate... then, wait... ;,
' power... >body @ is, bootstrap

