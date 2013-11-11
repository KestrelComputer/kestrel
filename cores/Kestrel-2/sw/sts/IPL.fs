$3C00 origin
defer, bootstrap

int, loadptr
int, loadorg
int, loadcnt
int, pause
int, seclen
char, i
char, o

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

:, sleep	pause @, -1 #, +, pause !,  pause @, if, again, then, ;,
:, wait		3 #, pause !, sleep ;,
:, clk		gpop @, kCLK1 xor, gpop !, ;,
:, shift	wait clk wait clk ;,
:, (mosi0)	gpop @, kMOSI0 and, ;,
:, mosi0	(mosi0) gpop !, ;,
:, mosi1	(mosi0) kMOSI1 xor, gpop !, ;,
:, mosi		if, mosi1 ;, then, mosi0 ;,
:, b		o c@, $80 #, and, mosi shift  o c@, o c@, +, o c!, ;,
:, snd		b b b b b b b b mosi1 ;,
:, gap		$FF #, o c!, snd ;,
:, cmd17	$51 #, o c!, snd  0 #, o c!, snd snd  loadorg 1 #, +, c@, o c!, snd  loadorg c@, o c!, snd gap ;,
:, (cs0)	gpop @, kCS0 and, ;,
:, cs0		(cs0) gpop !, ;,
:, cs1		(cs0) kCS1 xor, gpop !, ;,
:, miso		gpip @, kMISO and, ;,
:, wait0	miso if, shift again, then, ;,
:, b		i c@, i c@, +, i c!, miso if, i c@, 1 #, +, i c!, then, shift ;,
:, rcv		b b b b b b b b i c@, ;,
:, r1		wait0 rcv ;,
:, bytes	seclen @, if, rcv loadptr @, c!,  loadptr @, 1 #, +, loadptr !,  seclen @, -1 #, +, seclen !, again, then, ;,
:, start	rcv $FF #, xor, if, !, ;, then, again, ;,
:, data		start 512 #, seclen !, bytes  loadorg @, 512 #, +, loadorg !, ;,
:, crc		rcv rcv ;,
:, (led0)	gpop @, kLED0 and, ;,
:, led0		(led0) gpop !, ;,
:, led1		(led0) kLED1 xor, gpop !, ;,
:, sector	led1 cs0 cmd17 r1 data crc cs1 gap led0 ;,
:, load		loadcnt @, if, sector  loadcnt @, -1 #, +, loadcnt !, again, then, ;,
:, go		$0400 #, go, ;,
:, cold		$0400 #, loadptr !,  $0400 #, loadorg !,  24 #, loadcnt !, load go ;,
' cold >body @ is, bootstrap
pib $3C00 + pib 1024 move
1024 pibptr !

out" sys/$IPL"
bye
