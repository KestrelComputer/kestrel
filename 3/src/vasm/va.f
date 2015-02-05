65536 CONSTANT /image
CREATE image
/image ALLOT

VARIABLE lc0
VARIABLE bc

: ORG ( n -- )		lc0 ! ;
: LC ( -- n )		lc0 @ bc @ + ;
: RESET ( -- )		lc0 OFF  bc OFF ;
RESET

: room ( n -- )		bc @ + /image U> ABORT" Image overflow" ;

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

: ALIGN ( n -- )	DUP 1- bc @ + SWAP NEGATE AND bc ! ;

: (rs1)			SWAP 15 LSHIFT OR ;
: (rs2)			SWAP 20 LSHIFT OR ;
: (rd)			SWAP 7 LSHIFT OR ;

: R, ( rs1 rs2 rd opmask -- )
	(rd) (rs2) (rs1) W, ;

: I, ( rs1 imm rd opmask -- )
	(rd) (rs2) (rs1) W, ;

: S, ( rs1 rs2 imm opmask -- )
	OVER 31 AND 7 LSHIFT OR
	SWAP 5 RSHIFT 25 LSHIFT OR
	(rs2) (rs1) W, ;

: SB, ( rs1 rs2 disp opmask -- )
	OVER $01E AND 7 LSHIFT OR	( bits 4..1 )
	OVER $800 AND 4 RSHIFT OR	( bits 4..1,11 )
	OVER $7E0 AND 20 LSHIFT OR	( bits 10..5, 4..1, 11 )
	SWAP $1000 AND 19 LSHIFT OR	( bits 12, 10..5, 4..1, 11 )
	(rs2) (rs1) W, ;

: U, ( imm rd opmask -- )
	(rd) SWAP $FFFFF000 AND OR W, ;

: UJ, ( disp rd opmask -- )
	(rd)
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
: RDCYCLE	( rd -- )		>R 0 0C00 R> CSRRS ;
: RDCYCLEH	( rd -- )		>R 0 0C80 R> CSRRS ;
: RDTIME	( rd -- )		>R 0 0C01 R> CSRRS ;
: RDTIMEH	( rd -- )		>R 0 0C81 R> CSRRS ;
: RDINSTRET	( rd -- )		>R 0 0C02 R> CSRRS ;
: RDINSTRETH	( rd -- )		>R 0 0C82 R> CSRRS ;
DECIMAL

