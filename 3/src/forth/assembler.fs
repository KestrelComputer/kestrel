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

: slli,		1 swap $03 itypes tw, ;
: (srli)	5 swap $03 itypes ;
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

: sbtype ( disp12 rs1 rs2 fn3 opc -- w )
	chkopc
	swap chkfn3 12 lshift or swap chkreg 20 lshift or
	swap chkreg 15 lshift or
	over chkdisp13 dup $1E and swap 11 rshift 1 and or 7 lshift or
	swap dup $7E0 and 5 rshift swap 6 rshift $40 and or 25 lshift or ;

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

: displacement	@ romp @ h>t - ;
: vec,		t>h romp !  tfind if displacement else 2drop 0 then 0 jal, ;
: userTrap	S" __USERTRAP__" $FFFFFFFFFFFFFE00 vec, ;
: superTrap	S" __SUPERTRAP__" $FFFFFFFFFFFFFE40 vec, ;
: hyperTrap	S" __HYPERTRAP__" $FFFFFFFFFFFFFE80 vec, ;
: machTrap	S" __MACHTRAP__" $FFFFFFFFFFFFFEC0 vec, ;
: nmi		S" __NMI__" $FFFFFFFFFFFFFEFC vec, ;
: reset		S" __RESET__" $FFFFFFFFFFFFFF00 vec, ;
: linkage	headp @ h>t $FFFFFFFFFFFFFFF8 t>h ! ;
: traps		userTrap superTrap hyperTrap machTrap nmi reset ;
: vectors	safety off traps linkage ;

