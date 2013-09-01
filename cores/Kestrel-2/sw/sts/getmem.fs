\ getmem.fs
\ 
\ These routines provide a dynamic memory management facility, allowing
\ applications to request blocks of memory of a given size, and to release it
\ later if required.
\ 
\ Pools are maintained through a singly linked, circular list of nodes with the
\ invariant that a node N can point to node M if and only if M appears at a higher
\ address than N, and which follows N immediately.  So, if looking at a memory
\ dump of three nodes, A, B, and C in that order, A generally cannot point directly
\ to C.  The sole exception is if A and B both represent free chunks of memory, where
\ B's space coalesces with A to reduce fragmentation.
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

-2 cells constant -/node
 2 cells constant /node
/node 1- constant roundup

\ fmtmem formats a memory pool with the required metadata to support allocation requests.
\ reqsize holds how big the pool is in bytes, and p points to its first byte.
\ 
\ Beware: formatting a pool that's been previously used will, in effect, forcefully de-
\ allocate everything from that pool.

: fmtmem	p @ p @ !  reqsize @ -/node and -/node + p @ cell+ ! ;

\ getmem allocates reqsize bytes from the system memory pool.  If it can be satisfied,
\ p holds a pointer to the block, result is zero, and reason is undefined.
\ Otherwise, p remains undefined, result is non-zero, and reason provides some indication
\ why.

  : gmsplit	p @ @  p @ /node + reqsize @ + !
		p @ /node + reqsize @ +  p @ !
		p @ cell+ @  /node - reqsize @ -  p @ @ cell+ !
		reqsize @ 1 or p @ cell+ ! ;

  : gmstep	p @ cell+ @ 1 and if p @ @ p ! exit then
		BEGIN  p @ @ cell+ @ 1 and 0=  p @ @ @ poolbase @ = 0= and
		WHILE  p @ @ cell+ @ /node + p @ cell+ +!
		       p @ @ @ p @ !
		REPEAT
		p @ cell+ @ reqsize @ U< if p @ @ p ! exit then
		p @ cell+ @ reqsize @ /node 2* + U>= if gmsplit  /node p +!  0 result !  exit then
		p @ cell+ @ 1 or p @ cell+ !  /node p +!  0 result ! ;

: getmem	EBASE reason !  -1 result !  poolbase @ 0= if exit then
		ESIZE reason !  poolbase @ p !  reqsize @ roundup + -/node and reqsize !
		BEGIN gmstep result @ 0= p @ poolbase @ = or UNTIL ;

\ relmem releases a chunk of memory allocated by getmem.

: relmem	-/node p +!  p @ cell+ @  -/node and p @ cell+ !  0 result ! ;

