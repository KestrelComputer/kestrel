\ Main entry point for the STS kernel starts here.
\ This must be a defer vector.
\ We revector to a word named "cold" below.

include errors.fs
include constants.fs

$0400 origin
defer, coldstart

\ Global state for all OS services.

:, halt,	again, ;,
:, crash	$C000 #, !,  $C000 #, @, -1 #, xor, $C050 #, !,  $AAAA #, $C0A0 #, !, ;,
:, 0=		if, 0 #, exit, then, -1 #, ;,

\ rsn stores the reason for a service's failure to deliver the expected results.
\ Numerous system calls can fail for a number of reasons.  See the errors.fs file
\ for a list of reasons and their most common circumstances.
int, rsn

\ fillRect draws very simple rectangular patterns on the screen.
\ This can be used to clear the screen, or to let the user in on the current progress of something.
\ This procedure does not return anything.

int, bitmapptr
int, wrdperrow
int, rowendres
int, rowperbox
int, bitmapdat
int, wrdctr		( internal )
int, rowctr		( internal )

:, fillrow
	wrdctr @,
	if,	bitmapdat @, bitmapptr @, !,
		bitmapptr @, 2 #, +, bitmapptr !,
		wrdctr @, -1 #, +, wrdctr !,
		again,
	then,
	rowendres @, bitmapptr @, +, bitmapptr !, ;,

:, fillrows
	rowctr @,
	if,	wrdperrow @, wrdctr !,
		fillrow
		rowctr @, -1 #, +, rowctr !,
		again,
	then, ;,

:, fillRect
	rowperbox @, rowctr !, fillrows  ;,


include SYS.findtag.fs
include SYS.getmem.fs
include SYS.sdcard.fs
include SYS.filesys.fs


\ First instruction of STS starts here.  coldstart vectors here.

:, cold		$4000 #, %fp !,			( Initialize the STS frame pointer )
		-8 fp+!,			( Let user know we're running )
			$C000 #, bitmapptr !,
			40 #, wrdperrow !,
			80 #, rowendres !,
			100 #, rowperbox !,
			$AAAA #, bitmapdat !,
			fillRect

			0 #, fndtagsta !,	( locate free memory pool and initialize it. )
			$3000 #, fndtagend !,
			findTag
			rsn @, if,		( If not found... )
				$C000 #, bitmapptr !,	( indicate error to user and halt )
				40 #, wrdperrow !,
				0 #, rowendres !,
				200 #, rowperbox !,
				$FFFF #, bitmapdat !,
				fillRect
				halt,
			then,
			fndtagsta @, mplsta !,
			fndtagsta @, -1 #, xor, 1 #, +, $4000 #, +, mplsiz !,
			fmtmem

			$C050 #, bitmapptr !,	( Memory pool initialized; time to mount the system filesystem. )
			40 #, wrdperrow !,
			80 #, rowendres !,
			100 #, rowperbox !,
			$5555 #, bitmapdat !,
			fillRect

			mount
			rsn @, if,
				$C000 #, bitmapptr !,
				40 #, wrdperrow !,
				0 #, rowendres !,
				200 #, rowperbox !,
				$8888 #, bitmapdat !,
				fillRect
				halt,
			then,

			$C000 #, bitmapptr !,	( filesystem mounted; time to load user interface/shell )
			40 #, wrdperrow !,
			80 #, rowendres !,
			100 #, rowperbox !,
			$FFFF #, bitmapdat !,
			fillRect
		8 fp+!,

		
		halt, ;,

\ Let the start of free memory begin here.
\ This tag structure is discovered dynamically at boot time.
\ It must be the very last piece of code actually compiled; otherwise, the dynamic memory manager will corrupt valid program code.

pibptr @ 3 + -4 and pibptr !  ( Ensure proper structure alignment for getmem's benefit )

create, memtag
	$C0DE ,, ' memtag >BODY @ ,, $DA7A ,, $C0DE $DA7A + ' memtag >BODY @ + $FFFF xor ,,

\ Patch up the coldstart vector.

' cold >BODY @ is, coldstart

\ Emit the $SYS file image.
pib 1024 + pib pibptr @ 1024 - move
-1024 pibptr +!
out" sys/$SYS"
bye
