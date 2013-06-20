\ Target Image (Probably best to factor out)

65536 CONSTANT /image
CREATE 'image	/image ALLOT

: T-C@ ( addr -- b )
  'image + C@ ;

: T-@ ( addr -- x )
  DUP 1+ T-C@ 8 LSHIFT SWAP T-C@ $FF AND OR ;

: T-C! ( b addr -- )
  'image + C! ;

: T-! ( x addr -- )
  OVER 8 RSHIFT OVER 1+ T-C!  T-C! ;

: T-CELLS ( n -- x )
  2* ;

: T-CELL+ ( x -- x' )
  2 + ;

: T-DUMP ( addr len -- )
  SWAP 'image + SWAP DUMP ;


\ Base Extensions

DECIMAL
: BINARY ( -- )
  2 BASE ! ;

\ Section Types
\ 
\ Sections each have a unique type associated with them.  We describe the
\ section types by a set of permissions, based on a bitmapped set of flags.
\ 
\    3 2 1 0
\ +-+-+-+-+-+
\   |I|R|W|X|
\ +-+-+-+-+-+
\    | | | |
\    | | | +-- 1: Section may contain CODE content.  0: Strictly data.
\    | | +---- 1: Writes may occur to this section.  0: Writes have no effect.
\    | +------ 1: Reads may occur from this section.  0: Undefined.
\    +-------- 1: Section contains initialized data.  0: Uninitialized data.
\ 
\ In the context of the cross-compiler standard proposed by Elizabeth Rather,
\ not all combinations of flags yield meaningful descriptions.

VARIABLE 'current-type

: SECTION-TYPE ( n -- )
  CREATE , DOES> @ 'current-type ! ;

BINARY
( IRWX )
  0110 SECTION-TYPE UDATA
  1101 SECTION-TYPE CDATA
  1110 SECTION-TYPE IDATA
DECIMAL

\ Section Support
\ 
\ Sections are described with the following descriptor:
\ 
\ +0 cells	H (dictionary pointer for this section; low <= H <= high bound)
\ +1		Low Bound
\ +2		Upper Bound
\ +3		Section type

VARIABLE 'section

: SECTION ( lo-addr hi-addr c" name" -- )
  CREATE OVER , SWAP , , 'current-type @ ,  DOES> 'section ! ;

: >=L ( addr -- addr )
  DUP 'section @ CELL+ @ U< ABORT" Address out of range" ;

: <=U ( addr -- addr )
  DUP 'section @ 2 CELLS + @ 1+ U< 0= ABORT" Address out of range" ;

: +bounds ( addr -- addr )
  >=L <=U ;

: S-ORG ( addr -- )
  +bounds 'section @ ! ;

: S-HERE ( -- addr )
  'section @ @ ;

: S-ALLOT ( n -- )
  S-HERE + S-ORG ;

: S-ALIGN ( -- )
  S-HERE  1 T-CELLS 1- +  -1 T-CELLS AND  S-ORG ;

: S-C, ( c -- )
  S-HERE T-C!  1 ( CHARS ) S-ALLOT ;

: S-, ( x -- )
  S-ALIGN  S-HERE T-!  1 T-CELLS S-ALLOT ;

\ Colon Definitions Within Current Section

VARIABLE CURRENT	\ definition in progress
VARIABLE LASTXT		\ in the current context

CURRENT OFF
LASTXT OFF

: name, ( -- addrName )
  S-HERE >R BL PARSE DUP >R DUP S-C, S-HERE 'image + SWAP MOVE R> S-ALLOT R> ;

: lfa, ( -- )
  LASTXT @ S-, ;

: nfa, ( addrName -- )
  S-, ;

: cfa, ( -- )
  0 S-, ;

: :header, ( addrName -- )
  S-HERE CURRENT !  cfa, nfa, lfa, ;

: S-UNSMUDGE ( -- )
  CURRENT @ LASTXT ! ;

: S-: ( "name" -- )
  >IN @ name, S-ALIGN :header, >IN ! CREATE S-HERE 6 - , DOES> @ S-, ;

: S-; ( -- )
  S-UNSMUDGE ;

\ Context Selection

: H-ORG ( addr -- )
  HERE - ALLOT ;

: H-: ( -- )
  : ;

: H-; ( -- )
  POSTPONE ; ;

: ;-H ( -- )
  H-; ; IMMEDIATE

: H-@ ( addr -- x )
  @ ;

: H-!  ( x addr -- )
  ! ;

: H-C@ ( addr -- c )
  C@ ;

: H-C! ( c addr -- )
  C! ;

: H-DUMP ( addr len -- )
  DUMP ;

CREATE 'host-ctx
  ' H-ORG ,
  ' HERE ,
  ' ALLOT ,
  ' ALIGN ,
  ' C, ,
  ' , ,
  ' H-@ ,
  ' H-! ,
  ' H-C@ ,
  ' H-C! ,
  ' H-DUMP ,
  ' : ,
  ' H-; ,

CREATE 'target-ctx
  ' S-ORG ,
  ' S-HERE ,
  ' S-ALLOT ,
  ' S-ALIGN ,
  ' S-C, ,
  ' S-, ,
  ' T-@ ,
  ' T-! ,
  ' T-C@ ,
  ' T-C! ,
  ' T-DUMP ,
  ' S-: ,
  ' S-; ,

VARIABLE 'context

: REDIRECT: ( n -- n' )
  CREATE DUP , CELL+  DOES> @ 'context @ + @ EXECUTE ;

0 REDIRECT: ORG
  REDIRECT: HERE
  REDIRECT: ALLOT
  REDIRECT: ALIGN
  REDIRECT: C,
  REDIRECT: ,
  REDIRECT: @
  REDIRECT: !
  REDIRECT: C@
  REDIRECT: C!
  REDIRECT: DUMP
  REDIRECT: :
  REDIRECT: ; IMMEDIATE
DROP


H-: HOST ( -- )
  'host-ctx 'context H-! ;-H

HOST  ( default to HOST context )

H-: TARGET ( -- )
  'target-ctx 'context H-! ;-H

