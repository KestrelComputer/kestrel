\ Main entry point for the STS kernel starts here.
\ This must be a defer vector.
\ We revector to a word named "cold" below.

include errors.fs
include constants.fs

$0400 origin
defer, coldstart

:, halt,	again, ;,
:, crash	$C000 #, !,  $C000 #, @, -1 #, xor, $C050 #, !,  $AAAA #, $C0A0 #, !, ;,
:, 0=		if, 0 #, exit, then, -1 #, ;,

\ fillRect draws very simple rectangular patterns on the screen.
\ This can be used to clear the screen, or to let the user in on the current progress of something.
\ %fp points to the drawing control block.  It's fields are as follows:
\	+0	return PC
\	+1	Current bitmap pointer ($C000 <= p < $FE80 /\ (p & 1) == 0)
\	+2	WORDS per row to draw
\	+3	Residue to add to bitmap pointer after completing a row.  Beware of invariants.
\	+4	Number of rows to draw.
\	+5	Word to paste onto the bitmap.
\	+6	(Internal) Word counter
\	+7	(Internal) Row counter
\ This procedure does not return anything.

:, fillrow
	6 +fp@,
	if,	5 +fp@, 1 +fp@, !,
		1 +fp@, 2 #, +, 1 +fp!,
		6 +fp@, -1 #, +, 6 +fp!,
		again,
	then,
	3 +fp@, 1 +fp@, +, 1 +fp!, ;,

:, fillrows
	7 +fp@, if, 2 +fp@, 6 +fp!, fillrow  7 +fp@, -1 #, +, 7 +fp!, again, then, ;,

sub: fillRect
	4 +fp@, 7 +fp!, fillrows  rfs,

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

sub: findTag
	2 +fp@, -1 #, xor, 1 #, +,  1 +fp@, +, $8000 #, and,
	if,	1 +fp@, 0 #, +, @,
		1 +fp@, 2 #, +, @, +,
		1 +fp@, 4 #, +, @, +,
		1 +fp@, 6 #, +, @, +,
		$FFFF #, xor,
		if,  1 +fp@, 2 #, +, 1 +fp!,  ' findTag >BODY @ #, go,
		then,

		1 +fp@, @,  $C0DE #, xor,
		if,  1 +fp@, 2 #, +, 1 +fp!,  ' findTag >BODY @ #, go,
		then,

		1 +fp@, 2 #, +, @,  1 +fp@,  xor,
		if,  1 +fp@, 2 #, +, 1 +fp!,  ' findTag >BODY @ #, go,
		then,

		1 +fp@, 4 #, +, @,  $DA7A #, xor,
		if,  1 +fp@, 2 #, +, 1 +fp!,  ' findTag >BODY @ #, go,
		then,

		1 +fp@, 3 +fp!,  0 #, 4 +fp!,
		rfs,
	then,
	0 #, 3 +fp!,  ENOTFOUND 4 +fp!,
	rfs,

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

int, poolbase
int, p

sub: fmtmem
	1 +fp@, 1 +fp@, !,
	2 +fp@, -/node and, -/node +, 1 +fp@, 2 #, +, !,
	rfs,

\ getmem allocates a block of memory from a formatted memory pool.  The poolbase
\ variable must point to the pool to allocate from.
\ Arguments:
\	+0	Return PC
\	+1	Size to allocate, in bytes
\ If successful, it returns:
\	+2	Pointer to allocated block of memory
\	+3	0
\ Otherwise:
\	+2	undefined
\	+3	non-zero reason code.

:, gm2
	-1 +fp@, /node +, 1 +fp@, +, p !,  -1 +fp@, @,  p @, !,
	-1 +fp@, /node +, 1 +fp@, +,   -1 +fp@, !,
	1 +fp@, /node +, -1 #, xor, 1 #, +,  -1 +fp@, 2 #, +, @, +,  -1 +fp@, @, 2 #, +, !,
	1 +fp@, 1 #, xor, -1 +fp@, 2 #, +, !,
	-1 +fp@, /node +, 2 +fp!,  0 #, 3 +fp!,
	rfs,

:, gmCombine
	-1 +fp@, @, 2 #, +, @, 1 #, and, if, exit, then,
	-1 +fp@, @, poolbase @, xor, if,
		-1 +fp@, 2 #, +, -3 +fp!,
		-1 +fp@, @, 2 #, +, @, /node +, -3 +fp@, @, +, -3 +fp@, !,
		-1 +fp@, @, @, -1 +fp@, !,
	then, ;,

:, gm1
	-1 +fp@, 2 #, +, @, -2 +fp!,

	-2 +fp@,  1 #, and,
	if,	-1 +fp@, @, -1 +fp!,
		-1 +fp@, poolbase @, xor, if, again, then,
		0 #, 2 +fp!,  ESIZE $100 #, +, 3 +fp!, rfs,
	then,

	gmCombine

	-1 +fp@, 2 #, +, @, -2 +fp!,

	1 +fp@,  -1 #, xor, 1 #, +,  -2 +fp@, +,  $8000 #, and,
	if,	-1 +fp@, @, -1 +fp!,
		-1 +fp@, poolbase @, xor, if, again, then,
		0 #, 2 +fp!,  ESIZE $500 #, +, 3 +fp!, rfs,
	then,

	/node /node +, 1 +fp@, +, -1 #, xor, 1 #, +,  -2 +fp@, +, $8000 #, and, $8000 #, xor,
	if,	gm2
	then,

	-2 +fp@, 1 #, xor, -1 +fp@, 2 #, +, !,
	-1 +fp@, /node +, 2 +fp!,  0 #, 3 +fp!,
	rfs, ;,

sub: getmem
	poolbase @,
	if,	poolbase @, -1 +fp!,
		1 +fp@, roundup +, -/node and, 1 +fp!,
		gm1
	then,
	0 #, 2 +fp!,  EBASE 3 +fp!,
	rfs,

\ relmem is used to release previously allocated memory, as returned by getmem.
\ Arguments:
\	+0	Return PC
\	+1	Block of memory to release, as returned by getmem.
\ Nothing is returned.

sub: relmem
	1 +fp@,  -/node +,  1 +fp!,
	1 +fp@, 2 #, +, @,  -/node and,  1 +fp@, 2 #, +, !,
	rfs,

\ First instruction of STS starts here.  coldstart vectors here.

:, cold		$4000 #, %fp !,			( Initialize the STS frame pointer )
		-8 fp+!,			( Let user know we're running )
			$C000 #, 1 +fp!,
			40 #, 2 +fp!,
			80 #, 3 +fp!,
			100 #, 4 +fp!,
			$0000 #, 5 +fp!,
			fillRect

			0 #, 1 +fp!,		( locate free memory pool )
			$3000 #, 2 +fp!,
			findTag
			4 +fp@, if,		( If not found... )
				$C000 #, 1 +fp!,	( indicate error to user and halt )
				40 #, 2 +fp!,
				0 #, 3 +fp!,
				200 #, 4 +fp!,
				$FFFF #, 5 +fp!,
				fillRect
				halt,
			then,
			3 +fp@, $C000 #, +, 1 +fp!,
			3 +fp@, $C000 #, +, poolbase !,
			3 +fp@, -1 #, xor, 1 #, +, $4000 #, +, 2 +fp!,
			fmtmem

\			$C000 #, 1 +fp!,	( Memory pool updated.  Time to mount our filesystem. )
\			40 #, 2 +fp!,
\			80 #, 3 +fp!,
\			100 #, 4 +fp!,
\			$0000 #, 5 +fp!,
\			fillRect

			256 #, 1 +fp!,
			getmem
			3 +fp@,
			if,	$F640 #, crash halt,
			then,
			2 +fp@, 0=
			if,	$F642 #, crash halt,
			then,
			2 +fp@, -3 +fp!,
			256 #, 1 +fp!,
			getmem
			3 +fp@,
			if,	$F644 #, crash halt,
			then,
			2 +fp@, -3 +fp@, xor, 0=
			if,	$F646 #, crash halt,
			then,

			2 +fp@, 1 +fp!, relmem
			-3 +fp@, 1 +fp!, relmem

			512 #, 1 +fp!,
			getmem
			3 +fp@,
			if,	$F740 #, crash halt,
			then,

			2 +fp@,  poolbase @, /node +, xor, crash
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
