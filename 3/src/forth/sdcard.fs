\ Block storage driver for Kestrel-3 bit-banged SD card.

$0100000000000000 tconstant gpip
$0100000000000008 tconstant gpop

\ TimeoutError will be thrown if any timing parameter
\ of the SD protocol is violated.  Applications can check
\ for TimeoutError like so:
\ 
\     ... CATCH DUP TimeoutError = IF ( handle timeout ) THEN
t: TimeoutError	$" timeout" ;

\ ProtocolError will be thrown if an unexpected response
\ from the SD card is encountered.
t: ProtocolError $" protocol" ;

t: timeout	TimeoutError THROW ;
t: protocol	ProtocolError THROW ;

\ led1, led0 ( -- ) turns the SD card activity
\ LED on, off, respectively.
t: led1		gpop @ 1 OR gpop ! ;
t: led0		gpop @ 1 BIC gpop ! ;

\ cs1, cs0 ( -- ) negates or asserts the SD card
\ slave select signal, respectively.
t: cs1		gpop @ 2 OR gpop ! ;
t: cs0		gpop @ 2 BIC gpop ! ;

\ sd1 ( -- ) addresses the SD card and turns on the
\ LED at the same time.  sd0 ( -- ) deselects the
\ SD card and turns off the LED.
t: sd1		cs0 led1 ;
t: sd0		cs1 led0 ;

\ mosi1 ( -- ) forces MOSI signal to the SD card
\ high.
t: mosi1	gpop @ 4 OR gpop ! ;

\ mosi! ( b[2] -- ) sets MOSI to the current value
\ of bit 2 of b.  Bit 2 corresponds to the bit
\ position of the MOSI signal on the GPIA output
\ register.
t: mosi!	4 AND gpop @ 4 BIC OR gpop ! ;

\ clk0 ( -- ) forces the SPI clock low.
t: clk0		gpop @ 8 BIC gpop ! ;

\ edge ( -- ) toggles the SPI clock.
t: edge		gpop @ 8 XOR gpop ! ;

\ clocks ( n -- ) sends n clock pulses to the SPI peripheral.
t: clocks	1- FOR edge edge NEXT ;

\ miso ( -- b ) answers the current state of the MISO pin.
\ (0 <= b <= 1)
t: miso		gpip @ 4 AND 2 RSHIFT ;

\ frame ( o i n -- I ) sends n+1 bits of 'o' to the
\ attached peripheral (0 < o < 64).  The bits are sent
\ starting with the most significant bit (bit 63) first.
\ At the same time, input bits are sampled and shifted
\ into the initial input value 'i' from bit 0.  After
\ n+1 bits have been sent, I will contain the received
\ frame acquired during transmission.
t: o		SWAP DUP 61 RSHIFT mosi! 1 LSHIFT SWAP ;
t: i		1 LSHIFT miso OR ;
t: bit		o i edge edge ;
t: frame	FOR bit NEXT NIP ;

\ cmd ( frm -- ) sends a 48-bit frame 'frm' to the
\ attached peripheral.  Note that the frame must appear
\ in bits 63..16, not 47..0 as you might expect.
t: cmd		-1 47 frame DROP ;

\ byte ( o -- b ) sends the byte 'o' out the SPI link.
\ At the same time, it receives a byte 'b'.
t: byte		56 LSHIFT -1 7 frame ;

\ gap ( -- ) clocks eight bits, ignoring anything it
\ receives back.
t: gap		-1 byte DROP ;

\ frend ( -- ) ends an SPI frame in progress.  It 
\ negates the slave-select signal, then clocks an extra
\ byte for the benefit of SD card devices.
t: frend	sd0 gap ;

\ r1 ( -- b ) waits for an R1 response to arrive.
\ If no R1 response arrives in a reasonable period of
\ time, it throws a TimeoutError exception.
\ 
\ Note that the SD slave select must be asserted.
t: r1		-1 BEGIN byte DUP -1 XOR UNTIL $FF AND ;

\ initv1 ( -- ) waits for the SD card to report that
\ it has completed its initialization.  Then, it confirms
\ that the card is a SD Version 1.0 card.
t: initv1
  BEGIN
    sd1 $3700000000000000 cmd r1
    $FE AND IF frend protocol THEN
    $4100000000000000 cmd r1
    frend ?DUP $00 = IF EXIT THEN
    $FE AND IF protocol THEN
  AGAIN ;

\ native ( -- ) puts SD card into SD-native mode.
t: native	clk0 mosi1 sd0 80 clocks
		miso 0 = IF timeout THEN ;

\ reset ( -- )	puts SD card into SPI mode and confirms the SD
\ card is in idle state.
t: reset	sd1 $4000000000950000 cmd r1 frend
		$01 XOR IF timeout THEN ;

\ size ( -- ) configures the SD card for 512-byte sectors.
t: size		sd1 $5000000200000000 cmd r1 frend
		IF protocol THEN ;

\ MOUNT ( -- erc ) initializes the SD card presently in the
\ socket.  If no card exists, a TimeoutError will be returned.
\ Otherwise, 0 is returned.
t: mount	native reset initv1 size ;
t: MOUNT	doLIT mount CATCH frend ;

\ GET ( buf n -- erc ) retrieves a sector 'n' into a 512-byte
\ buffer 'buf'.
t: read		33 LSHIFT $5100000000000000 OR cmd r1
		IF DROP protocol THEN ;
t: token	r1 $FE XOR IF DROP protocol THEN ;
t: sector	511 FOR -1 byte OVER C! 1+ NEXT DROP ;
t: data		token sector gap gap ;
t: get		sd1 read data ;
t: GET		doLIT get CATCH frend ;

\ GETS ( buf n m -- erc ) retrieves 'm' adjacent sectors,
\ starting at sector 'n', each 512 bytes in size.  You are
\ responsible for having enough memory at 'buf' to contain all
\ the sectors.
t: gets		1- FOR 2DUP GET THROW 1+ SWAP 512 + SWAP NEXT
		2DROP ;
t: GETS		doLIT gets CATCH ;

\ PUT ( buf n -- erc ) writes a sector 'n' from a 512-byte
\ buffer 'buf'.
t: write	33 LSHIFT $5800000000000000 OR cmd r1
		IF DROP protocol THEN ;
t: token	$FE byte -1 XOR IF DROP protocol THEN ;
t: sector	511 FOR DUP C@ byte -1 XOR IF DROP protocol THEN
		1+ NEXT DROP ;
t: busy		BEGIN miso 1 XOR WHILE edge edge REPEAT ;
t: dr		r1 $1F AND 5 XOR IF protocol THEN busy ;
t: data		token sector dr gap gap ;
t: put		sd1 write data ;
t: PUT		doLIT put CATCH ;

\ PUTS ( buf n m -- erc ) writes 'm' adjacent sectors,
\ starting at sector 'n', each 512 bytes in size.  You are
\ responsible for using large enough buffers to contain all
\ the sectors.
t: puts		1- FOR 2DUP PUT THROW 1+ SWAP 512 + SWAP NEXT
		2DROP ;
t: PUTS		doLIT puts CATCH ;

