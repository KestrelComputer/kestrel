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
\ The bc variable contains the offset into the above image buffer where the
\ assembler should place the next byte.

VARIABLE lc0
VARIABLE bc

: ORG ( n -- )		lc0 ! ;
: LC ( -- n )		lc0 @ bc @ + ;
: RESET ( -- )		lc0 OFF  bc OFF ;
RESET

: room ( n -- )		bc @ + /image U> ABORT" Image overflow" ;

\ B, H, W, and D, place a byte, half-word, word, or double-word (8, 16, 32,
\ or 64 bit, respectively) values verbatim into the image buffer.
\ 
\ Note that double-word values are awkward to use with 32-bit Forth systems,
\ requiring double-sized values on the data stack.  E.g.,
\ $DEADBEEF.0BADC0DE D, versus $DEADBEEF0BADC0DE for a proper 64-bit system.
\ 
\ Observe that the RISC-V architecture is a LITTLE-ENDIAN instruction set
\ architecture.

: (b,) ( c -- )		bc @ image + C!  1 bc +! ;
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

\ R, I, S, SB, U, and UJ, function like B, H, W, and D, above.  However, they
\ place actual CPU instructions, and as such take additional parameters.
\ Note that I, S, SB, U, and UJ, all take an immediate operand of some kind;
\ however, each encodes its immediate value in a unique manner.  For example,
\ U, records bits 12 through 31 of an immediate value, while UJ, records
\ (in the same space) bits 1 through 21.

: R, ( rs1 rs2 rd opmask -- )
	4 ALIGN (rd) (rs2) (rs1) W, ;

: I, ( rs1 imm rd opmask -- )
	4 ALIGN (rd) (imm12) (rs1) W, ;

: S, ( rs1 rs2 imm opmask -- )
	4 ALIGN
	OVER 31 AND 7 LSHIFT OR
	SWAP 5 RSHIFT 25 LSHIFT OR
	(rs2) (rs1) W, ;

: SB, ( rs1 rs2 disp opmask -- )
	4 ALIGN
	OVER $01E AND 7 LSHIFT OR	( bits 4..1 )
	OVER $800 AND 4 RSHIFT OR	( bits 4..1,11 )
	OVER $7E0 AND 20 LSHIFT OR	( bits 10..5, 4..1, 11 )
	SWAP $1000 AND 19 LSHIFT OR	( bits 12, 10..5, 4..1, 11 )
	(rs2) (rs1) W, ;

: U, ( imm rd opmask -- )
	4 ALIGN (rd) SWAP $FFFFF000 AND OR W, ;

: UJ, ( disp rd opmask -- )
	4 ALIGN (rd)
	OVER $100000 AND 11 LSHIFT OR
	OVER $0007FE AND 20 LSHIFT OR
	OVER $000800 AND 9 LSHIFT OR
	SWAP $0FF000 AND OR W, ;

\ full-width instructions (32-bit on 32-bit CPUs, 64-bit on 64-bit CPUs, etc.)
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

