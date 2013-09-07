\ fs.fs - Filing System
\ 
\ This code provides the STS filing system, known as FS5, as it's the fifth storage layout I've come up with.
\ FS5 is not expected to remain in service long; it just needs to be enough to bootstrap a useful STS system.
\ 
\ Sector(s)	Purpose
\   0-1		Initial Program Loader
\   2-15	STS kernel
\   16-N	(16 <= N < M) The volume directory.
\   N+1-M	File storage
\ 
\ Assuming a sector consists of 512 bytes, a volume directory should never occupy more than 12.5% of available
\ storage space.  This figure is arrived using worst-case capacity planning: worst-case, every available sector
\ is used to storage a single file.  Thus, one directory entry (64 bytes) must exist per sector on the medium.
\ As 64 bytes is 1/8th the size (a factor of 0.125) of a sector, that explains the worst-case of 12.5% size.
\ In practice, you probably can get away with a smaller directory allocation.
\ 
\ Directory entries are laid out like so:
\ 
\ Byte(s)	Purpose
\   0		Length of filename (0 < n < 48)
\   1-47	Filename bytes.  Unused values set to $00.
\   48		Directory entry type.
\   49-63	"Book Keeping Area."  Depends on directory entry type.
\ 
\ Type		Description
\   0		Empty directory entry, suitable for (re)use.
\   1		File.
\   2		Volume Label.
\ 
\ Type-0 Book Keeping Area:
\   Ignored on read.  Always write as $00 bytes for future compatibility.
\ 
\ Type-1 Book Keeping Area:
\   Byte 49 unused.  Ignore on read, write as $00 for future compatibility.
\   Bytes 50-51 indicate the starting block of the file's data.
\   Bytes 52-53 indicate the last block of the file's data.  This field may equal the starting field if a file has only one block.
\   Bytes 54-63 are unused.  Ignore on read, write as $00 for future compatibility.
\ 
\ Type-2 Book Keeping Area:
\   Bytes 49-63 used to tell one volume from another given that they have equal names.  This blob is assigned during formatting or
\      disk copying, and for STS' purposes, is to be treated as an opaque blob with no particular format.
\ 
\ Space on the disk not explicitly delimited by a type-1 directory entry is considered freely available space.
\ Since the IPL, kernel, and directories are reserved areas, it follows they need special directory entries to describe them.
\ 
\ The directory is always described by the first entry of the first directory sector.  It always has a filename of "$DIR".
\ Its starting block must be 16.  Its ending block can be as large as 8208 for the largest volume supported by FS5
\ (32MB with 512-byte sectors).
\ 
\ The IPL and kernel can either be described by a single file, or by two separate files.  This is determined by the specific
\ formatting tool used.  If the volume is NOT bootable, then sectors 0 through 15 may be made available for data file storage.
\ No particular naming convention exists for bootstrap-specific files.  If described by a single file, $IPL is recommended.
\ Otherwise, use $IPL for sectors 0-1, and $SYS for the STS kernel allotment at sectors 2-15.
\ 
\ Finally, every volume must have a volume label record in the first directory block.
\ 
\ Data Structures
\   Stream Control Block (SCB)
\ 
\ API
\   Close
\      p @ == SCB of the file to close
\ 
\   Open
\      filenameptr @ == address of filename to open
\      filenamelen @ == length of filename to open
\      If successful, result @ == SCB of opened file.
\      Otherwise, result @ == 0 and reason @ indicates why.
\ 
\      Presently, filenames always conform to the syntax "SYS:name", where SYS: is a required prefix for all filenames.
\      A future version of this handler will support files on multiple volumes by specifying the device or volume name
\      directly in front of the colon.
\ 
\   Read
\      count @ == length of data to read
\      inbuf @ == pointer to buffer to receive the data read.  Must be at least count @ bytes in size.
\      cin @ == SCB of the current input stream.
\      If successful, count @ indicates how much data was actually read, and reason @ == 0.
\      Otherwise, count @ indicates how much was actually read (usually 0), and reason @ indicates why.

\ OPEN

variable blkptr
variable filenamelen
variable filenameptr
variable p
variable poolbase
variable reason
variable reqsize
variable result
variable sector

variable #devgets
variable lastsectread
: devget	1 #devgets +!  sector @ lastsectread !  0 reason ! 
		sector @ 2/ block sector @ 1 and 512 * +  blkptr @  512 move ;

include ../errors.fs
include ../constants.fs
include ../getmem.fs

8192 constant /pool
create pool	/pool allot
pool p !  /pool reqsize !  fmtmem
pool poolbase !

variable xxx

include ../fs.fs

: 000		0 #devgets !  pool p !  /pool reqsize !  fmtmem  ;

: s		S" foo" filenamelen ! filenameptr ! 000 ;
: t100.1	s  Open  result @ abort" t100.1" ;
: t100.2	s  Open  reason @ ENAME xor abort" t100.2" ;
: t100.3	s  Open  #devgets @ abort" t100.3" ;

: s		S" :foo" filenamelen !  filenameptr ! 000 ;
: t110.1	s  Open  result @ abort" t110.1" ;
: t110.2	s  Open  reason @ ENOTFOUND xor abort" t110.2" ;
: t110.3	s  Open  #devgets @ abort" t110.3" ;

: s		S" bar:" filenamelen !  filenameptr ! 000 ;
: t120.1	s  Open  result @ abort" t120.1" ;
: t120.2	s  Open  reason @ ENOTFOUND xor abort" t120.2" ;
: t120.3	s  Open  #devgets @ abort" t120.3" ;

: s		S" bar:foo" filenamelen !  filenameptr ! 000 ;
: t130.1	s  Open  result @ abort" t130.1" ;
: t130.2	s  Open  reason @ ENOTFOUND xor abort" t130.2" ;
: t130.3	s  Open  #devgets @ abort" t130.3" ;

: s		S" SYS:$DIR" filenamelen !  filenameptr !  S" blkf.open.happy" open-blocks  000 ;
: t140.1	s  Open  result @ 0= abort" t140.1" ;
: t140.2	s  Open  #devgets @ 1 xor abort" t140.2" ;
: t140.3	s  Open  lastsectread @ 16 xor abort" t140.3" ;
: t140.4	s  Open  result @ scb_starts + @ 16 xor abort" t140.4" ;
: t140.5	s  Open  result @ scb_ends + @ 18 xor abort" t140.5" ;
: t140.6	s  Open  result @ scb_buffer + @ 0= abort" t140.6" ;
: t140.7	s  Open  reason @ abort" t140.7" ;

: s		S" SYS:file.missing" filenamelen !  filenameptr !  S" blkf.open.happy" open-blocks  000 ;
: t150.1	s  Open  result @ abort" t150.1" ;
: t150.2	s  Open  reason @ ENOTFOUND xor abort" t150.2" ;

: s		S" SYS:$DIR" filenamelen !  filenameptr !  S" blkf.open.happy" open-blocks  000  /pool 256 - reqsize ! getmem ;
: t160.1	s  Open  result @ abort" t160.1" ;
: t160.2	s  Open  reason @ ESIZE xor abort" t160.2" ;

: s		S" SYS:file.present" filenamelen !  filenameptr !  S" blkf.open.happy" open-blocks  000 ;
: t170.1	s  Open  result @ 0= abort" t170.1" ;
: t170.2	s  Open  reason @ abort" t170.2" ;
: t170.3	s  Open  result @ scb_starts + @  $BEEF xor abort" t170.3" ;
: t170.4	s  Open  result @ scb_ends + @  $FACE xor abort" t170.4" ;

: t		t100.1 t100.2 t110.1 t110.2 t120.1 t120.2 t130.1 t130.2 
		t100.3 t110.3 t120.3 t130.3
		t140.1 t140.2 t140.3 t140.4 t140.5 t140.6 t140.7
		t150.1 t150.2
		t160.1 t160.2
		t170.1 t170.2 t170.3 t170.4
		;

