\ This software is the Kestrel-3's first milestone: print a bunch of "A"
\ characters to the console.

	$2000 ORG		( RISC-V ISA spec says we boot here. )

	0 x31 auipc		( X31 = address of next insn )
	assume-gp		( This lets us load big constants )

	x31 gl> uart-port x2 ld	( X2 = uart transmit port )
	x0 65 x3 addi		( X3 = ASCII code for "A" )
-> .again
	x3 x2 0 sb		( send "A" to console )
	x31 gl> .ctr x4 ld	( count how many "A"s we send )
	x4 1 x4 addi
	x4 x31 gs> .ctr sd
	.again x0 jal		( repeat forever )

-> uart-port	$0F000000.00000000 D,
-> .ctr		0.0 D,

