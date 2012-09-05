program progmem
0 origin

defer, bootstrap

$1000 const, ledport

int, digits
int, ctr

:, dl		ctr @, -1 #, +, ctr !,  ctr @, if, again, then, ;,
:, delay		$2000 #, ctr !, dl ;,

:, an0		$1079 #, ( E ) ledport !, delay ;,
:, an1		$2039 #, ( C ) ledport !, delay ;,
:, an2		$4077 #, ( A ) ledport !, delay ;,
:, an3		$8071 #, ( F ) ledport !, delay ;,

:, main		an0 an1 an2 an3 again, ;,

' main >body @ is, bootstrap

cr even image
cr odd image

