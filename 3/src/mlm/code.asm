\ 
\ Cold Boot Entry Point
\ 

	ZERO	CHAR *		A0	ADDI
	JAL> bios_putchar	RA	JAL
	LC			ZERO	JAL

\
\ BIOS Character Services
\ 

-> bios_putchar ( ch )
		\ A0

	X0 brod_uart_base	T0	LD
	A0		T0 UART_TX	SB
	RA 0			X0	JALR
