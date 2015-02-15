\ This fourth milestone exercises the Polaris immediate-operand computation
\ instructions.  ADD, SUB, SLT, SLTU, SLL, SRL, SRA, AND, OR, and XOR are
\ exercised here.
\
\ This code will print a single letter to the console if a test fails.
\ Register X30 holds the ASCII code to print in such a case.
\ Otherwise, if all tests pass, "Z" is printed.

	$0000 ORG
	$CC $2000 ADVANCE	( RISC-V ISA spec says we boot here. )

	0 x31 auipc		( X31 = address of next instruction )
	assume-gp

-> tryADD
	x0 65 x30 addi
	x0 $0CC x2 addi
	x0 $0E0 x3 addi
	x2 x3 x4 add
	x0 $1AC x2 addi
	x2 x4 b> trySUB beq
	
-> oops	x31 gl> uart-tx x1 ld
	x30 x1 0 sb
	lc x0 jal

-> trySUB
	x0 66 x30 addi
	x0 $0CC x2 addi
	x0 $0E0 x3 addi
	x2 x3 x4 sub
	x0 $-14 x2 addi
	x2 x4 oops bne

-> trySLTI<
	x0 67 x30 addi
	x0 10 x2 addi
	x0 20 x3 addi
	x2 x3 x4 slt
	x0 1 x1 addi
	x1 x4 oops bne 

-> trySLTI=
	x0 68 x30 addi
	x0 20 x2 addi
	x0 20 x3 addi
	x2 x3 x4 slt
	x0 x4 oops bne
	
-> trySLTI>
	x0 69 x30 addi
	x0 30 x2 addi
	x0 20 x3 addi
	x2 x3 x4 slt
	x0 x4 oops bne

-> trySLTI<-
	x0 70 x30 addi
	x0 -20 x2 addi
	x0 20 x3 addi
	x2 x3 x4 slt
	x1 x4 oops bne

-> trySLTI>=-
	x0 71 x30 addi
	x0 20 x2 addi
	x0 -20 x3 addi
	x2 x3 x4 slt
	x0 x4 oops bne

-> trySLTIU<
	x0 72 x30 addi
	x0 10 x2 addi
	x0 20 x3 addi
	x2 x3 x4 sltu
	x1 x4 oops bne

-> trySLTIU=
	x0 73 x30 addi
	x0 20 x2 addi
	x0 20 x3 addi
	x2 x3 x4 sltu
	x0 x4 oops bne

-> trySLTIU>
	x0 74 x30 addi
	x0 30 x2 addi
	x0 20 x3 addi
	x2 x3 x4 sltu
	x0 x4 oops bne

-> trySLTIU<-
	x0 75 x30 addi
	x0 -20 x2 addi
	x0 20 x3 addi
	x2 x3 x4 sltu
	x0 x4 oops bne		( -20 is a huge number in unsigned math )

-> trySLTIU>=-
	x0 76 x30 addi
	x0 20 x2 addi
	x0 -20 x3 addi
	x2 x3 x4 sltu
	x1 x4 oops bne		( same here; 20 is much less than $FF..FFEC )

-> trySLLI
	x0 77 x30 addi
	x0 1 x2 addi
	x0 63 x3 addi
	x2 x3 x4 sll
	x31 gl> slli-desired x2 ld
	x2 x4 oops bne

-> trySRLI
	x0 78 x30 addi
	x31 gl> slli-desired x2 ld
	x0 63 x3 addi
	x2 x3 x4 srl
	x0 1 x2 addi
	x2 x4 oops bne

-> trySRAI
	x0 79 x30 addi
	x31 gl> slli-desired x2 ld
	x0 63 x3 addi
	x2 x3 x4 sra
	x0 -1 x2 addi
	x2 x4 oops bne

-> tryANDI
	x0 80 x30 addi
	x0 $03F x2 addi
	x0 $333 x3 addi
	x2 x3 x4 and
	x0 $033 x2 addi
	x2 x4 oops bne

-> tryORI
	x0 81 x30 addi
	x0 $03F x2 addi
	x0 $333 x3 addi
	x2 x3 x4 or
	x0 $33F x2 addi
	x2 x4 oops bne

-> tryXORI
	x0 82 x30 addi
	x0 $03F x2 addi
	x0 $333 x3 addi
	x2 x3 x4 xor
	x0 $30C x2 addi
	x2 x4 oops bne

	x0 char Z x30 addi
	oops x0 jal

-> uart-tx	$0F000000.00000000 D,
-> slli-desired	$80000000.00000000 D,
