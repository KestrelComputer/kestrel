\ clocks points to an array of counters, each corresponding to
\ a local block buffer.  Whenever a buffer is referenced, the
\ corresponding clock field is updated with the current
\ reference clock.  When all blocks are used, one must be
\ selected for eviction; this software selects the block with
\ the smallest clock value.  This implements the LRU algorithm.
tglobal clocks

\ blocks points to an array mapping local buffers to storage
\ block numbers.  0 means not yet assigned.
tglobal blocks

\ laundry points to an array of bytes, each corresponding to
\ a local block buffer, which contains flags relevant to that
\ block.  The flags are:
\ 
\ Bit 0: 1 = block is marked for update.  0 = block is clean.
\        (Also known as the "dirty" bit, hence "laundry".)
tglobal laundry

\ The actual buffers themselves.
tglobal buffers

\ The access clock.  Each reference to BLOCK or BUFFER will
\ increment this clock.
tglobal bclk

\ lastblk ( -- a ) records the most recently accessed block
\ number.
tglobal lastblk

\ BLK ( -- a ) records the task's most recently loaded block.
\ This user variable is maintained by LOAD.
tuser BLK

\ EMPTY-BUFFERS ( -- ) unconditionally empties all local
\ buffers.  Any buffers marked for update will lose their
\ contents!
t: EMPTY-BUFFERS ( -- )
  0 lastblk !
  1 bclk !
  laundry @ 64 0 FILL
  blocks @ 64 CELLS 0 FILL
  clocks @ 64 CELLS 0 FILL ;

\ clean ( r -- ) marks the indicated block buffer cache as
\ "clean".
t: clean	0 SWAP laundry @ + C! ;

\ dirty? ( r -- f ) answers true if the indicated block
\ buffer cache is marked for update.
t: dirty?	laundry @ + C@ ;

\ >buf ( r -- a ) calculates the buffer address for the
\ provided cache row index.
t: >buf		1024 * buffers @ + ;

\ >blk ( r -- a ) calculates the block cache address for the
\ provided cache row index.
t: >blk		CELLS blocks @ + ;

\ >clk ( r -- a ) calculates the clock cache address for the
\ provided cache row index.
t: >clk		CELLS clocks @ + ;

\ wrb ( r -- ) writes back the indicated block buffer.
t: wrb ( r -- )	DUP >R R@ >buf R@ CELLS
		blocks @ + @ 1 LSHIFT 2 PUTS THROW R> clean ;

\ FLUSH ( -- ) empties all local buffers.  Before doing so,
\ any buffers marked for update will be written back.
t: FLUSH ( -- )
  0 BEGIN DUP 64 < WHILE
    DUP dirty? IF DUP wrb THEN
    1+
  REPEAT DROP ;

\ missing ( b -- b -1 / b r 0 ) will look up block 'b' in the
\ internal cache.  If it's missing from the cache, return TRUE.
\ Otherwise, return the cache row and FALSE.
t: missing ( b -- b -1 / b r 0 )
  0 BEGIN DUP 64 < WHILE
    2DUP CELLS blocks @ + @ = IF 0 EXIT THEN
    1+
  REPEAT DROP -1 ;

\ UPDATE ( -- ) marks the most recently referenced block as
\ needing to be written back to storage if the buffer is ever
\ flushed.
t: UPDATE ( -- )
  lastblk @ missing IF DROP EXIT THEN
  NIP laundry @ + DUP C@ 1 OR SWAP C! ;

\ clk! ( r -- ) updates the clock for the corresponding
\ cache line.
t: clk!		bclk @ DUP 1+ bclk ! SWAP >clk ! ;

\ assign ( b r -- a ) assigns a specified cache row to the
\ provided block.  It answers with the corresponding block
\ buffer for the cache row specified.
t: assign ( b r -- a )
  >R R@ clk!  R@ >blk !  R@ clean R> >buf ;

\ ?wrb ( r -- ) cleans the specified cache row.  If it's
\ dirty, it'll flush the cache contents to backing store.
\ Otherwise, no action will be taken.  In either case,
\ the dirty bit for the cache row is removed.
t: ?wrb ( r - )	DUP dirty? IF wrb EXIT THEN DROP ;

\ lru ( b -- b r ) selects the least frequently referenced
\ block cache row and returns it.
t: lru ( b -- b r )
  -1 0 BEGIN DUP 64 < WHILE
    DUP >clk @ 0 = IF NIP EXIT THEN
    SWAP OVER >clk @ UMIN SWAP
    1+
  REPEAT DROP
  0 BEGIN DUP 64 < WHILE
    2DUP >clk @ = IF NIP EXIT THEN
    1+
  REPEAT
  .S ABORT" LRU fault" ;

\ select ( b -- r ) attempts to locate block 'b' in the blocks
\ already known.  If the block is not known, it will select a
\ block buffer using the least-recently-used (LRU) algorithm.
\ The result is a cache row 'r'.  Note that it's possible for
\ the row returned to not match the specified block, so be
\ prepared to write-back its contents before using it.
t: select ( b -- r ) missing IF lru THEN ;

\ BUFFER ( n -- addr ) does not fetch block 'n' from backing
\ store; rather it merely assigns a local buffer for eventual
\ write-back to block 'n' (be sure to UPDATE the buffer).
\ This is useful if you know you're just going to over-write
\ the entire block (cuts I/O time in half, since no input
\ step need be performed).
\ 
\ Block 0 is illegal, and referencing it will throw an
\ exception.
t: BUFFER	DUP lastblk ! select DUP ?wrb assign ;

\ BLOCK ( n -- addr ) fetches block 'n' from backing storage,
\ if necessary.  It answers with the address of the in-memory
\ buffer containing the contents of the specified block.  If
\ the selected buffer already contains updated data, it will
\ be written back first.
\ 
\ Block 0 is illegal, and referencing it will throw an
\ exception.
t: BLOCK ( b - a )
  missing
  IF   DUP >R BUFFER DUP R> 2* 2 GETS THROW
  ELSE DUP clk! >buf SWAP lastblk ! THEN ;

\ LOAD ( n -- ) loads the block specified and evaluates it
\ as Forth program source, as though you had directly typed
\ it at the command-line interface.

t: blkParse ( c -- a u // see PARSE for stack effect )
  >R BLK @ BLOCK >IN @ + 1024 >IN @ - R> parse >IN +! ;

t: LOAD ( n -- )
  BLK @ >R BLK !
  >IN @ >R 0 >IN !
  'PARSE @ >R doLIT blkParse 'PARSE !
  'PROMPT @ >R 0 'PROMPT !
  EVAL
  R> 'PROMPT !
  R> 'PARSE !
  R> >IN !
  R> BLK ! ;

\ 0blocks ( -- ) allocates block buffers in the dictionary
\ so that we have some place to conduct I/O.  This allows
\ the block driver to exist in ROM.  It has the rather nice
\ side effect of allowing the competent user to reallocate
\ the buffers to suit the needs of her application.
t: 0blocks ( -- )
  HERE clocks ! 64 CELLS ALLOT
  HERE blocks ! 64 CELLS ALLOT
  HERE laundry ! 64 ALLOT
  HERE buffers ! 64 1024 * ALLOT
  EMPTY-BUFFERS
  ;
