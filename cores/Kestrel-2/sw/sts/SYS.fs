\ Main entry point for the STS kernel starts here.
\ This must be a defer vector.
\ We revector to a word named "cold" below.

include errors.fs
include constants.fs

$0400 origin
defer, coldstart

\ Global state for all OS services.

int, rsn

:, halt,	again, ;,
:, crash	$C000 #, !,  $C000 #, @, -1 #, xor, $C050 #, !,  $AAAA #, $C0A0 #, !, ;,
:, 0=		if, 0 #, exit, then, -1 #, ;,

\ fillRect draws very simple rectangular patterns on the screen.
\ This can be used to clear the screen, or to let the user in on the current progress of something.
\ This procedure does not return anything.

int, bitmapptr
int, wrdperrow
int, rowendres
int, rowperbox
int, bitmapdat
int, wrdctr		( internal )
int, rowctr		( internal )

:, fillrow
	wrdctr @,
	if,	bitmapdat @, bitmapptr @, !,
		bitmapptr @, 2 #, +, bitmapptr !,
		wrdctr @, -1 #, +, wrdctr !,
		again,
	then,
	rowendres @, bitmapptr @, +, bitmapptr !, ;,

:, fillrows
	rowctr @,
	if,	wrdperrow @, wrdctr !,
		fillrow
		rowctr @, -1 #, +, rowctr !,
		again,
	then, ;,

:, fillRect
	rowperbox @, rowctr !, fillrows  ;,

\ findTag can be used to locate a Tag structure anywhere in RAM.
\ A Tag structure consists of several fields designed to help it stand out from random data and program data.
\	+0	$C0DE
\	+2	pointer to $C0DE above
\	+4	$DA7A
\	+6	checksum
\ The checksum over the whole structure must equal $FFFF.
\ 
\ findTag's parameters are as follows:
\	+0	Return PC
\	+1	Start address (must be even)
\	+2	End address (must be even)
\ Upon success, it returns:
\	+3	Address of tag
\	+4	0
\ Otherwise:
\	+3	undefined
\	+4	Reason code (non-zero)

int, fndtagend
int, fndtagsta

:, findTag
	fndtagend @, -1 #, xor, 1 #, +,  fndtagsta @, +, $8000 #, and,
	if,	fndtagsta @, 0 #, +, @,
		fndtagsta @, 2 #, +, @, +,
		fndtagsta @, 4 #, +, @, +,
		fndtagsta @, 6 #, +, @, +,
		$FFFF #, xor,
		if,  fndtagsta @, 2 #, +, fndtagsta !,  again,
		then,

		fndtagsta @, @,  $C0DE #, xor,
		if,  fndtagsta @, 2 #, +, fndtagsta !,  again,
		then,

		fndtagsta @, 2 #, +, @,  fndtagsta @,  xor,
		if,  fndtagsta @, 2 #, +, fndtagsta !,  again,
		then,

		fndtagsta @, 4 #, +, @,  $DA7A #, xor,
		if,  fndtagsta @, 2 #, +, fndtagsta !,  again,
		then,

		0 #, rsn !,
		exit,
	then,
	ENOTFOUND rsn !, ;,

\ fmtmem formats a memory pool with the required metadata to support allocation requests.
\ Arguments:
\	+0	Return PC
\	+1	Start of pool (must be even)
\	+2	Size of pool
\ No returns.
\ 
\ Beware: formatting a pool that's been previously used will, in effect, forcefully de-
\ allocate everything from that pool.

-4 const, -/node
 4 const, /node
 3 const, roundup

int, mplsta
int, mplsiz

:, fmtmem
	mplsta @, mplsta @, !,
	mplsiz @, -/node and, -/node +, mplsta @, 2 #, +, !,  ;,

\ getmem allocates a block of memory from a formatted memory pool.  The mplsta
\ variable must point to the pool to allocate from.

int, p
int, q

int, memptr
int, memsiz

:, gm2
	memptr @, /node +, memsiz @, +, p !,  memptr @, @,  p @, !,
	memptr @, /node +, memsiz @, +,   memptr @, !,
	memsiz @, /node +, -1 #, xor, 1 #, +,  memptr @, 2 #, +, @, +,  memptr @, @, 2 #, +, !,
	memsiz @, 1 #, xor, memptr @, 2 #, +, !,
	memptr @, /node +, memptr !,  0 #, rsn !,
	rfs,

:, gmCombine
	memptr @, @, 2 #, +, @, 1 #, and, if, exit, then,
	memptr @, @, mplsta @, xor, if,
		memptr @, 2 #, +, q !,
		memptr @, @, 2 #, +, @, /node +, q @, @, +, q @, !,
		memptr @, @, @, memptr @, !,
	then, ;,

:, gm1
	memptr @, 2 #, +, @, 1 #, and,
	if,	memptr @, @, memptr !,
		memptr @, mplsta @, xor, if, again, then,
		0 #, memptr !,  ESIZE $100 #, +, rsn !, rfs,
	then,

	gmCombine

	memptr @, 2 #, +, @, q !,

	memsiz @,  -1 #, xor, 1 #, +,  q @, +,  $8000 #, and,
	if,	memptr @, @, memptr !,
		memptr @, mplsta @, xor, if, again, then,
		0 #, memptr !,  ESIZE $500 #, +, rsn !, rfs,
	then,

	/node /node +, memsiz @, +, -1 #, xor, 1 #, +,  q @, +, $8000 #, and, $8000 #, xor,
	if,	gm2
	then,

	q @, 1 #, xor, memptr @, 2 #, +, !,
	memptr @, /node +, memptr !,  0 #, rsn !,
	rfs, ;,

sub: getmem
	mplsta @,
	if,	mplsta @, memptr !,
		memsiz @, roundup +, -/node and, memsiz !,
		gm1
	then,
	0 #, memptr !,  EBASE rsn !,
	rfs,

\ relmem is used to release previously allocated memory, as returned by getmem.
\ Nothing is returned.

:, relmem
	memptr @,  -/node +,  memptr !,
	memptr @, 2 #, +, @,  -/node and,  memptr @, 2 #, +, !,  ;,

\ First instruction of STS starts here.  coldstart vectors here.

:, cold		$4000 #, %fp !,			( Initialize the STS frame pointer )
		-8 fp+!,			( Let user know we're running )
			$C000 #, bitmapptr !,
			40 #, wrdperrow !,
			80 #, rowendres !,
			100 #, rowperbox !,
			$0000 #, bitmapdat !,
			fillRect

			0 #, fndtagsta !,	( locate free memory pool and initialize it. )
			$3000 #, fndtagend !,
			findTag
			rsn @, if,		( If not found... )
				$C000 #, bitmapptr !,	( indicate error to user and halt )
				40 #, wrdperrow !,
				0 #, rowendres !,
				200 #, rowperbox !,
				$FFFF #, bitmapdat !,
				fillRect
				halt,
			then,
			fndtagsta @, $C000 #, +, mplsta !,
			fndtagsta @, -1 #, xor, 1 #, +, $4000 #, +, mplsiz !,
			fmtmem

\			$C000 #, 1 +fp!,	( Memory pool updated.  Time to mount our filesystem. )
\			40 #, 2 +fp!,
\			80 #, 3 +fp!,
\			100 #, 4 +fp!,
\			$0000 #, 5 +fp!,
\			fillRect

			256 #, memsiz !,
			getmem
			rsn @,
			if,	$F640 #, crash halt,
			then,
			memptr @, 0=
			if,	$F642 #, crash halt,
			then,
			memptr @, -1 +fp!,
			256 #, memsiz !,
			getmem
			rsn @,
			if,	$F644 #, crash halt,
			then,
			memptr @, -1 +fp@, xor, 0=
			if,	$F646 #, crash halt,
			then,

			relmem
			-1 +fp@, memptr !, relmem

			512 #, memsiz !,
			getmem
			rsn @,
			if,	$F740 #, crash halt,
			then,

			memptr @,  mplsta @, /node +, xor, crash
		8 fp+!,

		
		halt, ;,

\ Let the start of free memory begin here.
\ This tag structure is discovered dynamically at boot time.
\ It must be the very last piece of code actually compiled; otherwise, the dynamic memory manager will corrupt valid program code.

pibptr @ 3 + -4 and pibptr !  ( Ensure proper structure alignment for getmem's benefit )

create, memtag
	$C0DE ,, ' memtag >BODY @ ,, $DA7A ,, $C0DE $DA7A + ' memtag >BODY @ + $FFFF xor ,,

\ Patch up the coldstart vector.

' cold >BODY @ is, coldstart

\ Emit the $SYS file image.
pib 1024 + pib pibptr @ 1024 - move
-1024 pibptr +!
out" sys/$SYS"
bye
