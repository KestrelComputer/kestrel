\ findTag can be used to locate a Tag structure anywhere in RAM.
\ A Tag structure consists of several fields designed to help it stand out from random data and program data.
\	+0	$C0DE
\	+2	pointer to $C0DE above
\	+4	$DA7A
\	+6	checksum
\ The checksum over the whole structure must equal $FFFF.
\ 
\ To use, load fndtagsta with the starting address to check for, and fndtagend with the largest address to check.
\ If findTag succeeds, rsn will be 0, and fndtagsta will point to the tag found.  Otherwise, fndtagsta will be
\ undefined (usually, but not guaranteed to be, the same as fndtagend) and rsn set to indicate why.

int, fndtagend
int, fndtagsta

:, findTag
	fndtagend @, -1 #, xor, 1 #, +,  fndtagsta @, +, $8000 #, and,
	if,	fndtagsta @, 0 #, +, @,
		fndtagsta @, 2 #, +, @, +,
		fndtagsta @, 4 #, +, @, +,
		fndtagsta @, 6 #, +, @, +,
		$FFFF #, xor,
		if,  fndtagsta @, 2 #, +, fndtagsta !,  again,
		then,

		fndtagsta @, @,  $C0DE #, xor,
		if,  fndtagsta @, 2 #, +, fndtagsta !,  again,
		then,

		fndtagsta @, 2 #, +, @,  fndtagsta @,  xor,
		if,  fndtagsta @, 2 #, +, fndtagsta !,  again,
		then,

		fndtagsta @, 4 #, +, @,  $DA7A #, xor,
		if,  fndtagsta @, 2 #, +, fndtagsta !,  again,
		then,

		0 #, rsn !,
		exit,
	then,
	ENOTFOUND rsn !, ;,

