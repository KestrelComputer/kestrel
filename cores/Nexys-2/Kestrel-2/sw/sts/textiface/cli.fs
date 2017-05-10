\ Dependencies:
\
\ getkey ( -- )		Blocks until a decodable key event happens.  Places the key in the ckey variable.
\ ckey ( -- a )		Contains the most recently read key event.
\					Values between $0000-$007F represent ASCII characters.
\					Values between $0080-$00FF are, at present, undefined.
\					Values between $0100-$017F represent extended PS/2 key events.
\					Values between $0180-$FFFF are, at present, undefined.
\
\					Note that carriage return is assigned the value of $000D, not $000A as commonly used in Unix.
\
\ #ib ( -- a )		Variable containing the length of the current input buffer contents.
\ ib ( -- a )		Constant address of input buffer.
\ /ib ( -- n )		Constant capacity of the input buffer.
\
\ reveal ( -- )		Shows cursor on the screen.
\ hide ( -- )		Hides cursor from the screen.
\ mvleft ( -- )		Move cursor to the left one place.
\
\ chr ( -- ca )		Variable: character to print
\ strp ( -- a )		Variable: pointer to string to print
\ strl ( -- a )		Variable: length of string to print
\ PrintStr ( -- )	Prints a string to the console
\ ClearEol ( -- )   Clears everything to the right of the cursor
\
\ setbm ( -- )		Preserves cursor position
\ resetbm ( -- )	Restores cursor position.
\
\ Left and Right-half buffer pointers.
\
\ ib
\ |
\ *------ ( + /ib ) ---------+
\ |                          |
\ v                          v
\ +--------+--------+--------+
\ |  Left  |////////|  Right |
\ +--------+--------+--------+
\ ^        ^        ^        ^
\ |        |        |        |
\ |        |        |        +-- re
\ |        |        +----------- rs
\ |        +-------------------- le
\ +----------------------------- ls
int, ls
int, le
int, rs
int, re

:, rw		rs @, -1 #, xor, 1 #, +, re @, +, ;,
:, lw		ls @, -1 #, xor, 1 #, +, le @, +, ;,

:, (getkey)	reveal getkey hide ;,
:, .right	setbm  rs @, strp !, rw strl !, PrintStr ClearEol resetbm ;,
:, (bs)		ls @, le @, xor, if, mvleft .right le @, -1 #, +, le !, then, ;,
:, (del)	rs @, re @, xor, if, rs @, 1 #, +, rs !, then, ;,
:, (lc)		ls @, le @, xor, if, mvleft rs @, -1 #, +, rs !,  le @, -1 #, +, le !,  le @, c@, rs @, c!,  then, ;,
:, (rc)		rs @, re @, xor, if, mvright rs @, c@, le @, c!,  rs @, 1 #, +, rs !,  le @, 1 #, +, le !,  then, ;,
:, ins		ckey @, le @, c!,  le @, 1 #, +, le !, ;,
:, .char	ckey @, chr c!,  PrintCh ;,
:, graphic	ckey @, if,  le @, rs @, xor, if,  ins .char .right 0 #, ckey !,  then, then, ;,
:, bs		ckey @, $0008 #, xor, if, exit, then, (bs) 0 #, ckey !, ;,
:, del		ckey @, $007F #, xor, if, exit, then, (del) 0 #, ckey !, ;,
:, lc		ckey @, $0100 #, xor, if, exit, then, (lc) 0 #, ckey !, ;,
:, rc		ckey @, $0101 #, xor, if, exit, then, (rc) 0 #, ckey !, ;,
:, handle	bs del lc rc graphic ;,
:, (a)		(getkey) $000D #, ckey @, xor, if, handle again, then, ;,
:, drain	rs @, re @, xor, if, (rc) again, then, ;,
:, accept	ib ls !, ib le !,  ib /ib +, rs !,  ib /ib +, re !,  (a)  drain lw #ib !, ;,
