defer, go

include INC.STS.SYS.fs

create, lib.textiface
	C", SYS:lib.textiface"

int, textifaceBase
include INC.textiface.fs

160 const, /cmdbuf
create, cmdbuf
	char S c,,	char Y c,,	char S c,,	char : c,,
	char p c,,	char r c,,	char g c,,	char . c,,
160 allot,

int, p
int, #cmdbuf
int, psch
int, pdch
int, n


:, stop
	$C000 #, p !,
	begin,	p @,
	while,	$FFFF #, p @, !,
		p @, 2 #, +, p !,
	repeat,
	4 +fp@, $C002 #, !,
	4 +fp@, -1 #, xor, $C052 #, !,
	$AAAA #, $C0A2 #, !,
	begin, again,
;,

:, cls
	0 #, 1 +fp!,  0 #, 2 +fp!,
	80 #, 3 +fp!,  25 #, 4 +fp!,
	BlackRect
;,

create, prompt$
	C", > "

create, banner$
	C", STS/K2 V1"

:, prompt
	prompt$ 1 #, +, 1 +fp!,
	prompt$ c@, 2 +fp!,
	PrintStr
;,

:, getcmd
	prompt 
	Accept
	1 +fp@, #cmdbuf !,
;,

:, skipws
	$FF00 #, psch !,
        begin,  psch @, -$FF00 #, +, $8000 #, and,
                if,     exit,
                then,
                
                psch @, -$FFA0 #, +, $8000 #, and, $8000 #, xor,
                if,     exit,
                then,
                
                psch @, c@, -33 #, +, $8000 #, and, $8000 #, xor,
                if,     exit,
                then,
                
                psch @, 1 #, +, psch !,
        again,
;,

:, copy2ws
	cmdbuf 4 #, +, pdch !,
        8 #, n !,
        begin,  psch @, -$FF00 #, +, $8000 #, and,
                if,     exit,
                then,
                
                psch @, -$FFA0 #, +, $8000 #, and, $8000 #, xor,
                if,     exit,
                then,
                
                n @, -52 #, +, $8000 #, and, $8000 #, xor,
                if,     exit,
                then,
                
		n @, #cmdbuf @, -1 #, xor, +, 1 #, +, $8000 #, and, $8000 #, xor,
		if,	exit,
		then,

                psch @, c@, -33 #, +, $8000 #, and,
                if,     exit,
                then,
                
                psch @, c@, pdch @, c!,

                psch @, 1 #, +, psch !,
                pdch @, 1 #, +, pdch !,
                n @, 1 #, +, n !,
        again,
;,

:, run
	cmdbuf 1 +fp!,
	n @, 2 +fp!,
	PrintStr CR
;,

:, try
	CR
	skipws copy2ws run
;,

:, banner
	banner$ 1 #, +, 1 +fp!,
	banner$ c@, 2 +fp!,
	PrintStr CR
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

	cls
	banner
	begin,	getcmd
		try
	again,
;,

' main >body @ is, go

reloc" imgs/prg.start"

