\ These words provide low-level access to the SDSC card from which STS was
\ booted.

\ Hardware I/O definitions.

$B012 const, gpop
  $0001 const, kLED1
  $0002 const, kCS1
  $0004 const, kMOSI1
  $0008 const, kCLK1
  $FFFE const, kLED0
  $FFFD const, kCS0
  $FFFB const, kMOSI0
  $FFF7 const, kCLK0

$B010 const, gpip
  $0004 const, kMISO

\ Device Driver State

int, devsec
int, devbufptr

int, pause
int, seclen
int, bufptr
char, sndbuf
char, rcvbuf

create, devofs
	0 ,, 0 ,,

\ Hardware accessors of various kinds.

:, (led0)
	gpop @, kLED0 and, ;,

:, (cs0)
	gpop @, kCS0 and, ;,

:, (mosi0)
	gpop @, kMOSI0 and, ;,

:, led0
	(led0) gpop !, ;,

:, led1
	(led0) kLED1 xor, gpop !, ;,

:, cs0
	(cs0) gpop !, ;,

:, cs1
	(cs0) kCS1 xor, gpop !, ;,

:, mosi0
	(mosi0) gpop !, ;,

:, mosi1
	(mosi0) kMOSI1 xor, gpop !, ;,

:, miso
	gpip @, kMISO and, ;,

:, clk
	gpop @, kCLK1 xor, gpop !, ;,

\ SPI protocol.

:, sleep
	pause @, -1 #, +, pause !,  pause @, if, again, then, ;,

:, wait
	3 #, pause !, sleep ;,

:, shift
	wait clk wait clk ;,

:, b
	rcvbuf c@, rcvbuf c@, +, rcvbuf c!,
	miso
	if,	rcvbuf c@, 1 #, xor, rcvbuf c!,
	then,
	sndbuf c@, $80 #, and,
	if,	mosi1
	else,	mosi0
	then,
	shift
	sndbuf c@, sndbuf c@, +, sndbuf c!, ;,

:, i/o
	b b b b  b b b b  mosi1 ;,

\ SDSC cards rely upon a specific protocol.  The following words implement
\ their eponymous protocol phases.

:, gap
	$FF #, sndbuf c!, i/o ;,

:, cmd17
	$51 #, sndbuf c!, i/o		( send command 17: block read )
	devofs 3 #, +, c@, sndbuf c!, i/o
	devofs 2 #, +, c@, sndbuf c!, i/o
	devofs 1 #, +, c@, sndbuf c!, i/o
	devofs         c@, sndbuf c!, i/o
	gap ;,
	
:, wait0
	miso if, shift again, then, ;,

:, r1
	wait0 gap ;,

:, start
	gap rcvbuf c@, $FF #, xor, if, exit, then, again, ;,

:, bytes
	seclen @,
	if,	gap
		rcvbuf c@, bufptr @, c!,
		bufptr @, 1 #, +, bufptr !,
		seclen @, -1 #, +, seclen !,
		again,
	then, ;,

:, data
	start 512 #, seclen !, bytes ;,

:, crc
	gap gap ;,

\ SDSC cards take their seek offsets in byte units, NOT sectors.
\ Therefore, we need to convert a sector number into a byte offset.
\ shift9 soft-shifts the value already in devofs left 9 places,
\ in effect multiplying its value by 512.
\ 
\ Prior to calling shift9, make sure to clear the upper 16 bits of
\ devofs.  Otherwise, you'll get corrupted results.

:, shift
	devofs 2 #, +, @, devofs 2 #, +, @, +,
	devofs @, $8000 #, and, if, 1 #, xor, then,
	devofs 2 #, +, !,

	devofs @, devofs @, +, devofs !, ;,

:, shift3
	shift shift shift ;,

:, shift9
	shift3 shift3 shift3 ;,

\ devget retrieves a single 512-byte sector from the currently inserted SD
\ card.  Presently, devget will block indefinitely until it can successfully
\ retrieve data from the card.  This can only happen if the devget word is
\ called WHILE a card is inserted.  If the card is pulled from the slot,
\ and/or a card inserted before a previous call finishes, the system will
\ deadlock.
\ 
\ The devsec variable must contain the desired sector to read from.
\ The devbufptr variable must point to the start of a sector-sized buffer.
\ After grabbing the sector specified, that buffer will be filled with its
\ contents.
\ 
\ Note that rsn is not changed by this procedure at this time, as no
\ errors are detected.

:, devget
	devsec @, devofs !,  0 #, devofs 2 #, +, !,  shift9
	devbufptr @, bufptr !,
	led1 cs0 cmd17 r1 data crc cs1 gap led0 ;,	

