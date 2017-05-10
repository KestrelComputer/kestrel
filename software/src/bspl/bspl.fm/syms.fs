\ This file implements a symbol table.
\ 
\ When we compile a new colon definition, we need to record its name and
\ associate it with a unique identifier for the CALL instruction.  The
\ operand of the CALL instruction will reference this identifier, allowing
\ us to produce the correct assembly language listing for a given Forth
\ definition.
\ 
\ This symbol table will also hold external references (e.g., "external"
\ definitions).  This will let us link to separately-compiled modules.
\ 
\ Once a symbol is defined, we will never forget it.  Only by resetting the
\ symbol table to its default state will we recycle storage.

\ The number of symbols.  This should exceed the number of symbols your
\ program actually uses.

1024 constant #syms

\ Each symbol needs a name, and that name has a corresponding length.
#syms cells constant /syms

create names
/syms allot

create lengths
/syms allot

\ This variable indexes where we will place the next symbol to be defined.
\ 0 <= index < #syms
variable index

\ We need a buffer in which to store names, since Forth string storage is
\ transient at best.

65536 constant /storage

create storage
/storage allot

\ This points into storage; it indicates where the next byte will go.
\ 0 <= stp < /storage
variable stp

: syms0		0 index ! 0 stp ! ;
syms0

\ The current definition symbol.  0 <= cur < #syms.
variable cur

\ Copy a name into the symbol table.  Simply listing it here is sufficient to
\ consider it "defined."  Note that we don't bother storing specific values
\ because this information will be handled by the assembler down-stream.
: addr		storage stp @ + ;
: remember	2dup addr swap move nip addr swap dup stp +! ;
: len!		index @ cells lengths + ! ;
: adr!		index @ cells names + ! ;
: define	remember len! adr! index @ dup cur ! index inc ;

\ We're supposed to record symbol names.  But, we can also be used to store
\ strings as well.  Just don't mix up your indices, OK?
: dictate	remember len! adr! index @ dup 1+ index ! ;

\ Given a symbol, retrieve the corresponding name.
: name		cells dup names + @ swap lengths + @ ;
