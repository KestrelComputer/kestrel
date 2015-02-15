\ This third milestone exercises the Polaris immediate-operand computation
\ instructions.  ADDI is tested as far back as m1, so we ignore it here.
\ SLTI, SLTIU, SLLI, SRLI, SRAI, ANDI, ORI, and XORI are exercised here.
\
\ This code will print a single letter to the console if a test fails.
\ Register X30 holds the ASCII code to print in such a case.
\ Otherwise, if all tests pass, "Z" is printed.

	$0000 ORG



	$CC $2000 ADVANCE	( RISC-V ISA spec says we boot here. )

	0 x31 auipc		( X31 = address of next instruction )
	assume-gp

	x0 1 x1 addi		( X0 = 0 by hardware; X1 = 1 )

-> trySLTI<
	x0 65 x30 addi		( X30 = test ID )
	x0 10 x2 addi		( if 10 < 20 via SLTI, print Y )
	x2 20 x3 slti		( X3 = 1 )
	x1 x3 b> trySLTI= beq

-> oops	x31 gl> uart-tx x1 ld
	x30 x1 0 sb
	lc x0 jal

-> trySLTI=
	x0 66 x30 addi
	x0 20 x2 addi
	x2 20 x3 slti
	x0 x3 oops bne
	
-> trySLTI>
	x0 67 x30 addi
	x0 30 x2 addi
	x2 20 x3 slti
	x0 x3 oops bne

-> trySLTI<-
	x0 68 x30 addi
	x0 -20 x2 addi
	x2 20 x3 slti
	x1 x3 oops bne

-> trySLTI>=-
	x0 69 x30 addi
	x0 20 x2 addi
	x2 -20 x3 slti
	x0 x3 oops bne

-> trySLTIU<
	x0 70 x30 addi
	x0 10 x2 addi
	x2 20 x3 sltiu
	x1 x3 oops bne

-> trySLTIU=
	x0 71 x30 addi
	x0 20 x2 addi
	x2 20 x3 sltiu
	x0 x3 oops bne

-> trySLTIU>
	x0 72 x30 addi
	x0 30 x2 addi
	x2 20 x3 sltiu
	x0 x3 oops bne

-> trySLTIU<-
	x0 73 x30 addi
	x0 -20 x2 addi
	x2 20 x3 sltiu
	x0 x3 oops bne		( -20 is a huge number in unsigned math )

-> trySLTIU>=-
	x0 74 x30 addi
	x0 20 x2 addi
	x2 -20 x3 sltiu
	x1 x3 oops bne		( same here; 20 is much less than $FF..FFEC )

-> trySLLI
	x0 75 x30 addi
	x0 1 x2 addi
	x2 63 x3 slli
	x31 gl> slli-desired x2 ld
	x2 x3 oops bne

-> trySRLI
	x0 76 x30 addi
	x31 gl> slli-desired x2 ld
	x2 63 x3 srli
	x0 1 x2 addi
	x2 x3 oops bne

-> trySRAI
	x0 77 x30 addi
	x31 gl> slli-desired x2 ld
	x2 63 x3 srai
	x0 -1 x2 addi
	x2 x3 oops bne

-> tryANDI
	x0 78 x30 addi
	x0 $03F x2 addi
	x2 $333 x3 andi
	x0 $033 x2 addi
	x2 x3 oops bne

-> tryORI
	x0 78 x30 addi
	x0 $03F x2 addi
	x2 $333 x3 ori
	x0 $33F x2 addi
	x2 x3 oops bne

-> tryXORI
	x0 78 x30 addi
	x0 $03F x2 addi
	x2 $333 x3 xori
	x0 $30C x2 addi
	x2 x3 oops bne

	x0 char Z x30 addi
	oops x0 jal

-> uart-tx	$0F000000.00000000 D,
-> slli-desired	$80000000.00000000 D,
