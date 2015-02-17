\ BIOS Read-Only Data block.  This BROD contains hardware-specific constants
\ which lets the system software discover everything else that it needs to run.

0 	DUP CONSTANT	brod_uart_base
8 +	DUP CONSTANT	brod_initsp
8 +	DUP CONSTANT	brod_bcb
8 +	CONSTANT	brod_sizeof


\ BIOS maintains state in RAM as well.  For lack of better name, this is called
\ the BIOS Control Block, or BCB.

0	DUP CONSTANT	bcb_keypress
1 +	CONSTANT	bcb_sizeof

