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


: Open		finddevname
		reason @
		if	0 result ! exit
		then
		0 result !  ENOTFOUND reason ! ;


