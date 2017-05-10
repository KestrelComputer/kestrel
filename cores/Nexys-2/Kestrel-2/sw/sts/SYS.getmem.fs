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

sub: p_getmem
	mplsta @,
	if,	mplsta @, memptr !,
		memsiz @, roundup +, -/node and, memsiz !,
		gm1
	then,
	0 #, memptr !,  EBASE rsn !,
	rfs,

:, getmem
	-1 fp+!, p_getmem 1 fp+!, ;,

\ relmem is used to release previously allocated memory, as returned by getmem.
\ relmem expects the block to release in memptr.
\ Nothing is returned.

:, relmem
	memptr @,  -/node +,  memptr !,
	memptr @, 2 #, +, @,  -/node and,  memptr @, 2 #, +, !,  ;,

