\ This software is the Kestrel-3's first milestone: print a bunch of "A"
\ characters to the console.

	\ RAM variables
0 CONSTANT ctr		( loop iteration counter )

	$0000 ORG
	$CC $2000 ADVANCE	( RISC-V ISA spec says we boot here. )

	0 x31 auipc		( X31 = address of next instruction )
	assume-gp

	x31 gl> uart-tx x2 ld	( X2 -> UART TX register )
	x0 65 x3 addi		( X3 = ASCII character 'A' )

	x31 gl> ram-base x4 ld	( X4 -> start of RAM )

-> agn	x3 x2 0 sb		( Send 'a' to console )
	x4 ctr x5 ld		( Increment loop counter )
	x5 1 x5 addi
	x5 x4 ctr sd
	agn x0 jal		( repeat forever )

-> uart-tx	$0F000000.00000000 D,
-> ram-base	$01000000.00000000 D,
