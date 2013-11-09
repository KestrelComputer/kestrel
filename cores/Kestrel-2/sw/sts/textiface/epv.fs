sub: BlackRect-dsp
	1 +fp@, Left !,
	2 +fp@, Top !,
	3 +fp@, Right !,
	4 +fp@, Bottom !,
	BlackRect
	ErrFlag @, 5 +fp!,
	rfs,

' BlackRect-dsp >body @ is, BlackRect-epv

sub: CR-dsp
	.cr rfs,
' CR-dsp >body @ is, CR-epv

sub: PrintStr-dsp
	1 +fp@, strp !,
	2 +fp!, strl !,
	PrintStr
	rfs,
' PrintStr-dsp >body @ is, PrintStr-epv

sub: Accept-dsp
	Accept
	#ib @, 1 +fp!,
	rfs,
' Accept-dsp >body @ is, Accept-epv

