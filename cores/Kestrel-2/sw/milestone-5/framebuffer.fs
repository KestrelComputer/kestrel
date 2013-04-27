\ Dependencies:
\ 
\ Character Map Descriptor Accessor Words
\ 
\ These words are accessors, meaning they fetch the relevant fields from a
\ (logical) data structure called the Character Matrix Descriptor, or CMD.
\ The CMD tells the frame buffer logic how many characters across the frame
\ buffer is, and how many characters down.  It additionally tells the code
\ where to find the bitplane(s) for the frame buffer, so that drawing can
\ occur.
\ 
\ Note that the CMD is intrinsically hardware and framebuffer logic
\ dependent!  If you change video hardware, you'll almost certainly need
\ new framebuffer and CMD code to describe them.  The CMD's value becomes
\ apparent when you have closely-related classes of hardware.  For example,
\ this code can reasonably be expected to work (with small modifications)
\ on an Atari ST or Commodore-Amiga, for they both rely on bitplanes like the
\ Kestrel.  However, a 320x240 Mode-X VGA display will be fundamentally in-
\ compatible, and will require a completely different framebuffer driver
\ implementation.  It's likely that driver will need a slightly different set
\ of fields for the CMD as well, as mode-X VGA does not rely on bitplanes.
\ 
\ bitplane ( -- a )	Pointer to the bitplane memory.  This field is hardware
\			dependent.
\ #ch/row ( -- n )	Number of characters per row.  Assumes a fixed-width font.
\ #rows ( -- n )	Number of rows that can fit completely in the bitplane.
\ 			Partial rows are not supported.
\ #px/row ( -- n )	Number of raster-lines (pixels) per row.
\ mt/rows ( -- a )	Pointer to a table that maps row number to byte offset
\			into the bitplane.  At least #rows entries must exist.
\ mt/px ( -- a )	Pointer to a table that maps raster-line to byte offset
\			within a single row.  At least #px/row entries must exist.
\ 
\ Using this framebuffer code to render into off-screen bitmaps will require
\ a configuration that supports multiplexing between different CMDs.  A CMD must
\ exist for the screen, of course; in addition, all off-screen buffers must have
\ their own CMDs as well.
\ 
\ Frame Buffer Control Block Locators
\ 
\ The frame buffer drawing code requires space in memory to accept parameters,
\ and to maintain state as it completes its requested procedures.  This space
\ exists in a Frame Buffer Control Block, or FBCB.  This chunk of memory, like
\ the CMD above, is logical from the perspective of the framebuffer code.
\ Thus, support for multiple FBCBs or a single, global FBCB is determined through
\ external configuration.
\ 
\ These words are locators, for they return addresses to memory cells used to
\ hold state.  Some state is public, that is, intended to be used by application
\ software.  Other state is private in nature, and is not intended to be
\ utilized directly by any software except for the framebuffer code itself.
\ These private fields are documented, however, so that in a multi-FBCB system,
\ adequate space for these private fields can be reserved in each FBCB.
\ 
\ Left		The left-hand edge of a bounding rectangle.
\ Top		The top edge of a bounding rectangle.
\ Right		The right-hand edge of a bounding rectangle.
\ Bottom	The bottom edge of a bounding rectangle.
\ Glyph		The pointer to the first byte of the glyph to stamp.
\ Stride	The number of bytes between rows of the glyph image.
\ ErrFlag	This field always represents any error condition that prevented
\		the framebuffer code from completing the procedure.  The inter-
\		pretation of this field depends entirely upon the procedure
\		invoked.
\ 
\ The following fields are private: p, w, y, and r.
\ 
\ BEWARE: Make sure none of the aforelisted FBCB fields refer to previously
\ defined fields, or the framebuffer code will almost certainly crash.  They
\ _must_ correspond, in essence, to full cell-sized variables.


\ Constants useful for range checking
' #ch/row >body @ negate 1- const, -W-1    ( used for checking if x <= #ch/row )
' #rows >body @ negate 1- const, -H-1    ( used for checking if y <= #rows )
' #ch/row >body @ negate const, -W
' #rows >body @ negate const, -H

\ Common code to handle rectangular regions of the display.
\ Depending on the configuration of the AND- and XOR-masks,
\ this code can either clear, set, or reverse video in a character-aligned
\ rectangular region of the display.
char, andmask
char, xormask

:, incy		y @, 1 #, +, y !, ;,
:, decw		w @, -1 #, +, w !, ;,
:, incp		p @, 1 #, +, p !, ;,
:, addr		p @, 1 #, xor, ;,  ( 1 #, xor, because of the way MGIA maps bytes versus words in Kestrel-2 )
:, byte		addr c@, andmask c@, and, xormask c@, xor, addr c!, ;,
:, bytes	w @, if, byte incp decw again, then, ;,
:, edge		y @, y @, +,  mt/rows +, @,
		r @, r @, +,  mt/px +, @, +,
		bitplane +, Left @, +, p !, ;,
:, width	Left @, -1 #, xor, 1 #, +, Right @, +, w !, ;,
:, raster	edge width bytes ;,
:, rasters	r @, #px/row xor, if, raster r @, 1 #, +, r !, again, then, ;,
:, row		0 #, r !,  rasters ;,
:, allrows	y @, Bottom @, xor, if, row incy again, then, ;,
:, rect		Top @, y !, allrows ;,

:, adv		Glyph @, Stride @, +, Glyph !,  p @, #ch/row +, p !,  r @, 1 #, +, r !, ;,
:, cpy		Glyph @, c@, addr c!, ;,
:, row		cpy adv ;,
:, tile		r @, #px/row xor, if, row again, then, ;,

:, (br)		$00 #, andmask c!, $00 #, xormask c!,  rect ;,
:, (rv)		$FF #, andmask c!, $FF #, xormask c!,  rect ;,
:, (s)		0 #, r !,  edge  tile ;,

\ Error conditions preventing BlackRect from working
:, L>W		ErrFlag @, 1 #, xor, ErrFlag !, ;,
:, R>W		ErrFlag @, 2 #, xor, ErrFlag !, ;,
:, L>R		ErrFlag @, 4 #, xor, ErrFlag !, ;,
:, T>H		ErrFlag @, 8 #, xor, ErrFlag !, ;,
:, B>H		ErrFlag @, 16 #, xor, ErrFlag !, ;,
:, T>B		ErrFlag @, 32 #, xor, ErrFlag !, ;,

\ Guards against above-mentioned errors
\ Notice that, in L<=R and T<=B, I do not add one to the negated value of Right
\ or Bottom.  Since -X-1 = (~X+1)-1 = ~X, we leave off the adjustment for brevity.
:, L<=W		Left @, -W-1 +, $8000 #, and, if, exit, then, L>W ;,
:, R<=W		Right @, -W-1 +, $8000 #, and, if, exit, then, R>W ;,
:, L<=R		Right @, -1 #, xor, Left @, +, $8000 #, and, if, exit, then, L>R ;, 
:, T<=H		Top @, -H-1 +, $8000 #, and, if, exit, then, T>H ;,
:, B<=H		Bottom @, -H-1 +, $8000 #, and, if, exit, then, B>H ;,
:, T<=B		Bottom @, -1 #, xor, Top @, +, $8000 #, and, if, exit, then, T>B ;,
:, validate	0 #, ErrFlag !,  L<=W R<=W L<=R  T<=H B<=H T<=B ;,

\ Guards against errors relevant to glyph-painting.
:, L<W		Left @, -W +, $8000 #, and, if, exit, then, L>W ;,
:, T<H		Top @, -H +, $8000 #, and, if, exit, then, T>H ;,
:, validateS 0 #, ErrFlag !,  L<W T<H ;,

\ Public API
:, BlackRect	validate  ErrFlag @, if, exit, then,  (br) ;,
:, ReverseVideo validate  ErrFlag @, if, exit, then,  (rv) ;,
:, Stamp		validateS  ErrFlag @, if, exit, then,  (s) ;,
