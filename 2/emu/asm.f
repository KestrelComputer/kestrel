: sfind         dup pad c!  pad 1+ swap move  pad find dup 0= if >r count r> then ;

16384 constant /image
create image
/image allot

: -small    dup 0< abort" Target address out of range." ;
: -big      dup /image >= abort" Target address out of range." ;
: -odd      dup 1 and abort" Attempt to access cell with an unaligned address." ;

: >host     -small -big -odd image + ;

: w@        dup c@ 8 lshift swap 1+ c@ 255 and or ;
: w!        over 8 rshift over c! 1+ c! ;
: t@        >host w@ ;
: t!        >host w! ;

variable        h
: open          S" romfile" r/w bin create-file throw h ! ;
: close         h @ close-file throw ;
: write         image 16384 h @ write-file throw ;
: romfile       open write close ." romfile created/updated." cr ;

variable cp

: org       cp ! ;

: there     cp @ ;

: tallot    cp +! ;
: ,,        there t!  2 tallot ;
2048 constant /buffer
create strs     /buffer allot

strs /buffer + constant strs)

variable sp

: invariant     sp @ strs u< abort" String pointer too small"
                sp @ strs) u< 0= abort" String pointer out of bounds" ;

: +fits         sp @ over + strs) u< 0= abort" String too big to intern" ;

: remembered    invariant +fits sp @ swap dup sp +! move invariant ;

/buffer cells constant /column
create names        /column allot
create lengths      /column allot
create addresses    /column allot
create immediacies  /column allot

variable >symtab
variable >visible
: 0symtab       0 >symtab !  0 >visible !  strs sp ! ;

: #syms         >symtab @ ;
: ofs           #syms cells ;
: +opening      ofs /column u< 0= abort" Too many symbols" ;

: l!            ofs lengths + ! ;
: n!            ofs names + ! ;

: a!            ofs addresses + ! ;

: i!            ofs immediacies + ! ;

: defined       +opening dup l! sp @ n! remembered there a! 0 i! 1 >symtab +! ;

: l@            lengths + @ ;
: n@            names + @ ;

: length        cells l@ ;
: name          cells dup n@ swap l@ ;
: definition    cells addresses + @ ;
: isImmediate?  cells immediacies + @ ;
: #visible      >visible @ ;
: isVisible?    #visible u< ;
: revealed      #syms >visible ! ;

: cell-         [ -1 cells ] literal + ;
: rows          2/ 2/ ;     ( MACHINE SPECIFIC )
: -end          dup 0 >= if exit then  drop r> drop ;
: differs?      >r 2dup r@ n@ r@ l@ compare r> swap ;
: -match        differs? if exit then  nip nip rows -1 2r> 2drop ;
: -exist        1- cells begin -end -match cell- again ;

: sfind,        #visible -exist 0 ;
: sfindAll,     #syms -exist 0 ;

: isDefined?    sfindAll, dup 0= if nip then nip ;

: token         32 word count ;
: ',            token sfind, 0= abort" Undefined" ;

: defer,        token defined revealed 0 ,, ;

: +even         dup 1 and abort" Odd address" ;
: +range        dup $4000 u< 0= abort" Address outside of range CPU can execute" ;
: +address      +even +range ;
: is,           definition +address 2/ ', definition t! ;
: (:)           token defined ;

variable bb ( true if inside a basic block )

: p,            ,, bb off ;  ( program flow appendage )
: i,            ,, bb on ; ( anything else appendage )

: return,       $700C p, ;

: +bb           bb @ if exit then return, r> drop ;

: +here>=2      there 2 u< if r> drop then ;

: pInsn         there 2 - t@ ;

: -call?        $E000 and $4000 xor ;

: tweak         there 2 - t! bb off ;

: >jmp          pInsn $4000 xor tweak ;

: -call         +here>=2 pInsn -call? if exit then >jmp r> drop ;

: -alu?         $F000 and $6000 xor ; ( check top 4 bits to verify r->PC bit is clear too )




: +r            pInsn $100C or tweak ;
: -alu          +here>=2 pInsn -alu? if exit then +r r> drop ;

: exit,         +bb -call -alu return, ;
: +even         dup 1 and abort" Odd address" ;
: +range        dup $4000 u< 0= abort" Attempt to call word outside of CPU executable space" ;
: +address      +even +range ;

: call,         +address 2/ $4000 or i, ;


variable xorMask
variable        nn

: invert,       $6600 i, ;
: bits14:0,     $8000 or i, ;

: +ve           dup $8000 and if invert bits14:0, invert, r> drop then ;

: lit,          +ve bits14:0, ;

: >bin          [char] 0 - dup 10 u< 0= 7 and - ;

: -eoi          dup 0= if 2drop 2drop r> drop then ;

: +dec          dup 0 10 within 0= if 2r> 2drop r> drop then ;
: accum         >bin +dec nn @ 10 * + nn ! ;

: declit        begin -eoi over c@ accum 1 /string again ;

: is0-9?        [char] 0 [char] 9 1+ within ;
: ?neg          xorMask @ xor  xorMask @ 1 and + ;
: -dec          over c@ is0-9? if declit nn @ ?neg ['] lit, 2r> 2drop then ;


: +hex          dup 0 16 within 0= if 2r> 2drop r> drop then ;




: ucase         dup [char] a [char] z 1+ within $20 and xor ;
: accum         ucase >bin +hex nn @ 16 * + nn ! ;

: hexlit        begin -eoi over c@ accum 1 /string again ;

: -hex          over c@ [char] $ = if 1 /string hexlit nn @ ['] lit, 2r> 2drop then ;



: -compiled     2dup sfind, if nip nip definition ['] call, r> drop exit then 2drop ;

: -immediate    2dup sfind if nip nip r> drop exit then 2drop ;

: neg?          over c@ [char] - = if -1 xorMask ! 1 /string then ;
: -number       0 nn ! 0 xorMask !  neg? 2dup -dec -hex 2drop ;

: classify      -compiled -immediate -number ." Error: " type -2 abort" Undefined" ;


: +eotib        >in @ source nip < if r> drop then ;
: +successful   0= abort" Unexpected end of input" ;
: ?refill       +eotib refill +successful ;

: ],            begin ?refill token classify execute again ;
: :,            (:) ], ;

: [,            r> r> drop >r ;  ( break out of the infinite loop set up by ] )
: (;)           exit, revealed ;

: ;,            [, (;) ;



: create,       (:) there 4 + lit, (;) ;
: if,           there $2000 p, ;
: then,         dup t@ there 2/ or swap t! bb off ;
: recurse,      #syms 1- definition call, ;
: drop,         $6103 i, ;
: +,            $6203 i, ;
: and,          $6303 i, ;
: or,           $6403 i, ;
: xor,          $6503 i, ;
: rshift,       $6903 i, ;
: lshift,       $6D03 i, ;
: nop,          $6000 i, ;
: dbg,          $6010 i, ;
: swap,         $6180 i, ;
: dup,          $6081 i, ;
: over,         $6181 i, ;
: nip,          swap, drop, ;
: >r,           $6147 i, ;
: r>,           $6B8D i, ;
: r@,           $6B81 i, ;

: !,            $6123 i, drop, ;
: @,            $6C00 i, ;
: align         there 1 and if 1 tallot then ;
: (S",)         there >r [char] " parse there >host swap dup >r dup tallot move align r> r> swap ;
: ahead,        there $0000 p, ;
: S",           ahead, (S",) >r >r then, r> r> swap lit, lit, ;
only forth definitions
vocabulary target-primitives

: target        only forth also target-primitives ;
: host          only forth ;

also target-primitives definitions previous
: allot         tallot ;

: ,             ,, ;

: '             ', ;
: [']           ', lit, ;

: >body         definition ;

: defer         defer, ;

: is            is, ;

: :             :, ;

: ]             ], ;

: ;             ;, ;

: [             [, ;

: invert        invert, ;


: exit          exit, ;

: create        create, ;
: if            if, ;

: then          then, ;

: recurse       recurse, ;
: +             +, ;
: -             invert, +, 1 lit, +, ;
: dup           dup, ;
: xor           xor, ;
: over          over, ;
: drop          drop, ;
: nop           nop, ;
: rshift        rshift, ;
: lshift        lshift, ;
: and           and, ;
: or            or, ;
: swap          swap, ;
: nip           nip, ;
: >r            >r, ;
: r>            r>, ;
: r@            r@, ;

: !             !, ;
: S"            S", ;

: 2dup          over, over, ;
: 2drop         drop, drop, ;
: variable      create, 0 ,, ;
: 2*            1 lshift ;
: 2/            1 rshift ;
host definitions
