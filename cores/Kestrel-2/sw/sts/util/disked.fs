: sector	dup 2/ block  swap  1 and 512 *  + ;

variable sec
variable ofs
variable wof
variable ptr
variable bstr
variable blen

: h.w		hex s>d <# # # # #> type space decimal ;
: .ofs		ofs @ h.w ;
: .||		." | " ;
: b		ptr @ ofs @ + c@  hex s>d <# # # #> type space decimal 1 ofs +! ;
: rationalize	dup 32 u< if drop [char] _ then ;
: a		ptr @ ofs @ + c@ rationalize emit 1 ofs +! ;
: ascii		-16 ofs +!  a a a a a a a a space a a a a a a a a ;
: row		.ofs .|| b b b b  b b b b space b b b b  b b b b .|| ascii cr ;
: 8rows		row row row row  row row row row ;
: 32rows	8rows 8rows 8rows 8rows ;
: 512bytes	ptr ! 0 ofs !  32rows ;
: .sector	sec ! page ." Sector: " sec ? cr cr sec @ sector 512bytes cr ." Next write at: " wof @ h.w cr ;

: at		wof !  sec @ .sector ;
: plop		sec @ sector wof @ + .s c! update  1 wof +! ;
: c		hex bstr @ 2 evaluate plop  2 bstr +!  -2 blen +! decimal ;
: stuff		begin blen @ while c repeat ;
: bytes		blen ! bstr !  stuff  sec @ .sector ;
: ascii		512 wof @ - min  dup >r sec @ sector wof @ + swap move  r> wof +! sec @ .sector ;
: n		1 sec +!  sec @ 65535 min sec !  sec @ .sector ;
: p		-1 sec +!  sec @ 0 max sec !  sec @ .sector ;

