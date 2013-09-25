\ These entry points thunk from frame-based parameter passing rules to global-variable rules used internally.

sub: fndtag-v
	1 +fp@, fndtagsta !,
	2 +fp@, fndtagend !,
	findtag
	fndtagsta @, 3 +fp!,
	rsn @, 4 +fp!,
	rfs,

' fndtag-v >body @ is, fndtag-epv

sub: getmem-v
	1 +fp@, memsiz !,
	getmem
	memptr @, 2 +fp!,
	rsn @, 3 +fp!,
	rfs,

' getmem-v >body @ is, getmem-epv

sub: relmem-v
	1 +fp@, memptr !,
	relmem
	rfs,

' relmem-v >body @ is, relmem-epv

sub: open-v
	1 +fp@, filnamptr !,
	2 +fp@, filnamlen !,
	open
	filscb @, 3 +fp!,
	rsn @, 4 +fp!,
	rfs,

' open-v >body @ is, open-epv

sub: close-v
	1 +fp@, filscb !,
	close
	rfs,

' close-v >body @ is, close-epv

sub: read-v
	1 +fp@, inpscb !,
	2 +fp@, inpbuf !,
	3 +fp@, inplen !,
	read
	inpcnt @, 4 +fp!,
	rsn @, 5 +fp!,
	rfs,

' read-v >body @ is, read-epv

sub: loadseg-v
	1 +fp@, filnamptr !,
	2 +fp@, filnamlen !,
	loadseg
	segptr @, 3 +fp!,
	rsn @, 4 +fp!,
	rfs,

' loadseg-v >body @ is, loadseg-epv

sub: unloadseg-v
	1 +fp@, segptr !,
	unloadseg
	rfs,

' unloadseg-v >body @ is, unloadseg-epv

sub: exec-v
	1 +fp@, filnamptr !,
	2 +fp@, filnamlen !,
	3 +fp@, parambuf !,
	exec
	rsn @, 4 +fp!,
	rfs,

' exec-v >body @ is, exec-epv

sub: exit.-v
	exit.
	rfs,

' exit.-v >body @ is, exit.-epv

sub: compare-v
	1 +fp@, strptr1 !,
	2 +fp@, strlen1 !,
	3 +fp@, strptr2 !,
	4 +fp@, strlen2 !,
	compare
	strres @, 5 +fp!,
	rfs,

' compare-v >body @ is, compare-epv

sub: strdif-v
	1 +fp@, strptr1 !,
	2 +fp@, strptr2 !,
	strdif
	strres @, 3 +fp!,
	rfs,

' strdif-v >body @ is, strdif-epv

sub: movmem-v
	1 +fp@, strptr1 !,
	2 +fp@, strptr2 !,
	3 +fp@, strlen1 !,
	movmem
	rfs,

' movmem-v >body @ is, movmem-epv
