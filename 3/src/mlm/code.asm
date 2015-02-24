\ 
\ Cold Boot Entry Point
\ 

	X0 brod_initsp		SP	LD

	ZERO	CHAR *		A0	ADDI
	JAL> bios_putchar	RA	JAL

-> do-it-again

	ZERO	banner		A0	ADDI
	JAL> bios_putstrz	RA	JAL

-> wait-for-key
	JAL> bios_chkchar	RA	JAL
	X0	A0		wait-for-key BEQ
	JAL> bios_getchar	RA	JAL
	JAL> bios_putchar	RA	JAL
	wait-for-key		X0	JAL

	LC			ZERO	JAL

\
\ BIOS Character Services
\ 

\ Print a single character to the user's console.

-> bios_putchar ( ch )
		\ A0

	X0 brod_uart_base	T0	LD
	A0		T0 UART_TX	SB
	RA 0			X0	JALR



\ Print a zero-terminated string to the user's console.
\ This routine makes no attempt to interpret terminal control codes.

-> bios_putstrz ( strp )
		\  A0

	SP	-16		SP	ADDI
	S0			SP 0	SD
	RA			SP 8	SD

	A0	0		S0	ORI

-> .bios.putstrz.loop
	S0 0			A0			LBU
	ZERO	A0		B> .bios.putstrz.rtn	BEQ
	bios_putchar		RA			JAL
	S0	1		S0			ADDI
	.bios.putstrz.loop	X0			JAL

-> .bios.putstrz.rtn
	SP 8			RA	LD
	SP 0			S0	LD
	SP	16		SP	ADDI
	RA 0			X0	JALR


\ Check to see if a key has been pressed.
\ Returns pending ASCII code if a key is pending; use bios_getchar to pop it.
\ Returns zero otherwise.

-> bios_chkchar ( ) \ ascii
	X0 brod_bcb				T0			LD	( T0 -> BIOS Control Block )
	T0 bcb_keypress				A0			LBU	( do we have a key pending? )
	X0			A0		B> .bios.chkchar.done	BNE	( Yes, just return it )
	X0 brod_uart_base			T1			LD	( T1 -> UART base )
	T1 UART_RX				A0			LBU	( Check UART receive register )
	A0					T0 bcb_keypress		SB	( Hopefully queue key pending buffer )
-> .bios.chkchar.done
	RA 0					X0			JALR


\ Get a character, if it's been pressed.
\ Returns the current ASCII code if pending; zero otherwise.
\ Note that this function does not block.
\ To non-destructively read the next byte, if any, use bios_chkchar.

-> bios_getchar ( ) \ ascii
	X0 brod_bcb				T0			LD	( T0 -> BIOS Control Block )
	X0 brod_uart_base			T1			LD	( T1 -> UART )
	T0 bcb_keypress				A0			LBU	( pending keypress? )
	X0			A0		B> .bios.getchar.q	BNE	( Yes, pop the queue )
	T1 UART_RX				A0			LBU	( otherwise, read directly from uart )
	RA 0					X0			JALR

-> .bios.getchar.q
	X0					T0 bcb_keypress		SB
	RA 0					X0			JALR

