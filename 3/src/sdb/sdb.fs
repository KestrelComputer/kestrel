WARNINGS OFF

\ This software is used to build SDB ROM images for the e
\ emulator.  It is based on the SDB V1.1 specifications
\ available here: http://www.ohwr.org/projects/sdb/wiki

\ Kestrel-specific settings are based on the specifications
\ available on the Kestrel Github page at:
\ https://github.com/KestrelComputer/kestrel/wiki/SdbRegistry

512 CONSTANT /rom
CREATE rom /rom ALLOT
VARIABLE romp

: 0rom		rom /rom $FF FILL  0 romp ! ;
0rom
: romhere	romp @ ;
: romallot	romp +! ;
: h>r		rom - ;
: r>h		rom + ;
: ALIGN		romp @ OVER 1- + SWAP NEGATE AND romp ! ;
: rc@		r>h C@
: r@		r>h @ ;
: rc!		r>h C! ;
: r!		r>h ! ;

VARIABLE becheck
VARIABLE le	( true if little-endian; false otherwise )
: checkbe	$1122 becheck ! becheck C@ $22 = le ! ;
checkbe

: hswap le @ IF DUP $FF AND 8 LSHIFT SWAP 8 RSHIFT $FF AND OR THEN ;
: wswap le @ IF DUP hswap 16 LSHIFT SWAP 16 RSHIFT hswap OR THEN ;
: dswap le @ IF DUP wswap 32 LSHIFT SWAP 32 RSHIFT wswap OR THEN ;

: safe		romhere /rom U>= ABORT" SDB ROM too small" ;
: (rc,)		safe DUP romhere rc!  1 romallot 8 RSHIFT ;
: (rh,)		(rc,) (rc,) ;
: (rw,)		(rh,) (rh,) ;
: (r,)		(rw,) (rw,) ;
: rc,		(rc,) DROP ;
: rh,		2 ALIGN hswap (rh,) DROP ;
: rw,		4 ALIGN wswap (rw,) DROP ;
: r,		8 ALIGN dswap (r,) DROP ;

: rh!		romhere >R romp ! rh, R> romp ! ;

\ Constructor words covering interconnects and devices.
VARIABLE 'interconnect
: desc0		safe romhere r>h 64 0 FILL romhere 63 + rc! ;
: interconnect( ( bustype - )
  0 desc0
  romhere 'interconnect ! S" SDB-" romhere r>h SWAP MOVE
  4 romallot 0 rh, 1 rc, rc, ;
: device ( class maj min busspec - )
  1 desc0  2>R SWAP rh, rc, 2R> SWAP rc, rw, ;
: range ( first last - )	SWAP r, r, ;
: version ( vendor id vers - )	>R SWAP r, rw, R> rw, ;
: date ( date - )		rw, ;
CREATE namebuf 19 ALLOT
: name ( a u - )
  namebuf 19 32 FILL  0 MAX 19 MIN namebuf SWAP MOVE
  namebuf romhere r>h 19 MOVE 20 romallot ;
: )interconnect ( - )
  romp @ 63 AND ABORT" Alignment error in interconnect"
  romp @ 'interconnect @ - 6 RSHIFT
  'interconnect @ 4 + rh! ;

\ ROM image generator
VARIABLE h
: open		R/W BIN CREATE-FILE THROW h ! ;
: write		rom romhere h @ .S CR WRITE-FILE .S CR ;
: close		h @ CLOSE-FILE THROW ;
: (save)	open write ;
: save		13 PARSE (save) h @ CLOSE-FILE THROW THROW ;
\ : save		13 PARSE ['] (save) CATCH h @ ?DUP IF CLOSE-FILE DROP THEN THROW ;

\ Bus types
0 CONSTANT B_WISHBONE
1 CONSTANT B_SDBFS

\ Bus-specific flags (Wishbone)
$80 CONSTANT WB_LITTLE_ENDIAN
$08 CONSTANT WB_64BIT
$04 CONSTANT WB_32BIT
$02 CONSTANT WB_16BIT
$01 CONSTANT WB_8BIT
