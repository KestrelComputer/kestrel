\ BIOS Read-Only Data structure goes here.

	$0F000000.00000000 D,	( UART base )
	$01000000.00001000 D,	( Cold-boot SP initial value )
	$01000000.00000000 D,	( BIOS Control Block at start of RAM )

-> banner
	S" MLM/K3 V1" ASCII, 10 B, 0 B,
-> banner_end
banner_end banner - CONSTANT banner_length

