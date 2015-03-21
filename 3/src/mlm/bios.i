\ BIOS line input control block.
0	DUP CONSTANT	blicb_buffer
8 +	DUP CONSTANT	blicb_length
8 +	DUP CONSTANT	blicb_capacity
8 +	CONSTANT	blicb_sizeof

\ BIOS Read-Only Data block.  This BROD contains hardware-specific constants
\ which lets the system software discover everything else that it needs to run.

0	DUP CONSTANT	brod_uart_base
8 +	DUP CONSTANT	brod_initsp
8 +	DUP CONSTANT	brod_bcb
8 +	CONSTANT	brod_sizeof


\ BIOS maintains state in RAM as well.	For lack of better name, this is called
\ the BIOS Control Block, or BCB.

0		DUP CONSTANT	bcb_inpindex
8 +		DUP CONSTANT	bcb_licb
blicb_sizeof +	DUP CONSTANT	bcb_keypress
1 +		DUP CONSTANT	bcb_inpbuf
81 +		CONSTANT	bcb_sizeof

