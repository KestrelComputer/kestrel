defer, m2start

include INC.STS.SYS.fs

$B000 const, kqstat
$B002 const, kqdata

$69 const, kcEnd
$6C const, kcHome
$7A const, kcPgDn
$7D const, kcPgUp
$15 const, kcQuit

$00 const, kNOP
$01 const, kEND
$10 const, kTEXT
$11 const, kDWTEXT
$20 const, kHLINE
$21 const, kNELINE
$22 const, kSELINE
$30 const, kBOX
$31 const, kFBOX
$40 const, kVLINE

create, font
: m,	dup 8 rshift c,, c,, ;
hex
00f0 m, 0f00 m, 000f m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0018 m, 666c m, 1870 m, 3818 m, 0c30 m, 0000 m, 0000 m, 0000 m, 
1808 m, 3c3c m, 0c7e m, 1c7e m, 3c3c m, 0000 m, 0400 m, 203c m, 
3c10 m, 7c1e m, 787e m, 7e3c m, 663c m, 0666 m, 6042 m, 663c m, 
7c3c m, 7c3c m, 7e66 m, c666 m, 6666 m, 7e3c m, 003c m, 1800 m, 
3000 m, 6000 m, 0600 m, 1c00 m, 6000 m, 0060 m, 1800 m, 0000 m, 
0000 m, 0000 m, 0800 m, 0000 m, 0000 m, 000c m, 1830 m, 36aa m, 
8040 m, 2010 m, 0804 m, 0201 m, ff00 m, 0000 m, 0000 m, 0000 m, 
ffff m, ffc0 m, e0f0 m, 8001 m, 8001 m, ffff m, 0004 m, 0020 m, 
0010 m, 1018 m, 0044 m, 1038 m, 2838 m, 3800 m, 0000 m, 387c m, 
1010 m, 3838 m, 0800 m, 7c00 m, 0010 m, 3800 m, 3030 m, c010 m, 
2008 m, 1034 m, 2810 m, 2e38 m, 2008 m, 1028 m, 2008 m, 1028 m, 
7034 m, 2008 m, 1034 m, 2800 m, 3c20 m, 0810 m, 2808 m, 2030 m, 
1008 m, 1034 m, 2810 m, 0000 m, 2008 m, 1028 m, 2008 m, 1028 m, 
4834 m, 2008 m, 1034 m, 2800 m, 0220 m, 0810 m, 2808 m, 4028 m, 
00f0 m, 0f00 m, 000f m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0018 m, 666c m, 3e54 m, 6c18 m, 1818 m, 2418 m, 0000 m, 0006 m, 
2418 m, 6666 m, 1c40 m, 3006 m, 6666 m, 1818 m, 0c00 m, 3066 m, 
6638 m, 6630 m, 6c60 m, 6060 m, 6618 m, 066c m, 6066 m, 7666 m, 
6666 m, 6666 m, 1866 m, c666 m, 6666 m, 0630 m, 600c m, 1800 m, 
1800 m, 6000 m, 0600 m, 3000 m, 6018 m, 1860 m, 1800 m, 0000 m, 
0000 m, 0000 m, 1800 m, 0000 m, 0000 m, 0018 m, 1818 m, 6c55 m, 
8040 m, 2010 m, 0804 m, 0201 m, 00ff m, 0000 m, 0000 m, 0000 m, 
ffff m, ffc0 m, e0f0 m, 4002 m, c003 m, 7ffe m, 0004 m, 0020 m, 
0000 m, 3820 m, 4444 m, 1040 m, 0054 m, 1c14 m, 0000 m, 7400 m, 
2810 m, 0404 m, 1000 m, f400 m, 0030 m, 4450 m, 1010 m, 2000 m, 
1010 m, 2858 m, 0028 m, 5844 m, 1010 m, 2800 m, 1010 m, 2800 m, 
4858 m, 1010 m, 2858 m, 0044 m, 4c10 m, 1028 m, 0010 m, 2048 m, 
0810 m, 2858 m, 0028 m, 0000 m, 1010 m, 2800 m, 1010 m, 2800 m, 
3058 m, 1010 m, 2858 m, 0010 m, 3c10 m, 1028 m, 0010 m, 4000 m, 
00f0 m, 0f00 m, 000f m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0018 m, 24fe m, 5868 m, 6818 m, 300c m, 1818 m, 0000 m, 000c m, 
6638 m, 0606 m, 3c7c m, 600c m, 6666 m, 1818 m, 187e m, 1806 m, 
6e38 m, 6660 m, 6660 m, 6060 m, 6618 m, 0678 m, 607e m, 7666 m, 
6666 m, 6660 m, 1866 m, 6c66 m, 3c3c m, 0c30 m, 300c m, 3c00 m, 
0c3c m, 7c3e m, 3e3c m, 303e m, 7c00 m, 0066 m, 18fc m, 5c3c m, 
7c3e m, 5e3e m, 3c66 m, 66c6 m, 6666 m, 7e18 m, 1818 m, 00aa m, 
8040 m, 2010 m, 0804 m, 0201 m, 0000 m, ff00 m, 0000 m, 0000 m, 
00ff m, ffc0 m, e0f0 m, 2004 m, e007 m, 3ffc m, e004 m, 0720 m, 
0010 m, 5420 m, 3828 m, 1038 m, 006c m, 6428 m, 7c00 m, 6c00 m, 
107c m, 181c m, 0044 m, f400 m, 0010 m, 4428 m, 1010 m, c410 m, 
0000 m, 0000 m, 0010 m, 5840 m, 7c7c m, 7c7c m, 3838 m, 3838 m, 
4444 m, 3838 m, 3838 m, 3828 m, 5400 m, 0000 m, 0044 m, 3850 m, 
3838 m, 3838 m, 3810 m, 6c38 m, 3838 m, 3838 m, 0000 m, 0000 m, 
0858 m, 3838 m, 3838 m, 3800 m, 4c44 m, 4400 m, 4444 m, 5844 m, 
00f0 m, 0f00 m, 000f m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0018 m, 006c m, 3c10 m, 3200 m, 300c m, 7e7e m, 007e m, 0018 m, 
6618 m, 0c1c m, 6c06 m, 7c0c m, 3c3e m, 0000 m, 3000 m, 0c0c m, 
6a6c m, 7c60 m, 6678 m, 786e m, 7e18 m, 0670 m, 607e m, 7e66 m, 
7c66 m, 7c3c m, 1866 m, 6c7e m, 183c m, 1830 m, 180c m, 3c00 m, 
0006 m, 6660 m, 6666 m, 7c66 m, 6638 m, 186c m, 18d6 m, 6666 m, 
6666 m, 6060 m, 1866 m, 66c6 m, 3c66 m, 0c60 m, 1806 m, 0055 m, 
8040 m, 2010 m, 0804 m, 0201 m, 0000 m, 00ff m, 0000 m, 0000 m, 
0000 m, ffc0 m, e0f0 m, 1008 m, f00f m, 1ff8 m, 1808 m, 1810 m, 
0010 m, 5070 m, 287c m, 0044 m, 0064 m, 3c50 m, 0438 m, 7400 m, 
0010 m, 2004 m, 0044 m, 7410 m, 0010 m, 3814 m, 7c7c m, 2820 m, 
1010 m, 1010 m, 1010 m, 8c40 m, 4040 m, 4040 m, 1010 m, 1010 m, 
e464 m, 4444 m, 4444 m, 4410 m, 5444 m, 4444 m, 4428 m, 2478 m, 
0404 m, 0404 m, 0438 m, 1244 m, 4444 m, 4444 m, 3030 m, 3030 m, 
3864 m, 4444 m, 4444 m, 447c m, 5444 m, 4444 m, 4444 m, 6444 m, 
0000 m, 00f0 m, 0ff0 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0018 m, 00fe m, 1a2c m, 6c00 m, 300c m, 1818 m, 1000 m, 0030 m, 
6618 m, 3006 m, 7e06 m, 6618 m, 6606 m, 0018 m, 187e m, 1818 m, 
667c m, 6660 m, 6660 m, 6066 m, 6618 m, 6678 m, 6066 m, 6e66 m, 
6066 m, 7806 m, 1866 m, 387e m, 3c18 m, 3030 m, 0c0c m, 6600 m, 
003e m, 6660 m, 667e m, 3066 m, 6618 m, 1878 m, 18d6 m, 6666 m, 
6666 m, 603c m, 1866 m, 3cd6 m, 1866 m, 1818 m, 1818 m, 00aa m, 
8040 m, 2010 m, 0804 m, 0201 m, 0000 m, 0000 m, ff00 m, 0000 m, 
0000 m, 00c0 m, e0f0 m, 0810 m, f81f m, 0ff0 m, 0818 m, 1018 m, 
0010 m, 5420 m, 3810 m, 1038 m, 006c m, 7c28 m, 0000 m, 6c00 m, 
0010 m, 3c38 m, 0044 m, 1400 m, 0010 m, 0028 m, 0830 m, d440 m, 
2828 m, 2828 m, 2828 m, f840 m, 7070 m, 6070 m, 1010 m, 1010 m, 
4454 m, 4444 m, 4444 m, 4428 m, 5444 m, 4444 m, 4410 m, 3844 m, 
3c3c m, 3c3c m, 3c1c m, 7e40 m, 7c7c m, 7c7c m, 1010 m, 1010 m, 
4444 m, 4444 m, 4444 m, 4400 m, 6444 m, 4444 m, 4444 m, 6444 m, 
0000 m, 00f0 m, 0ff0 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 006c m, 7c54 m, 6c00 m, 1818 m, 2418 m, 1800 m, 1860 m, 
2418 m, 6066 m, 0c66 m, 6618 m, 660c m, 1818 m, 0c00 m, 3000 m, 
60c6 m, 6630 m, 6c60 m, 6066 m, 6618 m, 666c m, 6066 m, 6e66 m, 
606e m, 6c66 m, 1866 m, 3866 m, 6618 m, 6030 m, 060c m, 0000 m, 
0066 m, 6660 m, 6660 m, 303e m, 6618 m, 186c m, 18c6 m, 6666 m, 
7c3e m, 6006 m, 1866 m, 3cd6 m, 3c3e m, 3018 m, 1818 m, 0055 m, 
8040 m, 2010 m, 0804 m, 0201 m, 0000 m, 0000 m, 00ff m, 0000 m, 
0000 m, 00c0 m, e0f0 m, 0420 m, fc3f m, 07e0 m, 04e0 m, 2007 m, 
0010 m, 3820 m, 447c m, 1004 m, 0054 m, 0014 m, 0000 m, 6c00 m, 
0000 m, 0000 m, 0064 m, 1400 m, 0000 m, 7c50 m, 2808 m, 2c44 m, 
4444 m, 4444 m, 4444 m, 8844 m, 4040 m, 4040 m, 1010 m, 1010 m, 
484c m, 4444 m, 4444 m, 4444 m, 6444 m, 4444 m, 4410 m, 2064 m, 
4444 m, 4444 m, 4464 m, 9044 m, 4040 m, 4040 m, 1010 m, 1010 m, 
4444 m, 4444 m, 4444 m, 4410 m, 7844 m, 4444 m, 443c m, 583c m, 
0000 m, 00f0 m, 0ff0 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0018 m, 006c m, 181c m, 3a00 m, 0c30 m, 0000 m, 1000 m, 1800 m, 
183c m, 7e3c m, 0c3c m, 3c18 m, 3c38 m, 1810 m, 0400 m, 2018 m, 
3cc6 m, 7c1e m, 787e m, 603c m, 663c m, 3c66 m, 7e66 m, 663c m, 
603c m, 663c m, 183c m, 1042 m, 6618 m, 7e3c m, 003c m, 007e m, 
003a m, 7c3e m, 3e3c m, 3006 m, 663c m, 1866 m, 0cc6 m, 663c m, 
6006 m, 607c m, 0c3a m, 187c m, 6606 m, 7e0c m, 1830 m, 00aa m, 
8040 m, 2010 m, 0804 m, 0201 m, 0000 m, 0000 m, 0000 m, ff00 m, 
0000 m, 00c0 m, e0f0 m, 0240 m, fe7f m, 03c0 m, 0400 m, 2000 m, 
0010 m, 105c m, 0010 m, 1038 m, 0038 m, 0000 m, 0000 m, 3800 m, 
007c m, 0000 m, 005c m, 1400 m, 0800 m, 0000 m, 3810 m, 5c38 m, 
7c7c m, 7c7c m, 7c7c m, 8e38 m, 7c7c m, 7c7c m, 3838 m, 3838 m, 
7044 m, 3838 m, 3838 m, 3800 m, 7838 m, 3838 m, 3810 m, 2058 m, 
3c3c m, 3c3c m, 3c3c m, 6e38 m, 3838 m, 3838 m, 3838 m, 3838 m, 
3844 m, 3838 m, 3838 m, 3800 m, 8038 m, 3838 m, 3804 m, 4004 m, 
0000 m, 00f0 m, 0ff0 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 2000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0020 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0006 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 003c m, 0000 m, 7000 m, 0000 m, 0000 m, 
6006 m, 0000 m, 0000 m, 0000 m, 003c m, 0000 m, 0000 m, 0055 m, 
8040 m, 2010 m, 0804 m, 0201 m, 0000 m, 0000 m, 0000 m, 00ff m, 
0000 m, 00c0 m, e0f0 m, 0180 m, ffff m, 0180 m, 0400 m, 2000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0040 m, 0000 m, 1000 m, 0000 m, 0838 m, 0400 m, 
4444 m, 4444 m, 4444 m, 0060 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0080 m, 
0000 m, 0000 m, 0000 m, 0060 m, 0000 m, 0000 m, 0000 m, 0000 m, 
0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0000 m, 0038 m, 4038 m, 
decimal

create, 880*tab
0 ,,		880 ,,		1760 ,,		2640 ,,
3520 ,,		4400 ,,		5280 ,,		6160 ,,
7040 ,,		7920 ,,		8800 ,,		9680 ,,
10560 ,,	11440 ,,	12320 ,,	13200 ,,
14080 ,,	14960 ,,

int, nslides
int, cslide
int, k
int, ip
int, left
int, top
int, charp
int, length
int, p
int, q
int, chr
int, hdeck

create, buf	1024 allot,

create, slidedeck-name
	C", SYS:m2.slides"

create, errmsg
	C", Cannot open SYS:m2.slides"

create, nordmsg
	C", Cannot read from SYS:m2.slides"

create, noskmsg
	C", Cannot seek inside of SYS:m2.slides"


:, dwtext	;,		\ Draw 40-column text (stub!)

:, z		0 #, p @, !,  p @, 2 #, +, p !, ;,
:, clr		p @, if, z again, then, ;,
:, 880top	top @, top @, +, 880*tab +, @, ;,
:, p0		880top left @, 1 #, xor, +, $C000 #, +, p !, ;,
:, q0		chr c@, font +, q !, ;,
:, r		q @, c@, p @, c!,  q @, 256 #, +, q !,  p @, 80 #, +, p !, ;,
:, plot		p0 charp @, c@, chr !, q0 r r r r r r r r ;,
:, tx		plot  charp @, 1 #, +, charp !,  left @, 1 #, +, left !,  ;,
:, txt		length @, if, tx length @, -1 #, +, length !, ;, then, 80 #, left !, ;,

:, cls 		$C000 #, p !, clr ;,
:, text		left @, -80 #, +, $8000 #, and, if, txt again, then, ;,



:, readat	2 +fp!,
		hdeck @, 1 +fp!,
		0 #, 3 +fp!,
		seekblk
		4 +fp@,
		if,	cls  0 #, left !,  0 #, top !,
			noskmsg c@, length !, noskmsg 1 #, +, charp !, text
			4 +fp@, $C200 #, !,  4 +fp@, -1 #, xor, $C250 #, !,  $5555 #, $C2A0 #, !,
			exit.
		then,
		hdeck @, 1 +fp!,
		buf 2 +fp!,
		1024 #, 3 +fp!,
		read
		5 +fp@,
		if,	cls  0 #, left !,  0 #, top !,
			nordmsg c@, length !, nordmsg 1 #, +, charp !, text
			5 +fp@, $C200 #, !,  5 +fp@, -1 #, xor, $C250 #, !,  $5555 #, $C2A0 #, !,
			exit.
		then,
		;,

:, count	0 #, readat  buf @, nslides !, ;,
:, start	0 #, readat
		cslide @, cslide @, +, buf +, 2 #, +, @, readat
		buf ip !, ;,



:, inc		ip @, +, ip !, ;,
:, 2inc		2 #, inc ;,
:, 6inc		6 #, inc ;,
:, len8		ip @, 3 #, +, c@, ;,
:, vinc		len8 ip @, 4 #, +, +, ip !, ;,
:, opc		ip @, c@, ;,
:, y8		ip @, 1 #, +, c@, ;,
:, x8		ip @, 2 #, +, c@, ;,
:, left16	ip @, 2 #, +, @, ;,
:, right16	ip @, 4 #, +, @, ;,
:, top8		y8 ;,
:, bottom8	ip @, 6 #, +, c@, ;,
:, ptext	x8 left !,  y8 top !,  len8 length !,  ip @, 4 #, +, charp !, text ;,
:, pdwtext	x8 left !,  y8 top !,  len8 length !,  ip @, 4 #, +, charp !, dwtext ;,
:, 80c		x8 -80 #, +, $8000 #, and, if, opc kTEXT xor, if, ;, then, ptext then, ;,
:, 40c		x8 -40 #, +, $8000 #, and, if, opc kDWTEXT xor, if, ;, then, pdwtext then, ;,
:, cl5		;,
:, class5	opc $F0 #, and, $40 #, xor, if, 2inc ;, then, 6inc ;,
:, cl4		;,
:, class4	opc $F0 #, and, $30 #, xor, if, class5 ;, then, cl4 8 #, inc ;,
:, cl3		;,
:, class3	opc $F0 #, and, $20 #, xor, if, class4 ;, then, cl3 6inc ;,
:, cl2		len8 if, y8 -18 #, +, $8000 #, and, if, 80c 40c then, then, ;,
:, class2	opc $F0 #, and, $10 #, xor, if, class3 ;, then, cl2 vinc ;,
:, i		opc kNOP xor, if, class2 ;, then, 2inc ;,
:, algn		ip @, 1 #, and, if, 1 #, inc then, ;,
:, exec		algn opc kEND xor, if, i again, then, 2inc ;,
:, stats	cslide @, $C04E #, !,  cslide @, -1 #, xor, $C09E #, !,
		nslides @, $C04A #, !, nslides @, -1 #, xor, $C09A #, !, ;,
:, slide	cls start exec stats ;,

:, next		cslide @, 1 #, +, nslides @, -1 #, xor, 1 #, +, +, $8000 #, and,
		if, 1 #, cslide @, +, cslide !, then, ;,
:, previous	cslide @, if, -1 #, cslide @, +, cslide !, then, ;,
:, first	0 #, cslide !, ;,
:, last		nslides @, -1 #, +, cslide !, ;,
:, end		k @, kcEnd xor, if, ;, then, last slide ;,
:, home		k @, kcHome xor, if, ;, then, first slide ;,
:, pgdn		k @, kcPgDn xor, if, ;, then, next slide ;,
:, pgup		k @, kcPgUp xor, if, ;, then, previous slide ;,
:, q		k @, kcQuit xor, if, ;, then, exit. ;,
:, pressed	kqdata c@, k !, kqdata c!, ;,
:, released	kqdata c@, $8000 #, xor, k !,  kqdata c!, ;,
:, wait		kqstat c@, 1 #, and, if, again, then, ;,
:, event	kqdata c@, $F0 #, xor, if, pressed ;, then, kqdata c!, wait released ;,
:, key		wait kqdata c@, $E0 #, xor, if, event ;, then, kqdata c!, again, ;,
:, main		key  pgup pgdn home end q again, ;,

:, opnfil	slidedeck-name 1 #, +, 1 +fp!,
		slidedeck-name c@, 2 +fp!,
		open
		3 +fp@, hdeck !,
		4 +fp@,
		if,	cls  0 #, left !,  0 #, top !,
			errmsg c@, length !, errmsg 1 #, +, charp !, text
			exit.
		then, ;,

:, boot		-8 fp+!, opnfil count first slide main ;,
' boot >body @ is, m2start
\ reloc" prg.m2"
redo-out

