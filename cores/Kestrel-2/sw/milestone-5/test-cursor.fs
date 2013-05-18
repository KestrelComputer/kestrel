\ Bootstrap entry point.  The DEFER must always be the first thing compiled.
defer, entry-point

\ Character Map Descriptor Accessors
$C000 const, bitplane
   80 const, #ch/row
   25 const, #rows
    8 const, #px/row

\ Dependencies to satisfy cursor.fs
\
\ Cursor position
int, x
int, y

\ FCB fields
int, Left
int, Top
int, Right
int, Bottom

\ Test state
int, ReverseVideos
:, ReverseVideo  ReverseVideos @, 1 #, +, ReverseVideos !, ;,
:, 0st		0 #, ReverseVideos !, ;,


\ Module Under Test
pibptr @
include cursor.fs
pibptr @ swap - . .( bytes in module compiled) cr


\ Unit Testing Support
int, test
int, p
:, incp		p @, 2 #, +, p !, ;,
:, halt		again, ;,
:, testid	test @, $C000 #, !,  test @, -1 #, xor, $C050 #, !, $1111 #, $C0A0 #, !, ;,
:, (cls0)	p @, if, 0 #, p @, !, incp again, then, ;,
:, cls		bitplane p !, (cls0) ;,
:, fail		cls testid halt ;,

:, t		test !, 0st 0cursor ;,

:, tt		hidden? if, invisible? if, exit, then, then, fail ;,
:, tr		hidden? if, fail then,  invisible? if, fail then, ;,
:, th		hidden? if, fail then,  visible? if, fail then, ;,


\ Cursor visibility tests
:, t010		$0010 #, t tt ;,
:, t020		$0020 #, t hide tt ;,
:, t030		$0030 #, t reveal tr ;,
:, t040		$0040 #, t toggle tt ;,

:, t050		$0050 #, t hide hide tt ;,
:, t060		$0060 #, t hide reveal tt ;,
:, t070		$0070 #, t hide toggle tt ;,

:, t080		$0080 #, t reveal hide tt ;,
:, t090		$0090 #, t reveal reveal tr ;,
:, t0A0		$00A0 #, t reveal toggle th ;,

:, t0B0		$00B0 #, t toggle hide tt ;,
:, t0C0		$00C0 #, t toggle reveal tr ;,
:, t0D0		$00D0 #, t toggle toggle tt ;,

:, t0E0		$00E0 #, t reveal reveal hide tt ;,
:, t0F0		$00F0 #, t reveal reveal reveal tr ;,
:, t100		$0100 #, t reveal reveal toggle th ;,

:, t110		$0110 #, t reveal toggle hide tt ;,
:, t120		$0120 #, t reveal toggle reveal th ;,
:, t130		$0130 #, t reveal toggle toggle tr ;,

\ Cursor placement and movement
:, x=0		x @, if, fail then, ;,
:, x=1		x @, 1 #, xor, if, fail then, ;,
:, x=W-1	x @, #ch/row-1 xor, if, fail then, ;,
:, y=0		y @, if, fail then, ;,
:, y=1		y @, 1 #, xor, if, fail then, ;,
:, y=H-1	y @, #rows-1 xor, if, fail then, ;,

:, t200		$0200 #, t getxy x=0 y=0 ;,
:, t210		$0210 #, t mvleft  getxy x=0 y=0 ;,
:, t220		$0220 #, t mvright  getxy x=1 y=0 ;,
:, t230		$0230 #, t mvup  getxy x=0 y=0 ;,
:, t240		$0240 #, t mvdown  getxy x=0 y=1 ;,
:, t250		$0250 #, t return  getxy x=0 y=0 ;,
:, t260		$0260 #, t redge  getxy x=W-1 y=0 ;,
:, t261		$0261 #, t bedge  getxy x=0 y=H-1 ;,

:, t270		$0270 #, t mvleft mvleft  getxy x=0 y=0 ;,
:, t280		$0280 #, t mvleft mvright  getxy x=1 y=0 ;,
:, t290		$0290 #, t mvleft mvup  getxy x=0 y=0 ;,
:, t2A0		$02A0 #, t mvleft mvdown  getxy x=0 y=1 ;,
:, t2B0		$02B0 #, t mvleft return  getxy x=0 y=0 ;,
:, t2C0		$02C0 #, t mvleft redge  getxy x=W-1 y=0 ;,
:, t2C1		$02C1 #, t mvleft bedge  getxy x=0 y=H-1 ;,

:, t2D0		$02D0 #, t mvright mvleft  getxy x=0 y=0 ;,
:, t2E0		$02E0 #, t mvright mvright  getxy x @, 2 #, xor, if, fail then, y=0 ;,
:, t2F0		$02F0 #, t mvright mvup  getxy x=1 y=0 ;,
:, t300		$0300 #, t mvright mvdown  getxy x=1 y=1 ;,
:, t310		$0310 #, t mvright return  getxy x=0 y=0 ;,
:, t320		$0320 #, t mvright redge  getxy x=W-1 y=0 ;,
:, t321		$0321 #, t mvright bedge  getxy x=1 y=H-1 ;,

:, t330		$0330 #, t mvup mvleft  getxy x=0 y=0 ;,
:, t340		$0340 #, t mvup mvright  getxy x=1 y=0 ;,
:, t350		$0350 #, t mvup mvup  getxy x=0 y=0 ;,
:, t360		$0360 #, t mvup mvdown  getxy x=0 y=1 ;,
:, t370		$0370 #, t mvup return  getxy x=0 y=0 ;,
:, t380		$0380 #, t mvup redge  getxy x=W-1 y=0 ;,
:, t381		$0381 #, t mvup bedge  getxy x=0 y=H-1 ;,

:, t390		$0390 #, t mvdown mvleft  getxy x=W-1 y=0 ;,
:, t3A0		$03A0 #, t mvdown mvright  getxy x=1 y=1 ;,
:, t3B0		$03B0 #, t mvdown mvup  getxy x=0 y=0 ;,
:, t3C0		$03C0 #, t mvdown mvdown  getxy x=0 y @, 2 #, xor, if, fail then, ;,
:, t3D0		$03D0 #, t mvdown return  getxy x=0 y=1 ;,
:, t3E0		$03E0 #, t mvdown redge  getxy x=W-1 y=1 ;,
:, t3E1		$03E1 #, t mvdown bedge  getxy x=0 y=H-1 ;,

:, t3F0		$03F0 #, t return mvleft  getxy x=0 y=0 ;,
:, t400		$0400 #, t return mvright  getxy x=1 y=0 ;,
:, t410		$0410 #, t return mvup  getxy x=0 y=0 ;,
:, t420		$0420 #, t return mvdown  getxy x=0 y=1 ;,
:, t430		$0430 #, t return return  getxy x=0 y=0 ;,
:, t440		$0440 #, t return redge  getxy x=W-1 y=0 ;,
:, t450		$0450 #, t return bedge  getxy x=0 y=H-1 ;,

:, t460		$0460 #, t redge mvleft  getxy #ch/row -2 #, +, x @, xor, if, fail then, y=0 ;,
:, t470		$0470 #, t redge mvright  getxy x=0 y=1 ;,
:, t480		$0480 #, t redge mvup  getxy x=W-1 y=0 ;,
:, t490		$0490 #, t redge mvdown  getxy x=W-1 y=1 ;,
:, t4A0		$04A0 #, t redge return  getxy x=0 y=0 ;,
:, t4B0		$04B0 #, t redge redge  getxy x=W-1 y=0 ;,
:, t4C0		$04C0 #, t redge bedge  getxy x=W-1 y=H-1 ;,

:, t4D0		$04D0 #, t bedge mvleft  getxy x=W-1 #rows -2 #, +, y @, xor, if, fail then, ;,
:, t4E0		$04E0 #, t bedge mvright  getxy x=1 y=H-1 ;,
:, t4F0		$04F0 #, t bedge mvup  getxy x=0 #rows -2 #, +, y @, xor, if, fail then, ;,
:, t500		$0500 #, t bedge mvdown  getxy x=0 y=H-1 ;,
:, t510		$0510 #, t bedge return  getxy x=0 y=H-1 ;,
:, t520		$0520 #, t bedge redge  getxy x=W-1 y=H-1 ;,
:, t530		$0530 #, t bedge bedge  getxy x=0 y=H-1 ;,

:, t600		$0600 #, t ReverseVideos @, if, fail then, ;,
:, t610		$0610 #, t reveal ReverseVideos @, 1 #, xor, if, fail then, ;,
:, t620		$0620 #, t reveal mvleft ReverseVideos @, 3 #, xor, if, fail then, ;,

( Should the following functionality actually reside within the tty module instead? )

:, t700		$0700 #, t mvright mvright setbm resetbm  getxy x @, 2 #, xor, if, fail then, ;,
:, t710		$0710 #, t mvright mvright setbm mvdown mvdown resetbm getxy y @, if, fail then, ;,
:, t720		$0720 #, t mvdown setbm bedge redge mvright resetbm getxy y @, if, fail then, ;,

:, all-tests
	     t010 t020 t030 t040 t050 t060 t070 t080 t090 t0A0 t0B0 t0C0 t0D0 t0E0 t0F0
	t100 t110 t120 t130
	
	t200 t210 t220 t230 t240 t250 t260 t270 t280 t290 t2A0 t2B0 t2C0 t2D0 t2E0 t2F0
	t300 t310 t320 t330 t340 t350 t360 t370 t380 t390 t3A0 t3B0 t3C0 t3D0 t3E0 t3F0
	t400 t410 t420 t430 t440 t450 t460 t470 t480 t490 t4A0 t4B0 t4C0 t4D0 t4E0 t4F0
	t500 t510 t520 t530      t261 t2C1 t321 t381 t3E1

	t600 t610 t620

	t700 t710 t720

	0 #, test !, fail ;,

' all-tests >body @ is, entry-point

\ gforth ../asm.fs sd-test-cursor.fs
