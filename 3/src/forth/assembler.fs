: token		32 word count ;
: tcode		4 talign there token thead, ;
: tend-code	treveal ;

: chkopc	dup 0 128 within 0= abort" Bad opcode" ;
: chkreg	dup 0 32 within 0= abort" Bad register" ;
: chkfn3	dup 0 8 within 0= abort" Bad fn3" ;
: chkfn7	dup 0 128 within 0= abort" Bad fn7" ;
: chkimm12	dup -2048 2048 within 0= abort" Bad 12-bit immediate" ;
: chkshf	dup 0 64 within 0= abort" Bad shift span" ;
: chkimm20	$FFFFF000 and ; ( pre-shifted! )
: chkdisp13	dup -4096 4096 within 0= abort" Bad 13-bit displacement" ;
: chkdisp21	dup -1048576 1048576 within 0= abort" Bad 21-bit displacement" ;

: common ( rs1 fn3 rd opc -- w )
	chkopc swap chkreg 7 lshift or
	swap chkfn3 12 lshift or swap chkreg 15 lshift or ;

: rtype ( fn7 rs2 rs1 fn3 rd opc -- w )
	common swap chkreg 20 lshift or swap chkfn7 25 lshift or ;

: alupre	S" @ swap >r -rot >r >r" evaluate ; immediate
: alupost	S" swap r> r> rot r> $33 rtype" evaluate ; immediate
: alu1:		create , does> alupre 0 alupost tw, ;
: alu2:		create , does> alupre $20 alupost tw, ;

0 alu1: add,	0 alu2: sub,
1 alu1: sll,
2 alu1: slt,
3 alu1: sltu,
4 alu1: xor,
5 alu1: srl,	5 alu2: sra,
6 alu1: or,
7 alu1: and,

: itype ( imm12 rs1 fn3 rd opc -- w )
	common swap chkimm12 20 lshift or ;

: load:		create , does> @ swap $03 itype tw, ;
: alui:		create , does> @ swap $13 itype tw, ;

0 load: lb,	0 alui: addi,
1 load: lh,	( 1 alui: slli, )
2 load: lw,	2 alui: slti,
3 load: ld,	3 alui: sltui,
4 load: lbu,	4 alui: xori,
5 load: lhu,	( 5 alui: srli, )
6 load: lwu,	6 alui: ori,
7 load: ldu,	7 alui: andi,

: jalr,		0 swap $67 itype tw, ;

: itypes ( s rs1 fn3 rd op - w ) ( itype for immediate shifts )
	common swap chkshf 20 lshift or ;

: slli,		1 swap $13 itypes tw, ;
: (srli)	5 swap $13 itypes ;
: srli,		(srli) tw, ;
: srai,		(srli) $40000000 or tw, ;

: stype ( imm12 rs1 rs2 fn3 opc -- w )
	chkopc swap chkfn3 12 lshift or swap chkreg 20 lshift or
	swap chkreg 15 lshift or over 31 and 7 lshift or
	swap chkimm12 5 rshift 25 lshift or ;

: store:	create , does> @ $23 stype tw, ;

0 store: sb,
1 store: sh,
2 store: sw,
3 store: sd,

: enc13
  dup 11 rshift 1 and
  over $7FE and or
  swap $1000 and 1 rshift or ;

: sbtype ( disp13 rs1 rs2 fn3 opc -- w )
	>r >r >r >r chkdisp13 enc13 r> r> r> r> stype ;

: branch:	create , does> @ $63 sbtype tw, ;

0 branch: beq,
1 branch: bne,
4 branch: blt,
5 branch: bge,
6 branch: bltu,
7 branch: bgeu,

: utype ( imm20 rd opc - w )
	chkopc swap chkreg 7 lshift or swap chkimm20 or ;

: lui,		$37 utype tw, ;
: auipc,	$17 utype tw, ;

\ The only UJ-type instruction I'm aware of so far.

: enc21
	dup $100000 and 1 rshift
	over $000800 and 3 rshift or
	over $0007FE and 8 lshift or
	swap $0FF000 and 12 rshift or
	12 lshift ;

: jal,		chkreg 7 lshift $6F or swap chkdisp21 enc21 or tw, ;

\ \ \ \ \ \
\ Image finalization (for ROMs only!)

: displacement	@ there - ;
: vec,		t>h romp !  tfind if displacement else 2drop 0 then 0 jal, ;
: userTrap	S" __USERTRAP__" $FFFFFFFFFFFFFE00 vec, ;
: superTrap	S" __SUPERTRAP__" $FFFFFFFFFFFFFE40 vec, ;
: hyperTrap	S" __HYPERTRAP__" $FFFFFFFFFFFFFE80 vec, ;
: machTrap	S" __MACHTRAP__" $FFFFFFFFFFFFFEC0 vec, ;
: nmi		S" __NMI__" $FFFFFFFFFFFFFEFC vec, ;
: reset		S" __RESET__" $FFFFFFFFFFFFFF00 vec, ;
variable linkage
: traps		userTrap superTrap hyperTrap machTrap nmi reset ;
: vectors	safety off traps linkage @ EXECUTE ;

: (linkage)	headp @ h>t $FFFFFFFFFFFFFFF8 t>h ! ;
' (linkage) linkage !

variable romfile

: save
  r/w create-file throw romfile !
  rom /rom romfile @ write-file throw
  romfile @ close-file throw ;


\ \ \ \ \ \
\ Identities for registers.
0 constant x0
1 constant x1
2 constant x2
3 constant x3
4 constant x4
5 constant x5
6 constant x6
7 constant x7
8 constant x8
9 constant x9
10 constant x10
11 constant x11
12 constant x12
13 constant x13
14 constant x14
15 constant x15
16 constant x16
17 constant x17
18 constant x18
19 constant x19
20 constant x20
21 constant x21
22 constant x22
23 constant x23
24 constant x24
25 constant x25
26 constant x26
27 constant x27
28 constant x28
29 constant x29
30 constant x30
31 constant x31

\ \ \ \ \ \
\ Forth Register Assignments
\ 
\ Registers chosen deliberately to map to C function parameters.
\ This should make interoperability with C code and callbacks easier.
\ A typical C function prototype would be:
\ 
\ typedef long long cell;
\ void Cprocedure(cell w, cell *ip, cell *up, cell* dsp, cell* rsp);
\ 
\ NOTE: Unlike Forth primitives, C procedures CANNOT change the values
\ of the Forth VM registers without resorting to compiler-specific
\ primitives or directives (e.g., GNU C's asm() syntax).
\ 
\ This selection of registers also maps Forth's registers into the
\ subset supported by the 16-bit RISC-V compressed instruction set.

x10 constant w
x11 constant ip
x12 constant up
x13 constant dsp
x14 constant rsp

\ \ \ \ \ \
\ Want to talk to C?  Use these register aliases.
x0 constant zero
x1 constant ra
x2 constant sp
x3 constant gp
x4 constant tp
x5 constant t0
x6 constant t1
x7 constant t2
x8 constant s0	( or... )  x8 constant fp
x9 constant s1
x10 constant a0
x11 constant a1
x12 constant a2
x13 constant a3
x14 constant a4
x15 constant a5
x16 constant a6
x17 constant a7
x18 constant s2
x19 constant s3
x20 constant s4
x21 constant s5
x22 constant s6
x23 constant s7
x24 constant s8
x25 constant s9
x26 constant s10
x27 constant s11
x28 constant t3
x29 constant t4
x30 constant t5
x31 constant t6

