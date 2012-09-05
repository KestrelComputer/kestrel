program progmem
0 origin

defer, reset

char, k
char, n
char, dg0
char, dg1
char, dg2
char, dg3
int,  ctr

$1000 const, ledport
$2000 const, kqstat
$2002 const, kqdata


\ The S16X4 lacks logical shift instructions of any kind, so we use this
\ look-up table as a means of implementing a byte-wide 4-bit logical
\ shift left operation.

create, shltab hex
   00 c,, 00 c,, 00 c,, 00 c,, 00 c,, 00 c,, 00 c,, 00 c,, 
   00 c,, 00 c,, 00 c,, 00 c,, 00 c,, 00 c,, 00 c,, 00 c,, 
   01 c,, 01 c,, 01 c,, 01 c,, 01 c,, 01 c,, 01 c,, 01 c,, 
   01 c,, 01 c,, 01 c,, 01 c,, 01 c,, 01 c,, 01 c,, 01 c,, 
   02 c,, 02 c,, 02 c,, 02 c,, 02 c,, 02 c,, 02 c,, 02 c,, 
   02 c,, 02 c,, 02 c,, 02 c,, 02 c,, 02 c,, 02 c,, 02 c,, 
   03 c,, 03 c,, 03 c,, 03 c,, 03 c,, 03 c,, 03 c,, 03 c,, 
   03 c,, 03 c,, 03 c,, 03 c,, 03 c,, 03 c,, 03 c,, 03 c,, 
   04 c,, 04 c,, 04 c,, 04 c,, 04 c,, 04 c,, 04 c,, 04 c,, 
   04 c,, 04 c,, 04 c,, 04 c,, 04 c,, 04 c,, 04 c,, 04 c,, 
   05 c,, 05 c,, 05 c,, 05 c,, 05 c,, 05 c,, 05 c,, 05 c,, 
   05 c,, 05 c,, 05 c,, 05 c,, 05 c,, 05 c,, 05 c,, 05 c,, 
   06 c,, 06 c,, 06 c,, 06 c,, 06 c,, 06 c,, 06 c,, 06 c,, 
   06 c,, 06 c,, 06 c,, 06 c,, 06 c,, 06 c,, 06 c,, 06 c,, 
   07 c,, 07 c,, 07 c,, 07 c,, 07 c,, 07 c,, 07 c,, 07 c,, 
   07 c,, 07 c,, 07 c,, 07 c,, 07 c,, 07 c,, 07 c,, 07 c,, 
   08 c,, 08 c,, 08 c,, 08 c,, 08 c,, 08 c,, 08 c,, 08 c,, 
   08 c,, 08 c,, 08 c,, 08 c,, 08 c,, 08 c,, 08 c,, 08 c,, 
   09 c,, 09 c,, 09 c,, 09 c,, 09 c,, 09 c,, 09 c,, 09 c,, 
   09 c,, 09 c,, 09 c,, 09 c,, 09 c,, 09 c,, 09 c,, 09 c,, 
   0A c,, 0A c,, 0A c,, 0A c,, 0A c,, 0A c,, 0A c,, 0A c,, 
   0A c,, 0A c,, 0A c,, 0A c,, 0A c,, 0A c,, 0A c,, 0A c,, 
   0B c,, 0B c,, 0B c,, 0B c,, 0B c,, 0B c,, 0B c,, 0B c,, 
   0B c,, 0B c,, 0B c,, 0B c,, 0B c,, 0B c,, 0B c,, 0B c,, 
   0C c,, 0C c,, 0C c,, 0C c,, 0C c,, 0C c,, 0C c,, 0C c,, 
   0C c,, 0C c,, 0C c,, 0C c,, 0C c,, 0C c,, 0C c,, 0C c,, 
   0D c,, 0D c,, 0D c,, 0D c,, 0D c,, 0D c,, 0D c,, 0D c,, 
   0D c,, 0D c,, 0D c,, 0D c,, 0D c,, 0D c,, 0D c,, 0D c,, 
   0E c,, 0E c,, 0E c,, 0E c,, 0E c,, 0E c,, 0E c,, 0E c,, 
   0E c,, 0E c,, 0E c,, 0E c,, 0E c,, 0E c,, 0E c,, 0E c,, 
   0F c,, 0F c,, 0F c,, 0F c,, 0F c,, 0F c,, 0F c,, 0F c,, 
   0F c,, 0F c,, 0F c,, 0F c,, 0F c,, 0F c,, 0F c,, 0F c,, 
decimal

\ Mapping from a hexadecimal nybble to a set of LED segments showing
\ that nybble's value.

create, segtab hex
   3F c,, 06 c,, 5B c,, 4F c,, 66 c,, 6D c,, 7D c,, 07 c,,
   7F c,, 6F c,, 77 c,, 7C c,, 39 c,, 5E c,, 79 c,, 71 c,,
decimal

:, vacate   dg2 c@, dg3 c!,  dg1 c@, dg2 c!,  dg0 c@, dg1 c!, ;,
:, nybble   vacate  n c@, segtab +, c@, dg0 c!, ;,
:, msn      k c@, shltab +, c@, n c!, nybble ;,
:, lsn      k c@, 15 #, and, n c!, nybble ;,
:, update   msn lsn ;,
:, handle   kqdata c@, k c!,  update  kqdata c!, ;,
:, dl       ctr @, -1 #, +, ctr !,  ctr @, if, again, then, ;,
:, delay    $1000 #, ctr !, dl ;,
:, d0       dg0 c@, $1000 #, xor, ledport !, delay ;,
:, d1       dg1 c@, $2000 #, xor, ledport !, delay ;,
:, d2       dg2 c@, $4000 #, xor, ledport !, delay ;,
:, d3       dg3 c@, $8000 #, xor, ledport !, delay ;,
:, dark     0 ledport !, ;,
:, refresh  d3 d2 d1 d0 dark ;,
:, -qempty  kqstat c@, 1 #, and, 1 #, xor, ;,
:, start    -qempty if, handle then, refresh again, ;,
:, clr      0 #, dg0 c!, 0 #, dg1 c!, 0 #, dg2 c!, 0 #, dg3 c!, ;,
:, main     clr start ;,

' main >body @ is, reset
cr even image
cr odd image

