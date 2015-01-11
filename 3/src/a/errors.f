\ errors.f keeps track of errors accumulated during the assembly.
\ vim: set ts=8 sw=8 noet ai ft=forth:

16384 CONSTANT /errorbuf

1 CELLS CONSTANT /CELL
CREATE errorbuf		/errorbuf ALLOT
errorbuf /errorbuf + 1- CONSTANT bufend
VARIABLE errorp
VARIABLE lasterror

: 0errors ( -- )
	errorbuf errorp !  lasterror off ;

: invariant ( -- )
	errorp @ errorbuf U< ABORT" CRITICAL: Error buffer underrun"
	bufend errorp @ U< ABORT" CRITICAL: Error buffer overrun" ;

0errors invariant

: err-allot ( n -- )
	errorp +! invariant ;

: err, ( x -- )
	errorp @ !  /CELL err-allot ;

\ Errors sit in a linked list, and follow this overall structure:
\
\ +0	Link to previous error
\ +1	Assembler Pass (1 or 2, typically).
\ +2	Standard Error Message Emitter
\ +3...	(optional parameters)

: error ( xt n -- )
	errorp @ >R
		lasterror @ err, err, err,
	R> lasterror ! ;

: error/str ( xt n caddr u -- )
	2DUP errorp @ SWAP CMOVE  NIP errorp @  OVER err-allot
	>R >R error R> R> err, err, ;

: errors? ( -- f )
	lasterror @ 0= 0= ;

: .error ( e -- )
	." (P" DUP CELL+ @ S>D <# [CHAR] ) HOLD #S #> TYPE SPACE
	DUP CELL+ CELL+ @ EXECUTE
	CR ;

: .errors ( -- )
	lasterror @ BEGIN DUP WHILE DUP .error @ REPEAT DROP ;

\ Common Kinds of Errors

: cannot-open-file ( e -- )
	." Cannot open file "
	3 CELLS + DUP @ SWAP CELL+ @ TYPE ;

: syntax-error ( e -- )
	." Syntax error near "
	3 CELLS + DUP @ SWAP CELL+ @ TYPE ;

