\ loadseg.fs
\ 
\ This code provides a means of loading executable program code into memory at an
\ undetermined address, and still have it work.  Relocation happens at load-time,
\ not at compile-, link-, or run-time.

variable kind
variable sz
variable seg
variable offset

: rdword	2 count !  Read
		count @ 2 xor if
			seg @
			if	seg @ p !  relmem
			then
			0 result !  EBASE reason !
			r> r> 2drop
		then  ;
: rdsz		sz inbuf !  rdword ;
: rdkind	kind inbuf !  rdword ;
: rdoffset	offset inbuf !  rdword ;
: (loadseg)	rdkind  kind @ T_HUNK xor if
			0 result ! EBASE reason ! exit
		then
		begin	kind @ T_END xor
		while	rdkind
			kind @ T_CODE =
			if	rdsz sz @ reqsize ! getmem
				result @
				if	0 result ! exit
				then
				p @ seg !  p @ inbuf !  sz @ count !  Read
				count @ sz @ xor
				if	relmem
					0 result ! EBASE reason ! exit
				then
			then
			kind @ T_RELOC =
			seg @ 0= and
			if	0 result !  EBASE reason ! exit
			then
			kind @ T_RELOC =
			seg @ and
			if	rdsz
				begin	sz @
				while	rdoffset
					\ This prototype assumes a 2-byte word on a 64-bit Forth machine.
					\ This gyration goes away when word size and machine integer size matches.
					\     offset @ seg @ + @  seg @ +  offset @ seg @ + !
					\ What follows is for demonstration purposes only.
					offset @ seg @ + @
					seg @ + $FFFF and
					offset @ seg @ +
					2dup c! 1+ swap 8 rshift swap c!
					-1 sz +!
				repeat
			then
		repeat
		seg @ result !  0 reason ! ;

: loadseg	0 kind ! 0 p ! 0 reqsize ! 0 seg !
		Open
		result @ 0= if exit then
		result @ cin !
		(loadseg)
		cin @ p !  Close ;

