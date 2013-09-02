\ test-loadseg.fs
\ 
\ This code provides a means of loading executable program code into memory at an
\ undetermined address, and still have it work.  Relocation happens at load-time,
\ not at compile-, link-, or run-time.

include ../errors.fs

\ General purpose input variables
variable p
variable q

\ General purpose response fields
variable result
variable reason

\ DOS-related global state
variable filenameptr
variable filenamelen
variable cin
variable inbuf
variable count

\ Getmem-related state
variable reqsize
variable poolbase

\ Fake DOS API
variable dosvecs
: Open		dosvecs @ @ execute ;
: Read		dosvecs @ cell+ @ execute ;
: Close		dosvecs @ 2 cells + @ execute ;

include ../constants.fs

\ Real getmem interface
create pool  8192 allot
pool 8192 $cc fill
include ../getmem.fs
pool p !  8192 reqsize !  fmtmem
pool poolbase !

include ../loadseg.fs


\ Utilities
: stdfn		S" TEST:FILE" filenamelen ! filenameptr ! ;

\ Test state
variable #Opens
variable #Reads
variable #Closes
: 000		#Opens off  #Reads off  #Closes off ;

create testscb
	0 ,	\ scb_pointer -- pointer to next byte to read

create file_4
	$70 c, $03 c,				\ T_HUNK
	$71 c, $03 c,				\ T_CODE
	$08 c, $00 c,				\ size
	$41 c, $42 c, $43 c, $44 c,
	$45 c, $46 c, $47 c, $48 c,
	$72 c, $03 c,				\ T_END

create file_5
	$70 c, $03 c,				\ T_HUNK
	$73 c, $03 c,				\ T_RELOC
	$04 c, $00 c,				\ size = 4 entries
	$00 c, $00 c, $02 c, $00 c,
	$04 c, $00 c, $06 c, $00 c,
	$72 c, $03 c,				\ T_END

create file_6
	$70 c, $03 c,				\ T_HUNK
	$71 c, $03 c,				\ T_CODE
	$08 c, $00 c,				\ code size
	$00 c, $1E c,
	$00 c, $00 c,
	$00 c, $1E c,
	$04 c, $00 c,
	$73 c, $03 c,				\ T_RELOC
	$02 c, $00 c,				\ two entries (four bytes)
	$02 c, $00 c,
	$06 c, $00 c,
	$72 c, $03 c,				\ T_END

: notfound	0 result !  ENOTFOUND reason ! ;
: found		testscb result !  0 reason ! ;

: open_0	notfound ;
create 'api_0
	' open_0 ,
	0 ,
	0 ,
: api_0		000 'api_0 dosvecs ! ;

: open_1	1 #Opens +! notfound ;
: read_1	1 #Reads +! ;
: close_1	1 #Closes +! ;
create 'api_1
	' open_1 ,
	' read_1 ,
	' close_1 ,
: api_1		000  'api_1 dosvecs ! ;

: open_2	found ;
: read_2	1 #Reads +!  0 inbuf @ ! ;
create 'api_2
	' open_2 ,
	' read_2 ,
	' close_1 ,
: api_2		000  'api_2 dosvecs ! ;

: open_3	found ;
: read_3	1 #Reads +!  1 count ! ;
create 'api_3
	' open_3 ,
	' read_3 ,
	' close_1 ,
: api_3		000  'api_3 dosvecs ! ;

: open_4	found ;
variable cnt
: read_4	1 #Reads +!  count @ cnt !  begin cnt @ while  cin @ @ c@  inbuf @ c!  1 inbuf +!  1 cin @ +!  -1 cnt +!  repeat  ;
create 'api_4
	' open_4 ,
	' read_4 ,
	' close_1 ,
: api_4		000 'api_4 dosvecs ! ;

\ Attempting to load a file that doesn't exist must produce a suitable error.
: s		stdfn  -1 result !  -1 reason ! api_0 ;
: t100.1	s  loadseg  result @ abort" t100.1" ;
: t100.2	s  loadseg  reason @ ENOTFOUND xor abort" t100.2" ;

\ When loading a file, it should attempt to open it to see if it exists at all.
\ If not found, Open should set the reason/result fields, and no attempts to read
\ from the file should exist.
: s		stdfn api_1 ;
: t110.1	s  loadseg  #Opens @ 1 xor abort" t110.1" ;
: t110.2	s  loadseg  #Reads @ abort" t110.2" ;

\ Assuming that a file exists, it should attempt to read at least the initial header from the file to make sure it's actually an executable file.
\ If it's an invalid header, it should close the file and return no segment.
: s		stdfn api_2 ;
: t120.1	s  loadseg  #Reads @ 1 xor abort" t120.1" ;
: t120.2	s  loadseg  #Closes @ 1 xor abort" t120.2" ;
: t120.3	s  loadseg  result @ abort" t120.3" ;
: t120.4	s  loadseg  reason @ EBASE xor abort" t120.4" ;

\ If Read returns fewer than a word's worth of data when reading a header, the file is corrupt.
\ Make sure the file is closed as well.
: s		stdfn api_3 ;
: t130.1	s  loadseg  #Reads @ 1 xor abort" t130.1" ;
: t130.2	s  loadseg  result @ abort" t130.2" ;
: t130.3	s  loadseg  reason @ EBASE xor abort" t130.3" ;
: t130.4	s  loadseg  #Closes @ 1 xor abort" t130.4" ;

\ If given a valid segment file to read with a code section, we should get back a pointer to a segment.
: s		stdfn api_4 file_4 testscb ! ;
: t140.1	s  loadseg  #Reads @ 0= abort" t140.1" ;
: t140.2	s  loadseg  result @ 0= abort" t140.2" ;
: t140.3	s  loadseg  reason @ abort" t140.3" ;
: t140.4	s  loadseg  result @ @ $4847464544434241 xor abort" t140.4" ;

\ If given a valid segment file with a relocation record before a code record, it's an error.
: s		stdfn api_4 file_5 testscb ! ;
: t150.1	s  loadseg  result @ abort" t150.1" ;
: t150.2	s  loadseg  reason @ EBASE xor abort" t150.2" ;

\ If given a code then a relocation chunk in a valid file, we should see it loaded, and with relocations applied relative to the chunk's place in memory.
: s		stdfn api_4 file_6 testscb ! ;
: t160.1	s  loadseg  result @ 0= abort" t160.1" ;
: t160.2	s  loadseg  result @ @ $FFFF and $1E00 xor abort" t160.2" ;
: t160.3	s  loadseg  result @ 2 + @ $FFFF and result @ $FFFF and xor abort" t160.3" ;
: t160.4	s  loadseg  result @ 4 + @ $FFFF and $1E00 xor abort" t160.4" ;
: t160.5	s  loadseg  result @ 6 + @ $FFFF and result @ 4 + $FFFF and xor abort" t160.5" ;

: t		t100.1 t100.2 
		t110.1 t110.2
		t120.1 t120.2 t120.3 t120.4
		t130.1 t130.2 t130.3 t130.4
		t140.1 t140.2 t140.3 t140.4
		t150.1 t150.2
		t160.1 t160.2 t160.3 t160.4 t160.5
		;

