0 [if]  The J1 processor sports a 13-bit wide program counter, address-
        ing cells, not bytes.  Hence, the processor can only execute
        instructions from locations $0000 to $3FFE, inclusive.
[then]

16384 constant /image
create image
/image allot

0 [if]  When assembling/compiling, repeated references into target memory
        space will need to be made.  We want to ensure that we don't
        spill over into host memory when doing so.  Accessing any cell
        or byte not belonging to the target is strictly an error, and
        will result in immediate termination of the compiler.

        It should be noted that most contemporary Forth environments are
        32-bit or 64-bit, not 16-bit.  Thus, to better emulate how the
        J1 will be referencing memory, we would like to use @ and !, but
        constrained to 16-bits wide.  ANS Forth provides no such support,
        so we synthesize our own using C@ and C!, which we pray operate
        on 8-bit units of memory.

        To facilitate more seamless support for graphics, we define
        byte address A+0 to be displayed prior to A+1.  Since, to the
        human eye, A+0 appears to the left of A+1, we treat A+0 as
        bits 15..8 of a 16-bit quantity.  In other words, we define
        the J1 arbitrarily as big-endian.  This allows us to write
        graphics routines without byte-swapping all the time.
[then]

: -small    dup 0< abort" Address out of range" ;
: -big      dup /image >= abort" Address out of range" ;
: -odd      dup 1 and abort" Attempt to access cell with unaligned address" ;
: >host     -small -big image + ;
: w@        dup c@ 8 lshift swap 1+ c@ 255 and or ;
: w!        over 8 rshift over c! 1+ c! ;
: t@        -odd >host w@ ;
: t!        -odd >host w! ;

0 [if]  We mainain a compilation pointer, cp, to remember where our next
        word should be compiled to.  It will always point somewhere inside
        the target image.
[then]

variable cp
: org       cp ! ;
: there     cp @ ;

0 [if]  The act of compiling involves sequentially appending values to
        the binary image stored in the image buffer.  We define special
        setters to automate this process, so that we don't have to
        constantly reference there all the time.
[then]

: tallot    cp +! ;
: ,,        there t!  2 tallot ;

0 [if]  While compiling a word, we refer to other words.  To compile the
        instructions to realize the runtime semantics, we need to know the
        addresses of the referenced words.  Therefore, we need a database
        of name, address pairs.  This is the job of the symbol table.

        The symbol table consists of two aggregate components.  First, we
        have a chunk of storage space reserved for storing the names we
        encounter.  The bytes comprising the names are stored one after
        the other in this string buffer.
[then]

2048 constant /buffer
create strs     /buffer allot
strs /buffer + constant strs)
variable sp

: invariant     sp @ strs u< abort" String pointer too small"
                sp @ strs) u< 0= abort" String pointer out of bounds" ;
: +fits         sp @ over + strs) u< 0= abort" String too big to intern" ;
: remembered    invariant +fits sp @ swap dup sp +! move invariant ;

0 [if]  The second component refers to spans within the string buffer,
        plus any other data associations.  We keep our data arranged in
        a column-order relational table for convenience.
[then]

/buffer cells constant /column
create names        /column allot
create lengths      /column allot
create addresses    /column allot
create immediacies  /column allot
variable >symtab
variable >visible

: 0symtab       0 >symtab !  0 >visible !  strs sp ! ;

0 [if]  Creating a definition requires associating a name with some datum,
        specifically a definition's address.  However, because we cannot
        trust the calling program to keep its string memory around for the
        lifetime of the definition, we must copy it into a temporary lo-
        cation.  This creates the invariant that all pointers in the names
        column point into the strs buffer.

        When creating a new definition, we assume the immediacy flag is
        clear.  This preserves ANS Forth semantics.  Further, we assume
        the definition will equal the current compilation pointer.
[then]

: #syms         >symtab @ ;
: ofs           #syms cells ;
: +opening      ofs /column u< 0= abort" Too many symbols" ;
: l!            ofs lengths + ! ;
: n!            ofs names + ! ;
: a!            ofs addresses + ! ;
: i!            ofs immediacies + ! ;
: defined       +opening dup l! sp @ n! remembered there a! 0 i! 1 >symtab +! ;

\       Miscellanious attribute getters and setters.

: l@            lengths + @ ;
: n@            names + @ ;
: length        cells l@ ;
: name          cells dup n@ swap l@ ;
: definition    cells addresses + @ ;
: isImmediate?  cells immediacies + @ ;
: #visible      >visible @ ;
: isVisible?    #visible u< ;
: revealed      #syms >visible ! ;

0 [if]  We also need some mechanism to determine if a label is defined.  Forth
        actually doesn't use this functionality as such; rather, this word is
        used by the unit tests to ensure we're doing the right thing.

        Forth does use sfind, however, to determine the index into the symbol
        table corresponding to a given name.  This index is considered the
        "execution token" for the word.
[then]

: cell-         [ -1 cells ] literal + ;
: rows          2/ 2/ ;     ( MACHINE SPECIFIC )
: -end          dup 0 >= if exit then  drop r> drop ;
: differs?      >r 2dup r@ n@ r@ l@ compare r> swap ;
: -match        differs? if exit then  nip nip rows -1 2r> 2drop ;
: -exist        1- cells begin -end -match cell- again ;
: sfindAll,     #syms -exist 0 ;
: sfind,        #visible -exist 0 ;
: isDefined?    sfindAll, dup 0= if nip then nip ;

0 [if]  The first instruction executed by the J1 processor is going to be
        a JMP to the actual start-up code.  However, Forth doesn't work
        well compiling forward references.  To implement said forward
        reference, we use DEFER to compile a vectored word.  Thus, we can
        use DEFER to make our interrupt vector tables, like so:

            0 org
            defer   _reset
            ( ... )

            : reset         blah blah blah ;
            ' reset is _reset

            ( ... )
[then]

: token     32 word count ;
: defer,    token defined revealed 0 ,, ;
: ',        token sfind, 0= abort" Undefined" ;
: +even     dup 1 and abort" Odd address" ;
: +range    dup $4000 u< 0= abort" Address outside of range CPU can execute" ;
: +address  +even +range ;
: is,       definition +address 2/ ', definition t! ;

