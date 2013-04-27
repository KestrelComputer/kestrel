\ Dependencies:
\
\ BLINK_TICKS ( -- n )  The number of ticks between cursor toggles.
\
\ toggle ( -- )  Blinks the cursor on the screen.


int, ticks

:, 0timer	BLINK_TICKS ticks !, ;,

:, ticks--	ticks @, -1 #, +, ticks !, ;,
:, ?toggle	ticks @, if, exit, then, toggle 0timer ;,
:, tick		ticks-- ?toggle ;,
