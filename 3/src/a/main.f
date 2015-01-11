\ Polaris V0.1 Assembler V0.1
\ vim: set ts=8 sw=8 noet ai:


VARIABLE filename
VARIABLE filename-length
VARIABLE h


: RDROP
	R> R> NIP >R ;

: can't ( -- )
	['] cannot-open-file 1 filename @ filename-length @ error/str ;

: opened ( -- )
	filename @ filename-length @ R/O OPEN-FILE IF can't RDROP EXIT THEN h ! ;

: closed ( -- )
	h @ CLOSE-FILE THROW ;

: size ( -- u )
	h @ FILE-SIZE THROW D>S ;

: assemble-file ( caddr u -- )
	2DUP filename-length ! filename !
	opened size . ." bytes" CR closed ;

: hello ( -- )
	." This is a, the Polaris Assembler, V0.1" CR ;

: arguments ( -- )
	." At least one argument needs to be specified." CR RDROP ;

: no-errors ( -- )
	errors? IF .errors RDROP THEN ;

: main ( -- )
	hello 0errors
	argc 3 < IF arguments THEN
	argc 2 DO I argv assemble-file LOOP
	no-errors
	;

