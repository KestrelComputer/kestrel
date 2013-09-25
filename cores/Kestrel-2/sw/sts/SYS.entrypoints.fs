\ These entry points thunk from frame-based parameter passing rules to global-variable rules used internally.

sub: fndtag-epv
	1 fp+@, fndtagsta !,
	2 fp+@, fndtagend !,
	findtag
	fndtagsta @, 3 fp+!,
	rsn @, 4 fp+!,
	rfs,

sub: getmem-epv
	1 fp+@, memsiz !,
	getmem
	memptr @, 2 fp+!,
	rsn @, 3 fp+!,
	rfs,

sub: relmem-epv
	1 fp+@, memptr !,
	relmem
	rfs,

sub: open-epv
	1 fp+@, filnamptr !,
	2 fp+@, filnamlen !,
	open
	filscb @, 3 fp+!,
	rsn @, 4 fp+!,
	rfs,

sub: close-epv
	1 fp+@, filscb !,
	close
	rfs,

sub: read-epv
	1 fp+@, inpscb !,
	2 fp+@, inpbuf !,
	3 fp+@, inplen !,
	read
	inpcnt @, 4 fp+!,
	rsn @, 5 fp+!,
	rfs,

sub: loadseg-epv
	1 fp+@, filnamptr !,
	2 fp+@, filnamlen !,
	loadseg
	segptr @, 3 fp+!,
	rsn @, 4 fp+!,
	rfs,

sub: unloadseg-epv
	1 fp+@, segptr !,
	unloadseg
	rfs,

sub: exec-epv
	1 fp+@, filnamptr !,
	2 fp+@, filnamlen !,
	3 fp+@, parambuf !,
	exec
	rsn @, 4 fp+!,
	rfs,

sub: exit.-epv
	exit.
	rfs,

sub: compare-epv
	1 fp+@, strptr1 !,
	2 fp+@, strlen1 !,
	3 fp+@, strptr2 !,
	4 fp+@, strlen2 !,
	compare
	strres @, 5 fp+!,
	rfs,

sub: strdif-epv
	1 fp+@, strptr1 !,
	2 fp+@, strptr2 !,
	strdif
	strres @, 3 fp+!,
	rfs,

sub: movmem-epv
	1 fp+@, strptr1 !,
	2 fp+@, strptr2 !,
	3 fp+@, strlen1 !,
	memmov
	rfs,

