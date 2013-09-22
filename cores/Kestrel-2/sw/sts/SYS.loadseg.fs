\ loadseg.fs
\ 
\ This code provides a means of loading executable program code into memory at an
\ undetermined address, and still have it work.  Relocation happens at load-time,
\ not at compile-, link-, or run-time.

int, segptr

int, kind
int, sz
int, offset

:, rdword	
	2 #, inplen !,
	read
	rsn @,
	if,	segptr @,
		if,	segptr @, memptr !, relmem
			0 #, segptr !,
		then,	rfs,
	then,
	inpcnt @, 2 #, xor,
	if,	segptr @,
		if,	segptr @, memptr !,  relmem
			0 #, segptr !,
		then,	EBASE $1000 #, +, rsn !,  rfs,
	then,
;,

:, rdsz
	sz inpbuf !,  rdword ;,

:, rdkind
	kind inpbuf !,  rdword ;,

:, rdoffset
	offset inpbuf !,  rdword ;,


:, (loadseg)
	rdkind
	kind @, T_HUNK xor,
	if,	EBASE $3000 #, +, rsn !, exit,
	then,

	begin,	kind @, T_END xor,
	while,	rdkind
		kind @, T_CODE xor, 0=
		if,	rdsz sz @, memsiz !, getmem
			rsn @,
			if,	exit,
			then,

			memptr @, segptr !,  memptr @, inpbuf !,  sz @, inplen !,  read
			rsn @,
			if,	relmem  0 #, segptr !,  exit,
			then,
			inpcnt @, sz @, xor,
			if,	relmem  0 #, segptr !, EBASE $5000 #, +, rsn !, exit,
			then,
		then,
		kind @, T_RELOC xor, 0=
		segptr @, 0= and,
		if,	0 #, segptr !,  EBASE $7000 #, +, rsn !, exit,
		then,
		kind @, T_RELOC xor, 0=
		segptr @, and,
		if,	rdsz
			begin,	sz @,
			while,	rdoffset
				offset @, segptr @, +, @,
				segptr @, +,
				offset @, segptr @, +, !,
				sz @, -1 #, +, sz !,
			repeat,
		then,
	repeat,
	0 #, rsn !, ;,

sub: p_loadseg
	0 #, kind !, 0 #, segptr !,
	open
	rsn @,
	if,	rfs,
	then,
	filscb @, inpscb !,
	(loadseg)
	inpscb @, filscb !,  close rfs,

:, loadseg
	-1 fp+!,  p_loadseg  1 fp+!, ;,

