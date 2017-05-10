\ Dependencies
\
\ Cursor Management:
\ hide ( -- ) Hides the cursor.
\ reveal ( -- ) Reveals the cursor.
\ mvright ( -- ) Moves cursor to the right one character.
\ mvdown ( -- ) Moves cursor down one line.
\ return ( -- ) Moves cursor to the left edge of the current line.
\ home ( -- ) Moves cursor to upper-lefthand corner.
\ getxy ( -- ) Transfers current cursor location into x and y variables.
\ REdge? ( -- f ) True if the cursor is on the right-hand edge of the screen.
\ BEdge? ( -- f ) True if the cursor is on the bottom edge of the screen.
\ x ( -- a ) Horizontal coordinate
\ y ( -- a ) Vertical coordinate
\ Left ( -- a ) Left-edge/horizontal coordinate when drawing to framebuffer.
\ Top ( -- a ) Top-edge/vertical coordinate when drawing to framebuffer.
\
\ Framebuffer:
\ Stamp ( -- ) Prints a glyph at a specified location on the screen.
\ Scroll ( -- ) Move screen contents up one line.
\ fontBase ( -- a ) Constant-like providing address of font bitmap data.  The font bitmap is 2048x8 pixels.
\ Glyph ( -- a ) Variable pointing to base address of the glyph.
\ Stride ( -- a ) Variable indicating how wide of a bitmap (in bytes) the glyph image resides in.
\
\ Tty-specific:
\ chr ( -- a ) Variable containing character to emit.  (PrintCh only)
\ strp ( -- a ) Variable pointing to the beginning of an 8-bit text string (PrintStr only)
\ strl ( -- a ) Variable measuring the length of the string PrintStr should print


:, 0tty		home ;,

int, where
create, wheretab
	1 c,, 1 c,, 2 c,, 3 c,,

:, .ch		fontBase chr c@, +, Glyph !,  256 #, Stride !,  getxy x @, Left !, y @, Top !,  Stamp ;,
:, either	REdge? 2 #, and, where !,  BEdge? 1 #, and,  where @, xor, wheretab +, c@, where !, ;,
:, midline	where @, 1 #, xor, if, exit, then, .ch mvright ;,
:, eol		where @, 2 #, xor, if, exit, then, .ch return mvdown ;,
:, corner	where @, 3 #, xor, if, exit, then, .ch return scroll ;,
:, PrintCh	hide  either midline eol corner  reveal ;,
:, ClearEol	getxy x @, Left !, y @, Top !, #ch/row Right !, y @, 1 #, +, Bottom !, BlackRect ;,

:, .ch		strp @, c@, chr c!, PrintCh ;,
:, incstrp	strp @, 1 #, +, strp !, ;,
:, decstrl	strl @, -1 #, +, strl !, ;,
:, PrintStr	strl @, if, .ch incstrp decstrl again, then, ;,

:, either	BEdge? 1 #, and, where !, ;,
:, mid		where @, if, exit, then,  mvdown return ;,
:, btm		where @, 1 #, xor, if, exit, then,  return scroll ;,
:, .cr		hide either mid btm reveal ;,
