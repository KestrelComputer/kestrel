0 origin
program progmem.ram00
defer, bootstrap

create, sda
  15 ,, 0 ,,

int, nslides
int, cslide
int, k

$B000 const, kqstat
$B002 const, kqdata

$69 const, kEnd
$6C const, kHome
$7A const, kPgDn
$7D const, kPgUp

:, slide	cslide @, $C00A #, !, ;,

:, next		cslide @, 1 #, +, nslides @, -1 #, xor, 1 #, +, +, $8000 #, and,
		if, 1 #, cslide @, +, cslide !, then, ;,
:, previous	cslide @, if, -1 #, cslide @, +, cslide !, then, ;,
:, first	0 #, cslide !, ;,
:, last		nslides @, -1 #, +, cslide !, ;,
:, end		k @, kEnd xor, if, ;, then, last slide ;,
:, home		k @, kHome xor, if, ;, then, first slide ;,
:, pgdn		k @, kPgDn xor, if, ;, then, next slide ;,
:, pgup		k @, kPgUp xor, if, ;, then, previous slide ;,
:, count	sda @, nslides !, ;,
:, pressed	kqdata c@, k !, kqdata c!, ;,
:, released	kqdata c@, $8000 #, xor, k !,  k @, $C052 #, !, kqdata c!, ;,
:, wait		kqstat c@, 1 #, and, if, again, then, ;,
:, event	kqdata c@, $F0 #, xor, if, pressed ;, then, kqdata c!, wait released ;,
:, key		wait kqdata c@, $E0 #, xor, if, event ;, then, kqdata c!, again, ;,
:, main		key  pgup pgdn home end again, ;,
:, boot		count first slide main ;,
' boot >body @ is, bootstrap

