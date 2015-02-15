\ This software is the Kestrel-3's second milestone: print a message and halt.
\ We do this by calling a subroutine.

	$0000 ORG

-> msg1	S" Polaris V1 RISC-V CPU" ASCII, 13 B, 10 B,
-> msg1end

-> msg2 S" Hello world!" ASCII, 13 B, 10 B,
-> msg2end

	$CC $2000 ADVANCE	( RISC-V ISA spec says we boot here. )

	0 x31 auipc		( X31 = address of next instruction )
	assume-gp

	x0 msg1 x1 addi		( X1 -> msg to print )
	x0 msg1end msg1 - x2 addi	( X2 = length of msg )
	x31 gl> putstr x3 jalr	( try printing the string)

	x0 msg2 x1 addi
	x0 msg2end msg2 - x2 addi
	x31 gl> putstr x3 jalr

	LC x0 jal		( Halt. )

-> putstr
	x31 0 x30 addi		( Save and assume a GP )
	0 x31 auipc
	assume-gp

	x31 gl> uart-tx x4 ld	( X4 -> UART TX register )
-> agn
	x1 0 x8 lb		( X8 = byte to print )
	x8 x4 0 sb		( print it. )
	x1 1 x1 addi		( Next byte to print )
	x2 -1 x2 addi		( One less to print )
	x0 x2 agn bne		( Print more characters until no more )

	x30 0 x31 addi		( Restore GP )
	x3 0 x0 jalr		( return )

-> uart-tx	$0F000000.00000000 D,
-> ram-base	$01000000.00000000 D,

