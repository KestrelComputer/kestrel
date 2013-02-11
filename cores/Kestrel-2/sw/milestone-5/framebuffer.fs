\ Constants useful for range checking
' #ch/row >body @ negate 1- const, -W-1    ( used for checking if x <= #ch/row )
' #rows >body @ negate 1- const, -H-1    ( used for checking if y <= #rows )

:, (br)		;,

\ Error conditions preventing BlackRect from working
:, L>W		ErrFlag @, 1 #, xor, ErrFlag !, ;,
:, R>W		ErrFlag @, 2 #, xor, ErrFlag !, ;,
:, L>R		ErrFlag @, 4 #, xor, ErrFlag !, ;,
:, T>H		ErrFlag @, 8 #, xor, ErrFlag !, ;,
:, B>H		ErrFlag @, 16 #, xor, ErrFlag !, ;,
:, T>B		ErrFlag @, 32 #, xor, ErrFlag !, ;,

\ Guards against above-mentioned errors
:, L<=W		Left @, -W-1 +, $8000 #, and, if, exit, then, L>W ;,
:, R<=W		Right @, -W-1 +, $8000 #, and, if, exit, then, R>W ;,
:, L<=R		Right @, -1 #, xor, Left @, +, $8000 #, and, if, exit, then, L>R ;, 
:, T<=H		Top @, -H-1 +, $8000 #, and, if, exit, then, T>H ;,
:, B<=H		Bottom @, -H-1 +, $8000 #, and, if, exit, then, B>H ;,
:, T<=B		Bottom @, -1 #, xor, Top @, +, $8000 #, and, if, exit, then, T>B ;,
:, validate	0 #, ErrFlag !,  L<=W R<=W L<=R  T<=H B<=H T<=B ;,

\ Public API
:, BlackRect	validate  ErrFlag @, if, exit, then, (br) ;,

