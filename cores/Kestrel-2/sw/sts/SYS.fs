\ Main entry point for the STS kernel starts here.
\ This must be a defer vector.
\ We revector to a word named "cold" below.

include errors.fs
include constants.fs

$0400 origin
defer, coldstart

\ Global state for all OS services.

:, halt,	again, ;,
:, crash	$C000 #, !,  $C000 #, @, -1 #, xor, $C050 #, !,  $AAAA #, $C0A0 #, !, ;,
:, 0=		if, 0 #, exit, then, -1 #, ;,

\ rsn stores the reason for a service's failure to deliver the expected results.
\ Numerous system calls can fail for a number of reasons.  See the errors.fs file
\ for a list of reasons and their most common circumstances.
int, rsn

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
\ To use, load fndtagsta with the starting address to check for, and fndtagend with the largest address to check.
\ If findTag succeeds, rsn will be 0, and fndtagsta will point to the tag found.  Otherwise, fndtagsta will be
\ undefined (usually, but not guaranteed to be, the same as fndtagend) and rsn set to indicate why.

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

\ These routines provide a dynamic memory management facility, allowing
\ applications to request blocks of memory of a given size, and to release it
\ later if required.
\ 
\ Pools are maintained through a singly linked, circular list of nodes with the
\ invariant that a node N can point to node M if and only if M appears at a higher
\ address than N, and which follows N immediately.  So, if looking at a memory
\ dump of three nodes, A, B, and C in that order, A generally cannot point directly
\ to C.  The sole exception is if A and B both represent free chunks of memory, where
\ B's space coalesces with A to reduce fragmentation.  An order like A, C, B is simply
\ right out, no matter what.  If this happens, the memory pool is corrupted, and will
\ inevitably lead to a crash.
\ 
\ The structure of a node follows (offsets in cells):
\ 
\ +0	next		Pointer to next node in the list, or back to first node.
\ 
\ +1	--111111..	The size of the allocation, in bytes, excluding the header.
\ 			Note that memory may not be requested in units smaller than
\			four bytes.
\ 
\ +1	--......1.	Unused bit.  Must be set to zero on writing, and ignored on
\			read.
\ 
\ +1	--.......1	1=block is allocated; 0=block is free.

\ fmtmem formats a memory pool with the required metadata to support allocation requests.
\ The mplsta variable must point to the start of the memory pool, while mplsiz must contain
\ its size, in bytes.  fmtmem does not return, and cannot fail.
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
\ variable must point to the pool to allocate from.  memsiz holds the request
\ size.
\ 
\ If the request can be satisfied, memptr holds the address of the allocated
\ block of memory, and rsn is zero.  Otherwise, memptr is undefined, and rsn
\ indicates why the request failed.

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
\ relmem expects the block to release in memptr.
\ Nothing is returned.

:, relmem
	memptr @,  -/node +,  memptr !,
	memptr @, 2 #, +, @,  -/node and,  memptr @, 2 #, +, !,  ;,

\ 
\ First instruction of STS starts here.  coldstart vectors here.

:, cold		$4000 #, %fp !,			( Initialize the STS frame pointer )
		-8 fp+!,			( Let user know we're running )
			$C000 #, bitmapptr !,
			40 #, wrdperrow !,
			80 #, rowendres !,
			100 #, rowperbox !,
			$AAAA #, bitmapdat !,
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
			fndtagsta @, mplsta !,
			fndtagsta @, -1 #, xor, 1 #, +, $4000 #, +, mplsiz !,
			fmtmem

			$C050 #, bitmapptr !,	( Memory pool initialized; time to mount the system filesystem. )
			40 #, wrdperrow !,
			80 #, rowendres !,
			100 #, rowperbox !,
			$5555 #, bitmapdat !,
			fillRect
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
