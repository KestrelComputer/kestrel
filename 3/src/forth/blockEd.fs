\ Screen editor -- simplified

tuser edblk

\ ..............................................................

\ 0editor ( - ) initializes the screen editor.  (For an editor
\ this simple, we take no action.  For a full-screen visual
\ editor, it may require additional initialization steps.)
t: 0editor		;

t: .line ( a n - a' )	15 XOR 2 .R SPACE DUP 64 TYPE CR 64 + ;

\ LIST ( n -- ) lists the specified block to the screen.
t: LIST		DUP edblk ! BLOCK CR 15 FOR R@ .line NEXT DROP ;

t: t		."    SCR #" DUP . CR DUP LIST CR  1+ ;

\ TRI ( n -- ) lists three blocks consecutively, each with
\ their own title.  TRI.. ( n -- n' ) is like TRI except that
\ it leaves the next block to list on the stack, so you can
\ more easily generate a continuous listing.  This is useful
\ if you want to look at a lengthy listing.
t: TRI.. ( n -- n' )	CR CR t t t ;
t: TRI ( n -- )		TRI.. DROP ;

\ INDEX ( a b -- ) prints the top line of all blocks starting
\ at a up to and including b.  This provides a kind of
\ "directory" of blocks.  This depends on you having the
\ discipline to label your source blocks with a comment on the
\ top-most line though.
t: INDEX ( a b -- )	1+ SWAP CR DO R@ 5 .R SPACE
			R@ BLOCK 64 TYPE CR LOOP ;

t: erase ( a u - )	32 FILL ;

\ CLEAN ( - ) erases the last block LIST'ed to all spaces.
t: CLEAN ( - )		edblk @ BLOCK UPDATE 1024 erase ;

\ OPEN ( n - ) opens a new blank line at line n.  Line 15 is
\ lost.
t: addr ( n - a )	64 * edblk @ BLOCK + ;
t: size ( n - m )	64 * 960 SWAP - ;
t: open ( n - )	DUP 15 U< IF DUP size >R addr DUP 64 + R> MOVE THEN ;
t: line ( n - )		addr 64 erase ;
t: OPEN ( n - )		15 OVER U< ABORT" bad line"
			DUP open line ;


t: dell ( n - )		DUP size >R addr DUP 64 + SWAP R> MOVE ;
t: bottom ( - )		edblk @ BLOCK UPDATE 960 + 64 erase ;

\ CLOSE ( n - ) deletes the specified line from the block last
\ LISTed.
t: CLOSE ( n - )    15 OVER U< ABORT" bad line" dell bottom ;

\ SET ( n "text" - ) copies the rest of the line (up to 64
\ characters) to the specified line in the block last LISTed.
\ This will overwrite the entire line, filling the rest of
\ the line with blanks if necessary.
t: SET ( n - )		>R R@ line 13 PARSE R> addr SWAP MOVE ;

