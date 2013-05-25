\ Dependencies:
\ 
\ dt ( -- a)	Variable	Top of data stack cache

:, fetch,	dt @, @, dt !, _nxt ;,
:, cfetch,	dt @, c@, dt !, _nxt ;,
:, store,	dc @, @, dt @, !,  dc @, 2 #, +, @, dt !,  dc @, 4 #, +, dc !,  _nxt ;,
:, cstore,	dc @, @, dt @, c!,  dc @, 2 #, +, @, dt !,  dc @, 4 #, +, dc !,  _nxt ;,
:, +store,	dt @, @, dc @, @, +, dt @, !, dc @, 2 #, +, @, dt !,  dc @, 4 #, +, dc !,  _nxt ;,

