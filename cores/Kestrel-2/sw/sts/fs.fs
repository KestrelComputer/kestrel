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

: locatefile	p @ scb_buffer + @ blkptr !
		16 sector !  17 dirnext !  devget
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
			dirnext @ sector !  devget
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

