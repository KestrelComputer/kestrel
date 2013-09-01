\ test-getmem.fs
\ 
\ These routines provide a dynamic memory management facility, allowing
\ applications to request blocks of memory of a given size, and to release it
\ later if required.


include ../errors.fs


8192 constant /pool
create pool	/pool allot

\ Memory Request Block fields
variable p
variable reqsize
variable result
variable reason
variable poolbase

include ../getmem.fs

\ Memory pool metadata itself requires storage.
\ This prevents one from allocating the pool as a whole.

: 0=		if 0 exit then -1 ;
: 0pool		pool /pool $cc fill  pool p ! /pool reqsize ! fmtmem  pool poolbase ! ;

: s		0pool ;
: t100.1	s  /pool reqsize !  getmem  result @ 0= abort" t100.1" ;
: t100.2	s  0 poolbase !  /pool reqsize !  getmem  reason @ EBASE xor abort" t100.2" ;
: t100.3	s  pool poolbase !  /pool reqsize !  getmem  reason @ ESIZE xor abort" t100.3" ;

\ Allocating something smaller than the whole pool should
\ succeed, however.

: s		0pool ;
: t110.1	s  4000 reqsize !  getmem  result @ abort" t110.1" ;
: t110.2	s  4000 reqsize !  getmem  p @ pool /node + xor abort" t110.2" ;
: t110.3	s  4000 reqsize !  getmem getmem result @ abort" t110.3" ;
: t110.4	s  4000 reqsize !  getmem getmem 193 reqsize ! getmem result @ 0= abort" t110.4";

\ Allocating a block of memory twice should not yield the same pointer.

variable q
: s		pool p !  /pool reqsize !  fmtmem  pool poolbase !
		256 reqsize !  getmem  p @ q ! ;
: t120.1	s  256 reqsize !  getmem  result @ abort" t120.1" ;
: t120.2	s  256 reqsize !  getmem  p @ q @ xor 0= abort" t120.2" ;

\ If we allocate two blocks of 256 bytes, then free the first one,
\ allocating a 512-byte block should appear after the 2nd block,
\ not at the smaller hole.

variable r
: s		pool p !  /pool reqsize !  fmtmem  pool poolbase !
		256 reqsize !  getmem  result @ abort" t130-s1"  p @ q !
		getmem result @ abort" t130-s2"  p @ r !
		q @ p ! relmem result @ abort" t130-s3" ;

: t130.1	s  257 reqsize !  getmem  result @ abort" t130.1" ;
: t130.2 	s  257 reqsize !  getmem  p @ r @ u<= abort" t130.2" ;

\ If we allocate 5 blocks of 64 bytes each, then free the first four,
\ allocating a 256 byte block _should_ be possible through de-fragmentation.

variable u
variable v

: s		pool /pool $CC fill  pool p !  /pool reqsize !  fmtmem  pool poolbase !
		64 reqsize !
		  getmem result @ abort" t140-s1" p @ q !
		  getmem result @ abort" t140-s2" p @ r !
		  getmem result @ abort" t140-s3" p @ u !
		  getmem result @ abort" t140-s4" p @ v !
	  	  getmem result @ abort" t140-s5"
		q @ p ! relmem  r @ p ! relmem  u @ p ! relmem  v @ p ! relmem ;
: t140.1	s  256 reqsize !  getmem  result @ abort" t140.1" ;
: t140.2	s  256 reqsize !  getmem  p @  q @  xor abort" t140.2" ;

\ Allocate 8 bytes.  Release that block.  Re-allocate 8 bytes.
\ This should re-use the previously allocated block.
\ It should not corrupt the subsequent node in the memory list.
: s		pool /pool $CC fill  pool p !  /pool reqsize !  fmtmem  pool poolbase !
		8 reqsize !  getmem  p @ q !
		relmem
		8 reqsize !  getmem  p @ r ! ;

: t150.1	s  q @ r @ xor abort" t150.1" ;
: t150.2	s  pool @ cell+ @ /pool /node 3 * - xor abort" t150.2" ;
		( 3 * because 1 is for the 1st block's header, )
		( 1 is for the space consumed by the "8-byte" reservation, )
		( and 1 more for the split node's header. )


: t		." 100" cr t100.1 t100.2 t100.3
		." 110" cr t110.1 t110.2 t110.3 t110.4
		." 120" cr t120.1 t120.2 
		." 130" cr t130.1 t130.2 
		." 140" cr t140.1 t140.2 
		." 150" cr t150.1 t150.2 ;

\ t

