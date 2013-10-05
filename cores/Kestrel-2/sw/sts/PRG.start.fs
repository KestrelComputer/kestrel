defer, go

include INC.STS.SYS.fs

create, lib.textiface
	C", SYS:lib.textiface"

int, textifaceBase
include INC.textiface.fs

int, p

:, stop
	$C000 #, p !,
	begin,	p @,
	while,	$FFFF #, p @, !,
		p @, 2 #, +, p !,
	repeat,
	begin, again,
;,

:, main
	-8 fp+!,
	
	lib.textiface 1 #, +, 1 +fp!,
	lib.textiface c@, 2 +fp!,
	1 #, 0 #, !, 
	loadseg
	4 +fp@,
	if,	stop
	then,
	3 +fp@, textifaceBase !,

	0 #, 1 +fp!,
	0 #, 2 +fp!,
	80 #, 3 +fp!,
	25 #, 4 +fp!,
	BlackRect

	begin,	
	again,
;,

' main >body @ is, go

reloc" imgs/prg.start"

