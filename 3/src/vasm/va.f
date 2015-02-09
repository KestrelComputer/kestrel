\ Sometimes convenient.
DECIMAL
: BINARY		2 BASE ! ;

\ The image buffer is where the assembler assembles its bytes.	The /image
\ (pronounced "per-image") constant configures how large of a buffer it is.

65536 CONSTANT /image
CREATE image
/image ALLOT

\ lc0 contains the origin of the program.  Generally, you shouldn't have to
\ care about the origin.  The RISC-V instruction set is fully
\ position-independent for both data and code.	But, sometimes, if you want to
\ perform address arithmetic on absolute addresses, setting the origin may
\ prove useful.
\ 
\ gp0 contains the address that the assembler thinks the global pointer
\ register points to.  Use the ASSUME-GP directive to set this value.
\ 
\ The bc variable contains the offset into the above image buffer where the
\ assembler should place the next byte.

VARIABLE lc0
VARIABLE gp0
VARIABLE bc

: ORG ( n -- )		lc0 ! ;
: LC ( -- n )		lc0 @ bc @ + ;
: RESET ( -- )		lc0 OFF  gp0 OFF  bc OFF ;
RESET
image /image $CC FILL
: ASSUME-GP ( -- )	LC gp0 ! ;

\ Check to make sure enough room exists in the image to assemble the desired
\ number of bytes.
: room ( n -- )		bc @ + /image U> ABORT" Image overflow" ;

\ Advance an offset or address by one RISC-V "word" (32-bit quantity).
	\ CAREFUL!!
	\ These assume we're running on a little-endian, 32-bit Forth host.
: WORD+			CELL+ ;

\ Accessors for the raw image.  Use like @ and !, but instead of an address,
\ pass an image-relative offset.
	\ CAREFUL!!
	\ These assume we're running on a little-endian, 32-bit Forth host.
: im>abs		image + ;
: IB! ( c bo -- )	im>abs C! ;
: IH! ( h bo -- )	2DUP IB! 1+ SWAP 8 RSHIFT SWAP IB! ;
: IW! ( w bo -- )	im>abs ! ;
: ID! ( d bo -- )	>R SWAP R> im>abs 2! ;
: IB@ ( bo -- c )	im>abs C@ ;
: IH@ ( bo -- h )	DUP IB@ SWAP 1+ IB@ 8 LSHIFT OR ;
: IW@ ( bo -- w )	im>abs @ ;
: ID@ ( bo -- d )	im>abs 2@ SWAP ;

\ B, H, W, and D, place a byte, half-word, word, or double-word (8, 16, 32,
\ or 64 bit, respectively) values verbatim into the image buffer.
\ 
\ Note that double-word values are awkward to use with 32-bit Forth systems,
\ requiring double-sized values on the data stack.  E.g.,
\ $DEADBEEF.0BADC0DE D, versus $DEADBEEF0BADC0DE for a proper 64-bit system.
\ 
\ Observe that the RISC-V architecture is a LITTLE-ENDIAN instruction set
\ architecture.

: (b,) ( c -- )		bc @ IB!  1 bc +! ;
: B, ( c -- )		1 room (b,) ;

HEX
: hwcomponents ( n -- h l )
	DUP 0FF00 AND 8 RSHIFT SWAP 0FF AND ;

: wcomponents ( n -- h l )
	DUP 0FFFF0000 AND 10 RSHIFT SWAP 0FFFF AND ;

: dwcomponents ( d -- h l ) \ Assumes 32-bit Forth
	SWAP ;
DECIMAL

: (h,) ( n -- )		hwcomponents (b,) (b,) ;
: H, ( n -- )		2 room (h,) ;

: (w,) ( n -- )		wcomponents (h,) (h,) ;
: W, ( n -- )		4 room (w,) ;

: (d,) ( d -- )		dwcomponents (w,) (w,) ;
: D, ( d -- )		8 room (d,) ;

\ ALIGN helps establish alignment in a program.  The argument can be any power
\ of two, up to and including the size of the image buffer.  Non-power-of-two
\ values will leave the buffer counter variable in a weird location.

: ALIGN ( n -- )	DUP 1- bc @ + SWAP NEGATE AND bc ! ;

\ Supporting a RISC architecture, the RISC-V instruction set architecture
\ attempts to minimize hardware required for instruction decoding by placing
\ often used fields at standard locations in an instruction.  These words
\ are used to fill those standard locations.

: (rs1)			SWAP 31 AND 15 LSHIFT OR ;
: (rs2)			SWAP 31 AND 20 LSHIFT OR ;
: (imm12)		SWAP 4095 AND 20 LSHIFT OR ;
: (rd)			SWAP 7 LSHIFT OR ;

\ Rearrange the bits in displacement 'n' to follow the UJ instruction format
\ rules.  Accumulate the results into the provided accumulator value.
\ To just convert a raw binary value, set accum to 0.  Typically, accum will
\ be a blank instruction encoding template.
: S>UJ ( displacement accum -- accum' )
	OVER $100000 AND 11 LSHIFT OR
	OVER $0007FE AND 20 LSHIFT OR
	OVER $000800 AND 9 LSHIFT OR
	SWAP $0FF000 AND OR ;

\ Rearrange the bits in a UJ-formatted instruction back to their intended
\ positions in a sign-extended displacement.  For proper operation, set accum
\ to zero.
: UJ>S ( n 0 -- displacement )
	OVER $7FE00000 AND 20 RSHIFT OR
	OVER $00100000 AND 9 RSHIFT OR
	OVER $000FF000 AND OR
	OVER $80000000 AND 11 RSHIFT OR
	NIP DUP $00100000 AND NEGATE OR ;

\ As with S>UJ, but for Bxx conditional branches.
: S>SB ( displacement 0 -- n )
	OVER $01E AND 7 LSHIFT OR
	OVER $800 AND 4 RSHIFT OR
	OVER $7E0 AND 20 LSHIFT OR
	SWAP $1000 AND 19 LSHIFT OR ;

\ As with UJ>S, but for Bxx conditional branches.
: SB>S ( n 0 -- displacement )
	OVER 7 RSHIFT $01E AND OR
	OVER 4 LSHIFT $800 AND OR
	OVER 20 RSHIFT $7E0 AND OR
	SWAP 19 RSHIFT $1000 AND OR
	DUP $1000 AND NEGATE OR ;

\ As with S>UJ, but for load instructions.
: S>LD ( displacement 0 -- n )
	SWAP $FFF AND 20 LSHIFT OR ;

\ As with UJ>S, but for load instructions.
: LD>S ( n 0 -- displacement )
	SWAP 20 RSHIFT $FFF AND OR
	DUP $800 AND NEGATE OR ;

\ As with S>UJ, but for store instructions.
: S>ST ( displacement 0 -- n )
	OVER $01F AND 7 LSHIFT OR
	SWAP $FE0 AND 20 LSHIFT OR ;

\ As with UJ>S, but for store instructions.
: ST>S ( n 0 -- displacement )
	OVER 7 RSHIFT $01F AND OR
	SWAP 20 RSHIFT $FE0 AND OR
	DUP $800 AND NEGATE OR ;

\ Recover the displacement from a UJ-format instruction in image memory.
: UJ@ ( addr -- displacement )
	IW@ 0 UJ>S ;

\ Set a new displacement for an already assembled UJ-format instruction in
\ image memory.
: UJ! ( displacement addr -- )
	>R 0 S>UJ R@ IW@ $FFF AND OR R> IW! ;

\ As with UJ@, but for Bxx conditional branch instructions.
: SB@ ( addr -- displacement )
	IW@ 0 SB>S ;

\ As with UJ!, but for Bxx conditional branch instructions.
: SB! ( displacement addr -- )
	>R 0 S>SB R@ IW@ $01FFF07F AND OR R> IW! ;

\ As with UJ@, but for loads and other I-format instructions.
: LD@ ( addr -- displacement )
	IW@ 0 LD>S ;

\ As with UJ!, but for loads and other I-format instructions.
: LD! ( displacement addr -- )
	>R 0 S>LD R@ IW@ $000FFFFF AND OR R> IW! ;

\ As with UJ@, but for loads and other S-format instructions.
: ST@ ( addr -- displacement )
	IW@ 0 ST>S ;

\ As with UJ!, but for loads and other S-format instructions.
: ST! ( displacement addr -- )
	>R 0 S>ST R@ IW@ $01FFF07F AND OR R> IW! ;

\ R, I, S, SB, U, and UJ, function like B, H, W, and D, above.  However, they
\ place actual CPU instructions, and as such take additional parameters.
\ Note that I, S, SB, U, and UJ, all take an immediate operand of some kind;
\ however, each encodes its immediate value in a unique manner.  For example,
\ U, records bits 12 through 31 of an immediate value, while UJ, records
\ (in the same space) bits 1 through 21.

: R, ( rs1 rs2 rd opmask -- )
	4 ALIGN (rd) (rs2) (rs1) W, ;

	\ Immediate instructions are also employed by the various load
	\ instructions as well.
: I, ( rs1 imm rd opmask -- )
	4 ALIGN (rd) (imm12) (rs1) W, ;

	\ Note that we swap the two source registers for store instructions.
	\ This is for the benefit of human beings trying to code in assembly
	\ language directly.  The RISC-V ISA says that the store instructions
	\ take data from rs2 and store them into address rs1+imm.  Swapping the
	\ registers minimizes surprises for the human coder, as it preserves 
	\ the convention that the destination of an instruction is closest to
	\ the instruction.
: S, ( rs2 rs1 imm opmask -- )
	4 ALIGN
	OVER 31 AND 7 LSHIFT OR
	SWAP 5 RSHIFT 25 LSHIFT OR
	(rs1) (rs2) W, ;

: SB, ( rs1 rs2 addr opmask -- )
	4 ALIGN
	>R LC WORD+ - R> S>SB (rs2) (rs1) W, ;

: U, ( imm rd opmask -- )
	4 ALIGN (rd) SWAP $FFFFF000 AND OR W, ;

: UJ, ( addr rd opmask -- )
	4 ALIGN (rd)
	>R LC WORD+ - R> S>UJ W, ;

\ Label Management.  Words of the form X> construct relocation records for
\ as-yet-undefined symbols.  The different forms of relocation records exist
\ because the RISC-V ISA contains different instruction operand encodings.
\ 
\ Attempting to use a symbol before it's defined, as if it were defined,
\ will produce an error.  In addition, attempting to shadow an existing Forth
\ definition will also cause an error.
\ 
\ Symbol words contain a list header structure with two fields:
\ 
\ +0 cells	Execution token to invoke when the word executes.
\		By default, this points to fwd, which provides the user with an
\		error message about using the label without defining it first.
\ 
\		When the label definition happens, this field will change to
\		point to the val routine, which implements VALUE-like
\		semantics.
\ 
\ +1 cells	For as-yet undefined symbols, this field points to the most
\		recently created relocation record.  For defined symbols, it
\		contains the symbol's actual value.
\ 
\ Each relocation record, then, contains four fields on its own:
\ 
\ +0 cells	Link to previously created relocation record.  The oldest
\		relocation record will have zero in this field.
\ 
\ +1		Execution token to a fixup routine.  This code executes when
\		the symbol finally is defined by the programmer.  The handler
\		is supposed to fix up, however it sees fit, a single RISC-V
\		instruction.  Currently, the symbol's value is taken to be the
\		current value of the location counter (LC).
\ 
\ +2		Buffer counter of the RISC-V instruction to fix up.
\		To calculate the location counter, just add the value of the
\		lc0 variable.
\ 
\ +3		The current global pointer address, as understood by the
\		assembler.  The user is free to choose any register she wants
\		for the global pointer, but the assembler needs to know what
\		the address is for GP-relative offset calculations.
\ 
\ Without any doubt, this is *the* single, most complex piece of code in this
\ assembler.

	\ This is executed whenever a forward-definition word is invoked
	\ without a corresponding constructor in front of it.
: fwd ( a -- )
	DROP -1 ABORT" Forward reference used without definition" ;

	\ Value accessor for defined symbols.
: val ( a -- n )
	CELL+ @ ;

	\ This word is invoked during symbol definition to resolve forward
	\ references.
	\ 
	\ It provides a 32-bit absolute relocation.
: fixup-abs32 ( a -- )
	2 CELLS + @ DUP IW@ LC + SWAP IW! ;

	\ This word is invoked during symbol definition to resolve forward
	\ references.
	\ 
	\ It provides a 64-bit absolute relocation.
	\ 
	\ NOTE: Because the image address space is constrained to less than 32
	\ bits on a 32-bit Forth environment, it follows that any 64-bit
	\ relocation will only affect the lower 32-bits of the value.  This is
	\ technically a bug, but one which shouldn't manifest except where you
	\ have an origin that is near the upper 4GB boundary.  As long as your
	\ origin is 2GB or less, you should never have a carry-over into the
	\ upper 32-bit half of a dword address.
	\ 
	\ Assumes a 32-bit Forth environment.
: fixup-abs64 ( a -- )
	2 CELLS + @ DUP ID@ LC M+ ROT ID! ;

	\ absreloc creates an absolute relocation record in the Forth
	\ dictionary.
: absreloc ( a -- )
	DUP HERE >R
	CELL+ @ ,
	['] fixup-abs32 ,
	bc @ ,
	gp0 @ ,
	R> SWAP CELL+ ! ;

	\ abs64reloc creates an absolute relocation record in the Forth
	\ dictionary.
: abs64reloc ( a -- )
	DUP HERE >R
	CELL+ @ ,
	['] fixup-abs64 ,
	bc @ ,
	gp0 @ ,
	R> SWAP CELL+ ! ;

	\ Creates a new polymorphic Forth word to serve as a relocation record
	\ list header.  By default, when executed, the word will produce an
	\ error to the user if called directly.
	\ 
	\ Later, when the programmer defines a label of the same name, the
	\ handler is changed to match VALUE semantics.
: newdesc ( -- a )
	CREATE HERE >R ['] fwd , 0 , R> DOES> DUP @ EXECUTE ;

	\ Parse, and then look up a word, by name.
: lookup ( -- xt f )
	BL WORD FIND ;

	\ Handle a generic forward reference.
: (>) ( xt -- : "word" )
	>IN @
	lookup IF
		>BODY
		DUP @ ['] fwd = NOT ABORT" Shadowing existing word or label"
		NIP
	ELSE
		DROP >IN !
		newdesc
	THEN
	SWAP EXECUTE ;
	
	\ Absolute Word forward reference prefix.  Leaves 0 on the stack for
	\ later consumption by W,.
: AW> ( -- 0 : "word" )
	['] absreloc (>) 0 ;

	\ Absolute Dword forward reference prefix.  Leaves 0 on the stack for
	\ later consumption by the D, directive.
	\ 
	\ Assumes a 32-bit Forth runtime.
: AD> ( -- 0 : "word" )
	['] abs64reloc (>) 0 0 ;

	\ Fixes up a GP-relative offset for LOAD instructions.
: fixup-gl ( a -- )
	LC OVER 3 CELLS + @ - >R
	2 CELLS + @ DUP LD@ R> + SWAP LD! ;

	\ glreloc creates an global pointer-relative relocation record in the
	\ Forth dictionary.
: glreloc ( a -- )
	DUP HERE >R
	CELL+ @ ,
	['] fixup-gl ,
	bc @ ,
	gp0 @ ,
	R> SWAP CELL+ ! ;

	\ Global Pointer Relative forward reference prefix for LOADs.
: GL> ( -- 0 : "word" )
	['] glreloc (>) 0 ;

	\ Fixes up a GP-relative offset for STORE instructions.
: fixup-gs ( a -- )
	LC OVER 3 CELLS + @ - >R
	2 CELLS + @ DUP ST@ R> + SWAP ST! ;

	\ gsreloc creates an global pointer-relative relocation record in the
	\ Forth dictionary.
: gsreloc ( a -- )
	DUP HERE >R
	CELL+ @ ,
	['] fixup-gs ,
	bc @ ,
	gp0 @ ,
	R> SWAP CELL+ ! ;

	\ Global Pointer Relative forward reference prefix for STOREs.
: GS> ( -- 0 : "word" )
	['] gsreloc (>) 0 ;

	\ Global Pointer Relative back-reference to an already defined
	\ symbol for LOADs and STOREs.
: <G ( -- n "word" )
	lookup 0= ABORT" Label not defined"
	DUP >BODY @ ['] val = NOT ABORT" Label expected"
	EXECUTE gp0 @ - ;

	\ Performs a single relocation for a UJ-format instruction.
: fixup-jal ( a -- )
	2 CELLS + @ >R
	R@ UJ@
	LC R@ WORD+ - +
	R> UJ! ;

	\ Creates a relocation record for a UJ-format instruction.
: jalreloc ( a -- )
	DUP HERE >R
	CELL+ @ ,
	['] fixup-jal ,
	bc @ ,
	gp0 @ ,
	R> SWAP CELL+ ! ;

	\ PC-relative forward reference prefix for JAL and other UJ-format
	\ instructions.  Leaves LC+4 on the stack for consumption by the JAL
	\ instruction.
: JAL> ( -- lc : "word" )
	['] jalreloc (>) LC WORD+ ;

	\ Performs a single relocation for an SB-format instruction.
: fixup-bxx ( a -- )
	2 CELLS + @ >R
	R@ SB@
	LC R@ WORD+ - +
	R> SB! ;

	\ Creates a relocation record for an SB-format instruction.
: bxxreloc ( a -- )
	DUP HERE >R
	CELL+ @ ,
	['] fixup-bxx ,
	bc @ ,
	gp0 @ ,
	R> SWAP CELL+ ! ;

	\ PC-relative forward reference prefix for Bxx and other SB-format
	\ instructions.  Leaves LC+4 on the stack for consumption by the Bxx
	\ instruction.
: B> ( -- lc : "word" )
	['] bxxreloc (>) LC WORD+ ;

	\ Apply a single fix-up.
: fixup ( fx -- )
	DUP CELL+ @ EXECUTE ;

	\ Apply fixups by walking the fixup list until no more exist.
: fixups ( fx -- )
	BEGIN DUP WHILE DUP fixup @ REPEAT DROP ;

	\ Defines a new label.  Resolves all previously recorded forward
	\ references, if any exist.
: -> ( -- : "word" )
	>IN @
	lookup IF
		>BODY
		DUP @ ['] fwd = NOT
			OVER @ ['] val = NOT AND
			ABORT" Shadowing existing word or label"
		DUP @ ['] fwd = NOT ABORT" Duplicate label definition"
		DUP CELL+ @ fixups
		['] val OVER !
		LC OVER CELL+ !
		2DROP
	ELSE
		DROP >IN !
		CREATE ['] val , LC , DOES> DUP @ EXECUTE
	THEN ;

\ RV32I instructions.
\ Taken from http://riscv.org/download.html#tab_isaspec
HEX
: LUI		( imm rd -- )		00000037 U, ;
: AUIPC		( imm rd -- )		00000017 U, ;
: JAL		( disp rd -- )		0000006F UJ, ;
: JALR		( rs1 disp rd -- )	00000067 I, ;
: BEQ		( rs1 rs2 disp -- )	00000063 SB, ;
: BNE		( rs1 rs2 disp -- )	00001063 SB, ;
: BLT		( rs1 rs2 disp -- )	00004063 SB, ;
: BGE		( rs1 rs2 disp -- )	00005063 SB, ;
: BLTU		( rs1 rs2 disp -- )	00006063 SB, ;
: BGEU		( rs1 rs2 disp -- )	00007063 SB, ;
: LB		( rs1 disp rd -- )	00000003 I, ;
: LH		( rs1 disp rd -- )	00001003 I, ;
: LW		( rs1 disp rd -- )	00002003 I, ;
: LBU		( rs1 disp rd -- )	00004003 I, ;
: LHU		( rs1 disp rd -- )	00005003 I, ;
: SB		( rs1 rs2 imm -- )	00000023 S, ;
: SH		( rs1 rs2 imm -- )	00001023 S, ;
: SW		( rs1 rs2 imm -- )	00002023 S, ;
: ADDI		( rs1 imm rd -- )	00000013 I, ;
: SLLI		( rs1 imm rd -- )	00001013 I, ;
: SLTI		( rs1 imm rd -- )	00002013 I, ;
: SLTIU		( rs1 imm rd -- )	00003013 I, ;
: XORI		( rs1 imm rd -- )	00004013 I, ;
: SRLI		( rs1 imm rd -- )	00005013 I, ;
: SRAI		( rs1 imm rd -- )	40005013 I, ;
: ORI		( rs1 imm rd -- )	00006013 I, ;
: ANDI		( rs1 imm rd -- )	00007013 I, ;
: ADD		( rs1 rs2 rd -- )	00000033 R, ;
: SUB		( rs1 rs2 rd -- )	40000033 R, ;
: SLL		( rs1 rs2 rd -- )	00001033 R, ;
: SLT		( rs1 rs2 rd -- )	00002033 R, ;
: SLTU		( rs1 rs2 rd -- )	00003033 R, ;
: XOR		( rs1 rs2 rd -- )	00004033 R, ;
: SRL		( rs1 rs2 rd -- )	00005033 R, ;
: SRA		( rs1 rs2 rd -- )	40005033 R, ;
: OR		( rs1 rs2 rd -- )	00006033 R, ;
: AND		( rs1 rs2 rd -- )	00007033 R, ;
: CSRRW		( rs1 csr rd -- )	00001073 I, ;
: CSRRS		( rs1 csr rd -- )	00002073 I, ;
: CSRRC		( rs1 csr rd -- )	00003073 I, ;
: CSRRWI	( imm csr rd -- )	00005073 I, ;
: CSRRSI	( imm csr rd -- )	00006073 I, ;
: CSRRCI	( imm csr rd -- )	00007073 I, ;

\ RV64I extensions.
: LWU		( rs1 disp rd -- )	00006003 I, ;
: LD		( rs1 disp rd -- )	00007003 I, ;
: SD		( rs1 rs2 imm -- )	00003023 S, ;
: ADDIW		( rs1 imm rd -- )	0000001B I, ;
: SLLIW		( rs1 imm rd -- )	0000101B I, ;
: SRLIW		( rs1 imm rd -- )	0000501B I, ;
: SRAIW		( rs1 imm rd -- )	4000501B I, ;
: ADDW		( rs1 rs2 rd -- )	0000003B R, ;
: SUBW		( rs1 rs2 rd -- )	4000003B R, ;
: SLLW		( rs1 rs2 rd -- )	0000103B R, ;
: SRLW		( rs1 rs2 rd -- )	0000503B R, ;
: SRAW		( rs1 rs2 rd -- )	4000503B R, ;

\ Special case instruction forms.  Yuck.
: FENCE		( pred succ -- )	SWAP 4 LSHIFT OR 0 SWAP 0 0000000F I, ;
: FENCE.I	( -- )			0 0 0 0000100F I, ;
: SCALL		( -- )			0 0 0 00000073 I, ;
: SBREAK	( -- )			0 1 0 00000073 I, ;

\ Convenient aliases.
: RDCYCLE	( rd -- )		0 0C00 ROT CSRRS ;
: RDCYCLEH	( rd -- )		0 0C80 ROT CSRRS ;
: RDTIME	( rd -- )		0 0C01 ROT CSRRS ;
: RDTIMEH	( rd -- )		0 0C81 ROT CSRRS ;
: RDINSTRET	( rd -- )		0 0C02 ROT CSRRS ;
: RDINSTRETH	( rd -- )		0 0C82 ROT CSRRS ;
DECIMAL

\ Register names

 0 CONSTANT  X0	( Integer )
 1 CONSTANT  X1
 2 CONSTANT  X2
 3 CONSTANT  X3
 4 CONSTANT  X4
 5 CONSTANT  X5
 6 CONSTANT  X6
 7 CONSTANT  X7
 8 CONSTANT  X8
 9 CONSTANT  X9
10 CONSTANT X10
11 CONSTANT X11
12 CONSTANT X12
13 CONSTANT X13
14 CONSTANT X14
15 CONSTANT X15
16 CONSTANT X16
17 CONSTANT X17
18 CONSTANT X18
19 CONSTANT X19
20 CONSTANT X20
21 CONSTANT X21
22 CONSTANT X22
23 CONSTANT X23
24 CONSTANT X24
25 CONSTANT X25
26 CONSTANT X26
27 CONSTANT X27
28 CONSTANT X28
29 CONSTANT X29
30 CONSTANT X30
31 CONSTANT X31

