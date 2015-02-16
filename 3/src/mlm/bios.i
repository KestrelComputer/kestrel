\ BIOS Read-Only Data block.  This BROD contains hardware-specific constants
\ which lets the system software discover everything else that it needs to run.

0 	DUP CONSTANT	brod_uart_base
8 +	DUP CONSTANT	brod_initsp
	CONSTANT	brod_sizeof
