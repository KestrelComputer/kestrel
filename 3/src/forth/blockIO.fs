\ int, invalid
\ int, cardtype
\ int, sector1
\ int, dct
\ int, toctr
\ int, #read
\ int, p
\ int, q
\ char, cmdbyte
\ char, crcbyte
\ int, paraml
\ int, paramh
\ char, out
\ char, in
\ char, _r1
\ int, _r3h
\ int, _r3l
\ int, inw
\ int, outw
\ int, t.o.
\ int, count
\ 
\ 
\ $3C00 const, BootBuffer
\ 
\ $0001 const, CARD_MMC
\ $0002 const, CARD_V1
\ $0004 const, CARD_V2
\ $0008 const, CARD_HC
\ 
\ $0003 const, CARD_V1MMC
\ $000C const, CARD_V2HC
\ $000D const, -CARD_V1
\ 
\   $0001 const, kSDCD
\   $0002 const, kSDWP
\   $0004 const, kMISO
\ 
\   $FFFE const, kSDLEDOFF
\   $0001 const, kSDLEDON
\ 
\ :, -v1?		cardtype @, -CARD_V1 and, ;,
\ :, v1|mmc?	cardtype @, CARD_V1MMC and, ;,
\ :, v2hc?	cardtype @, CARD_V2HC and, ;,
\ 
\ :, clk0		gpop @, $FFF7 #, and, gpop !, ;,
\ :, mosi0	gpop @, $FFFB #, and, gpop !, ;,
\ :, cs0		gpop @, $FFFD #, and, gpop !, ;,
\ 
\ :, clk+-	gpop @, 8 #, xor, gpop !, ;,
\ :, mosi1	mosi0  gpop @, 4 #, xor, gpop !, ;,
\ :, cs1		cs0 gpop @, 2 #, xor, gpop !, ;,
\ 
\ :, miso		gpip @, kMISO and, ;,
\ 
\ 
\ :, sleep	dct @, -1 #, +, dct !,   dct @, if, again, then, ;,
\ :, 50ms		1000 #, dct !, sleep ;,
\ :, 5ms		3 #, dct !, sleep ;,
\ :, clk		5ms clk+- ;,
\ 
\ :, mosi		if, mosi1 ;, then, mosi0 ;,
\ :, b		out c@, $80 #, and, mosi  clk clk  out c@, out c@, +, out c!, ;,
\ :, snd		b b b b b b b b ;,
\ :, sndw		outw 1 #, +, c@, out c!, snd  outw c@, out c!, snd ;,
\ :, send		cmdbyte c@, out c!, snd paramh @, outw !, sndw paraml @, outw !, sndw crcbyte c@, out c!, snd ;,
\ :, gap		$FF #, out c!, snd ;,
\ 
\ :, (wait)	toctr @, if,
\ 		  miso if, clk clk  -1 #, toctr @, +, toctr !, again, then,
\ 		  0 #, t.o. !, ;,
\ 		then, 1 #, t.o. !, ;,
\ :, wait		0 #, t.o. !,  8192 #, toctr !, mosi1 (wait) ;,
\ :, issue	send wait ;,
\ :, timeout?	t.o. @, ;,
\ :, -timeout?	timeout? 1 #, xor, ;,
\ 
\ :, idle?	_r1 c@, $01 #, and, ;,
\ :, -idle?	idle? 1 #, xor, ;,
\ :, illegal?	_r1 c@, $04 #, and, ;,
\ :, -illegal?	illegal? 1 #, xor, ;,
\ :, -ready?	_r1 c@, ;,
\ :, ccs?		_r3h @, $4000 #, and, ;,
\ 
\ :, b		in c@, in c@, +, in c!,  miso if, in c@, 1 #, xor, in c!, then,  clk clk ;,
\ :, rcv		0 #, in c!,  b b b b b b b b ;,
\ :, r1		rcv in c@, _r1 c!, ;,
\ :, rcvw		rcv in c@, inw 1 #, +, c!,  rcv in c@, inw c!, ;,
\ :, (r3)		rcvw inw @, _r3h !,  rcvw inw @, _r3l !, ;,
\ :, r3		r1 _r1 c@, $7C #, and, if, ;, then, (r3) ;,
\ :, r7		r3 ;,
\ :, bytes	count @, if, rcv in c@, p @, c!,  p @, 1 #, +, p !,  #read @, 1 #, +, #read !,  count @, -1 #, +, count !, again, then, ;,
\ :, data		512 #, count !, bytes ;,
\ :, start	rcv in c@, $FF #, xor, if, ;, then, again, ;,
\ :, 512bytes	start data rcv rcv ;,
\ :, sector	-ready? if, ;, then,  512bytes ;,
\ 
\ :, param0	0 #, paraml !, 0 #, paramh !, ;,
\ :, cmd0		cs0 $40 #, cmdbyte c!, param0 $95 #, crcbyte c!, issue -timeout? if, r1 then, cs1 gap ;,
\ :, cmd1		cs0 $41 #, cmdbyte c!, param0 issue -timeout? if, r1 then, cs1 gap ;,
\ :, cmd8		cs0 $48 #, cmdbyte c!, param0 $01AA paraml !, $87 #, crcbyte c!, issue -timeout? if, r7 then, cs1 gap ;,
\ :, cmd16	cs0 $50 #, cmdbyte c!, 512 #, paraml !, 0 #, paramh !, issue -timeout? if, r1 then, cs1 gap ;,
\ :, cmd17	cs0 $51 #, cmdbyte c!, param0 q @, paraml !, issue -timeout? if, r1 sector then, cs1 gap ;,
\ :, cmd55	cs0 $77 #, cmdbyte c!, param0 issue -timeout? if, r1 then, cs1 gap ;,
\ :, hcs		v2hc? if, $4000 #, ;, then, 0 #, ;,
\ :, acmd41	cmd55 cs0 $69 #, cmdbyte c!, hcs paramh !, 0 #, paraml !, issue -timeout? if, r1 then, cs1 gap ;,
\ :, cmd58	cs0 $7A #, cmdbyte c!, param0 issue -timeout? if, r3 then, cs1 gap ;,
\ 
\ :, 80cyc	gap gap gap gap gap  gap gap gap gap gap ;,
\ :, stabilize	clk0 mosi1 cs1 80cyc ;,
\ 
\ 
\ :, -valid 	1 #, invalid !, ;,
\ 
\ : to. 		timeout? if, -valid ;, then, ;
\ : valid		invalid @, if, ;, then, ;
\ 
\ :, read1k	BootBuffer p !,  0 #, #read !,  0 #, q !, cmd17  sector1 @, q !, cmd17 ;,
\ :, size		valid  cmd16 to.  -ready? if, -valid then, ;,
\ :, bytes	512 #, sector1 !, ;,
\ :, sdhc		CARD_HC cardtype !,    1 #, sector1 !, ;,
\ :, sdsc		CARD_V2 cardtype !,  bytes ;,
\ :, check	cmd58 to.  -ready? if, -valid ;, then,  ccs? if, sdhc ;, then,  sdsc ;,
\ :, addressing	valid  v1|mmc? if, bytes ;, then, check ;,
\ :, cmd		cardtype @, CARD_MMC xor, if, acmd41 ;, then, cmd1 ;,
\ :, poll		cmd to. ;,
\ :, wait		valid  50ms poll
\                 illegal? if,
\ 		  -v1? if, -valid ;, then,
\                   v1|mmc? if, CARD_MMC cardtype !, again, then,
\ 		then,
\ 		idle? if, again, then,
\ 		-ready? if, -valid then, ;,
\ :, verify	valid  cmd58 to.  illegal? if, -valid then, ;,
\ :, kind		illegal? if, CARD_V1MMC ;, then, CARD_V2HC ;,
\ :, v1v2		valid  cmd8 to. kind cardtype !, ;,
\ :, controller	cmd0 to. -idle? if, -valid then, ;,
\ 

\ Block storage driver for Kestrel-3 bit-banged SD card.

$0100000000000000 tconstant gpip
$0100000000000008 tconstant gpop

t: TimeoutError	$" timeout" ;
t: ProtocolError $" protocol" ;

t: timeout	TimeoutError THROW ;
t: protocol	ProtocolError THROW ;

\ MOUNT ( -- erc ) initializes the SD card presently in the
\ socket.  If no card exists, a TimeoutError will be returned.
\ Otherwise, 0 is returned.

t: led1		gpop @ 1 OR gpop ! ;
t: led0		gpop @ 1 BIC gpop ! ;
t: cs1		gpop @ 2 OR gpop ! ;
t: cs0		gpop @ 2 BIC gpop ! ;
t: mosi1	gpop @ 4 OR gpop ! ;
t: mosi!	4 AND gpop @ 4 BIC OR gpop ! ;
t: clk0		gpop @ 8 BIC gpop ! ;
t: edge		gpop @ 8 XOR gpop ! ;
t: clocks	1- FOR edge edge NEXT ;

t: miso		gpip @ 4 AND 2 RSHIFT ;

t: o		SWAP DUP 61 RSHIFT mosi! 1 LSHIFT SWAP ;
t: i		1 LSHIFT miso OR ;
t: bit		o i edge edge ;
t: frame	FOR bit NEXT NIP ;
t: cmd		-1 47 frame DROP ;
t: byte		56 LSHIFT -1 7 frame ;
t: gap		-1 byte DROP ;
t: frend	cs1 gap ;
t: r1		-1 BEGIN byte DUP -1 XOR UNTIL $FF AND ;

t: initv1
  BEGIN
    cs0 $3700000000000000 cmd r1
    $FE AND IF frend protocol THEN
    $4100000000000000 cmd r1
    frend ?DUP $00 = IF EXIT THEN
    $FE AND IF protocol THEN
  AGAIN ;

t: native	clk0 mosi1 cs1 80 clocks
		miso 0 = IF timeout THEN ;
t: reset	cs0 $4000000000950000 cmd r1 frend
		$01 XOR IF timeout THEN ;
t: size		cs0 $5000000200000000 cmd r1 frend
		IF protocol THEN ;
t: mount	native reset initv1 size ;
t: MOUNT	led1 doLIT mount CATCH led0 ;

\ 		controller v1v2 verify wait addressing size ;, then, -valid ;,
