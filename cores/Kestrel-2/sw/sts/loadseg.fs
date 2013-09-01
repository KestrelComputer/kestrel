\ loadseg.fs
\ 
\ This code provides a means of loading executable program code into memory at an
\ undetermined address, and still have it work.  Relocation happens at load-time,
\ not at compile-, link-, or run-time.

variable kind
variable sz
variable seg

: rdsz		sz inbuf !  2 count !  Read
		count @ 2 xor if
			p @ if relmem then
			Close  0 result !  EBASE reason !  r> drop
		then  ;

: rdkind	kind inbuf !  2 count !  Read
		count @ 2 xor if
			p @ if relmem then
			Close  0 result !  EBASE reason !  r> drop
		then  ;

: loadseg	0 kind !   0 p !  0 reqsize !

		Open
		result @ 0= if exit then
		result @ cin !

		rdkind
		kind @ T_HUNK xor if
			Close  0 result !  EBASE reason !  exit
		then

		begin	kind @ T_END xor
		while	rdkind
			kind @ T_CODE = if
				rdsz
				sz @ reqsize !  getmem
				result @ if
					0 result ! exit
				then
				p @ seg !
				p @ inbuf !
				sz @ count !  Read
				count @ sz @ xor if
					relmem
					Close  0 result !  EBASE reason ! exit
				then
			then
		repeat
		seg @ result !  0 reason !
;

