variable devnameptr
variable devnamelen

: finddevname	0 devnamelen !
		begin	devnamelen @ filenamelen @ =
			if	ENAME reason ! exit
			then
			filenameptr @ devnamelen @ + c@ [char] : =
			if	filenameptr @ devnameptr !
				devnamelen @ 1+ filenameptr +!
				devnamelen @ 1+ negate filenamelen +!
				0 reason !
				exit
			then
			1 devnamelen +!
		again ;


variable lfstarts
variable lfends
variable dirends
variable dirnext

: f		lfstarts @ lfends @ or
		if	exit
		then
		blkptr @ c@ filenamelen @ xor
		if	64 blkptr +!  exit
		then
		blkptr @ dir_type + c@  1 xor
		if	64 blkptr +!  exit
		then
		blkptr @ 1+ filenamelen @  filenameptr @ filenamelen @ compare
		if	64 blkptr +!  exit
		then
		blkptr @ dirt1_starts + @ $FFFF and lfstarts !
		blkptr @ dirt1_ends + @ $FFFF and lfends !
		;

: rdsect	p @ scb_sector + @ sector ! devget ;

: locatefile	p @ scb_buffer + @ blkptr !
		16 p @ scb_sector + !  17 dirnext !  rdsect
		reason @
		if	exit
		then
		p @ scb_buffer + @ dirt1_ends + @ $FFFF and dirends !

		0 lfstarts !  0 lfends !
		begin	dirnext @ dirends @ 1+ U<=
		while	f f f f  f f f f
			lfstarts @
			if	0 reason !  exit
			then
			dirnext @ p @ scb_sector + !  rdsect
			reason @
			if	exit
			then
			1 dirnext +!
		repeat
		ENOTFOUND reason !
		;

: (open)	/scb 512 + reqsize !  getmem
		result @
		if	0 result !  exit
		then
		p @ /scb + p @ scb_buffer + !
		locatefile
		reason @
		if	relmem  0 result !  exit
		then

		lfstarts @ p @ scb_starts + !
		lfends @ p @ scb_ends + !
		p @ /scb +  p @ scb_buffer + !
		0 p @ scb_index + !

		lfstarts @ p @ scb_sector + @ xor
		if	lfstarts @ p @ scb_sector + !
			p @ scb_buffer + @  blkptr !
			rdsect
			reason @
			if	relmem 0 result ! exit
			then
		then
		p @ result !  0 reason ! ;

: Open		finddevname
		reason @
		if	0 result ! exit
		then
		devnamelen @ 0=
		if	0 result !  ENOTFOUND reason !  exit
		then
		filenamelen @ 0=
		if	0 result !  ENOTFOUND reason !  exit
		then
		devnameptr @ devnamelen @ S" SYS" compare
		if	0 result !  ENOTFOUND reason !  exit
		then
		0 result !  ENOTFOUND reason !
		(open) ;

: Read		cin @ scb_index + @  512 =
		if	cin @ scb_sector + @ cin @ scb_ends + @ xor
			if	1 cin @ scb_sector + +!
				cin @ scb_buffer + @ blkptr !
				rdsect
				reason @
				if	-1 cin @ scb_sector + +!  0 result !  exit
				then
				0 cin @ scb_index + !
				recurse  exit
			else	EEOF reason !  0 count !  exit
			then
		then

		cin @ scb_index + @  count @  +  512  min
		cin @ scb_index + @  -  count !

		cin @ scb_buffer + @   cin @ scb_index + @  +
		inbuf @
		count @
		move
		count @  cin @ scb_index + +!
		;

