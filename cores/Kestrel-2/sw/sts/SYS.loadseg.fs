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

\ unloadseg cleans up all resources related to loading a segment, and disposes of the loaded segment.
\ unloadseg WILL NOT dispose of resources acquired by the program in the segment, however.

:, unloadseg
	segptr @, memptr !,
	relmem
;,

\ exec terminates the current program so that it can bring another into memory.
\ The filenameptr/filenamelen variables points to the program to load and run.
\ The paramseg variable points to an agreed upon buffer used to pass parameters and/or results.

int, parambuf

int, taskseg

:, exec
	taskseg @,
	if,	taskseg @, segptr !,
		unloadseg
		0 #, taskseg !,
	then,

	loadseg
	rsn @,
	if,	1stProgram c@, filnamlen !,
		1stProgram 1 #, +, filnamptr !,
		loadseg
		rsn @,
		if,	( panic I guess; I don't know what to do here. )
			exit,
		then,
	then,

	segptr @, taskseg !,
	segptr @, go,
;,

\ exit terminates the current program and forces the user's 1st program to be brought into
\ memory.  It will also dispose of the parameter buffer if any still exists.

:, exit.
	parambuf @,
	if,	parambuf @, memptr !,
		relmem
		0 #, parambuf !,
	then,
	1stProgram 1 #, +, filnamptr !,
	1stProgram c@, filnamlen !,
	exec
;,

