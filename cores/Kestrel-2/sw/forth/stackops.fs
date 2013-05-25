\ Dependencies:
\ 
\ dc ( -- a )	Variable	Data stack counter; points to 2nd top of stack
\ pc ( -- a )	Variable	Program counter
\ dt ( -- a )	Variable	Data top-of-stack cache
\ _nxt ( -- )	Primitive	Jumps to the next Forth word to execute

:, dup,		dc @, -2 #, +, dc !,  dt @, dc @, !,  _nxt ;,
:, over,	dc @, -2 #, +, dc !,  dt @, dc @, !,  dc @, 2 #, +, @, dt !,  _nxt ;,
:, swap,	dt @, dc @, @, dt !, dc @, !,  _nxt ;,
:, rot,		dt @, dc @, @, dt !, dc @, !,  dt @, dc @, 2 #, +, @, dt !, dc @, 2 #, +, !,  _nxt ;,
:, drop,	dc @, @, dt !,  dc @, 2 #, +, dc !,  _nxt ;,
:, dolit,	dc @, -2 #, +, dc !,  dt @, dc @, !,  pc @, @, dt !,  pc @, 2 #, +, pc !,  _nxt ;,
:, nip,		dc @, 2 #, +, dc !,  _nxt ;,
