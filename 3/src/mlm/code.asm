\ 
\ Cold Boot Entry Point
\ 

	X0 brod_initsp		SP	LD

	ZERO	banner		A0	ADDI
	ZERO	banner_length	A1	ADDI
	JAL> bios_putstrc	RA	JAL

-> do-it-again

	ZERO brod_bcb		T0	LD
	ZERO	t0 bcb_accumulator	SD
	ZERO -1			T1	ADDI
	T1	T0 bcb_startaddr	SD


	ZERO	mlm_prompt	A0	ADDI
	ZERO	2		A1	ADDI
	JAL> bios_putstrc	RA	JAL

	\ Reset the line input buffer control block, and get the line of text.

	ZERO brod_bcb		T0		LD
	T0 bcb_licb		A0		ADDI
	T0 bcb_inpbuf		T2		ADDI
	T2			A0 blicb_buffer	SD	( licb.buffer -> inpbuf )
	ZERO			A0 blicb_length SD	( licb.length = 0 )
	ZERO 80			T2		ADDI
	T2			A0 blicb_capacity SD	( licb.capacity = 80 )
	JAL> bios_getline	RA		JAL

	\ When you ENTER on bios_getline, you don't actually move to next line.
	x0 10			a0	ori
	jal> bios_putchar	ra	jal

	\ Convert each character in the buffer to uppercase, for easier
	\ event dispatching.

	ZERO brod_bcb		t0	ld	( T0 -> BCB )
	t0 bcb_licb		t1	addi	( T1 -> BIOS' BLICB)
	t1 blicb_buffer		s1	ld	( S1 -> start of buffer )
	t1 blicb_length		s2	ld	( S2 -> length of line )

-> lowercase-again
	s2 x0	 b> interpret-line	beq	( Break loop if done w/ buffer )
	s1 0			s0	lb	( S0 = byte in buffer )

	ZERO 97			s3	addi	( If S0 < 'a', skip it )
	s0 s3	  b> not-lowercase	bltu

	ZERO 122		s3	addi	( If 'z' < S0, skip it )
	s3 s0	  b> not-lowercase	bltu

	s0 $20			s0	xori	( Convert to uppercase )
	s0			s1 0	sb

-> not-lowercase
	s1 1			s1	addi
	s2 -1			s2	addi
	lowercase-again		x0	jal
	
	\ Interpret the buffer, now consisting entirely of upper-case letters.
-> interpret-line
	t1 blicb_buffer		a0	ld	( A0 -> start of line )
	t1 blicb_length		a1	ld	( A1 = length of line )
	jal> interpret-cmd	ra	jal	( interpret the line )

	\ Lather, rinse, repeat.
	do-it-again		x0	jal


\ 
\ Interpret a complete MLM command
\ 

-> interpret-cmd
	sp -24			sp	addi
	ra			sp 0	sd
	s0			sp 8	sd
	s1			sp 16	sd

	x0 a0			s0	or	( Preserve args in S-regs )
	x0 a1			s1	or

-> interpreter-loop
	s1 x0 b> done-interpreting	beq	( If no further bytes, goodbye. )

	s0 0			a0	lb	( A0 = byte to interpret )
	jal> interpret-char	ra	jal	( interpret it. )

	s0 1			s0	addi
	s1 -1			s1	addi
	interpreter-loop	x0	jal


-> done-interpreting
	sp 16			s1	ld
	sp 8			s0	ld
	sp 0			ra	ld
	sp 24			sp	addi
	ra 0			x0	jalr


\ 
\ Interpret a single byte of an MLM command.
\ 

-> interpret-char
	x0 brod_bcb		t0	ld	( T0 -> BCB )
	t0 bcb_accumulator	t1	ld	( T1 = current accumulator )

	x0 48			t2	ori	( char < '0'? )
	a0 t2		b> not-digit	bltu

	x0 58			t2	ori	( char <= '9'? )
	a0 t2		b> eat-0..9	bltu

-> not-digit
	x0 65			t2	ori	( char < 'A'? )
	a0 t2		b> not-hex	bltu

	x0 71			t2	ori	( char < 'F'? )
	a0 t2		b> eat-hex	bltu

-> not-hex
	x0 64			t2	ori	( char = '@'? )
	a0 t2		b> eat-@	beq

	x0 46			t2	ori	( char = '.'? )
	a0 t2		b> eat-.	beq

	x0 44			t2	ori	( char = ','? )
	a0 t2		b> eat-,	beq

	x0 71			t2	ori	( char = 'G'? )
	a0 t2		b> eat-G	beq

	x0 58			t2	ori	( char = ':'? )
	a0 t2		b> eat-:	beq

	x0 88			t2	ori	( char = 'X'? )
	a0 t2		b> eat-X	beq

	jal> bios_putchar x0 jal


-> eat-hex
	a0 -7			a0	addi	( sequentialize then fall through )

-> eat-0..9
	a0 -48			a0	addi	( extract BCD digit )

	t1 4			t1	slli	( make room for digit )
	t1 a0			t1	or	( merge digit )
	t1	t0 bcb_accumulator	sd
	ra 0			x0	jalr

\ Dump user-mode register space

-> eat-:
	t1 7			t1	ori	( Regs are 8 bytes in size )
	\ fall through to eat-@

\ Dump byte of memory or dump range of bytes

-> eat-@
	sp -40			sp	addi	( preallocate slot for print-row's ra contents )
	ra			sp 0	sd
	s0			sp 8	sd
	s1			sp 16	sd
	s2			sp 24	sd

	t0 bcb_startaddr	s0	ld	( start address for dump )
	x0 -1			t2	ori	( Defaults to accumulator if start not set )
	s0 t2		b> >=2bytes	bne
	x0 t1			s0	or

-> >=2bytes
	s0 -16			s1	andi	( current peek pointer )
	t1 15			s2	ori	( end address for row )
	s2 1			s2	addi

-> another-row
	jal> print-row		ra	jal
	s1 s2 		another-row	bltu

	sp 0			ra	ld
	sp 8			s0	ld
	sp 16			s1	ld
	sp 24			s2	ld
	sp 40			sp	addi
	ra 0			x0	jalr

-> print-row
	ra			sp 32	sd
	t1 1			t1	addi	( to compensate for bgeu semantics )

	x0 s1			a0	or	( print address and colon )
	jal> puthex64		ra	jal
	x0 58			a0	ori
	jal> bios_putchar	ra	jal

	x0 16			s3	ori	( byte counter )

-> print-row-loop
	x0 s3		b> done-w/-row	beq

	s1 s0		b> a-dot	bltu
	s1 t1		b> a-dot	bgeu

	s1 0			a0	lb
	jal> puthex8		ra	jal
	x0 32			a0	ori
	jal> bios_putchar	ra	jal

-> next-byte
	s1 1			s1	addi
	s3 -1			s3	addi
	print-row-loop		x0	jal

-> a-dot
	x0 spdotsp		a0	ori
	x0 3			a1	ori
	jal> bios_putstrc	ra	jal
	next-byte		x0	jal

-> done-w/-row
	x0 10			a0	ori
	jal> bios_putchar	ra	jal
	sp 32			ra	ld
	t1 -1			t1	addi	( restore original value )
	ra 0			x0	jalr


\ Set start address register

-> eat-.
	t1	t0 bcb_startaddr	sd
	x0	t0 bcb_accumulator	sd
	ra 0			x0	jalr

\ Store a byte into memory.

-> eat-,
	t0 bcb_startaddr	t2	ld
	t1			t2 0	sb
	t2 1			t2	addi
	t2	t0 bcb_startaddr	sd
	t1 8			t1	srli
	t1	t0 bcb_accumulator	sd
	ra 0			x0	jalr

\ Goto!

-> eat-G
	sp -8			sp	addi
	ra			sp 0	sd
	t1 0			ra	jalr
	sp 0			ra	ld
	sp 8			sp	addi
	ra 0			x0	jalr

\ Compute user-mode register address in memory

-> eat-X
	t1 31			t1	andi
	t1 3			t1	slli
	t1 t0			t1	add
	t1 bcb_userRegs		t1	addi
	t1	t0 bcb_accumulator	sd
	ra 0			x0	jalr

\ 
\ Print newline
\ 

-> newline
	x0 10			a0	ori
	jal> bios_putchar	x0	jal

\ 
\ Print out hexadecimal numbers of various widths.  These must appear
\ immediately before bios_putchar (or else, adjust the puthex4 routine to jump
\ to bios_putchar).
\ 

-> puthex64
	sp -16			sp	addi
	ra			sp 0	sd
	s0			sp 8	sd

	x0 a0			s0	or
	a0 32			a0	srli
	jal> puthex32		ra	jal

	x0 s0			a0	or
	sp 8			s0	ld
	sp 0			ra	ld
	sp 16			sp	addi

-> puthex32
	sp -16			sp	addi
	ra			sp 0	sd
	s0			sp 8	sd

	x0 a0			s0	or
	a0 16			a0	srli
	jal> puthex16		ra	jal

	x0 s0			a0	or
	sp 8			s0	ld
	sp 0			ra	ld
	sp 16			sp	addi

-> puthex16
	sp -16			sp	addi
	ra			sp 0	sd
	s0			sp 8	sd

	x0 a0			s0	or
	a0 8			a0	srli
	jal> puthex8		ra	jal

	x0 s0			a0	or
	sp 8			s0	ld
	sp 0			ra	ld
	sp 16			sp	addi

-> puthex8
	sp -16			sp	addi
	ra			sp 0	sd
	s0			sp 8	sd

	x0 a0			s0	or
	a0 4			a0	srli
	jal> puthex4		ra	jal

	x0 s0			a0	or
	sp 8			s0	ld
	sp 0			ra	ld
	sp 16			sp	addi

-> puthex4
	a0 15			a0	andi

	\ The following instruction replaces a more complex instruction
	\ sequence, but it only works if hextable sits below 2K in ROM.
	\ If we didn't know ahead of time where hextable sat, we'd need this:
	\ 
	\ auipc	 x31,0
	\ ld     t3,_addr_hextable
	\ add	 a0,a0,t3
	\ lb	 a0,0(a0)

	a0 hextable		a0	lb

	\ fall through to bios_putchar

\ 
\ BIOS Character Services
\ 

\ Print a single character to the user's console.

-> bios_putchar ( ch )
		\ A0

	X0 brod_uart_base	T0	LD
	A0		T0 UART_TX	SB
	RA 0			X0	JALR



\ Print a counted string to the user's console.
\ This routine makes no attempt to interpret terminal control codes.

-> bios_putstrc ( strp, strlen )
		\  A0     A1
	SP -16			SP	ADDI
	S0			SP 0	SD
	RA			SP 8	SD

	X0 A0			S0	OR

-> .bios.putstrc.loop
	A1 X0			B> .bios.putstrc.done BEQ
	S0 0			A0	LBU
	bios_putchar		RA	JAL
	S0 1			S0	ADDI
	A1 -1			A1	ADDI
	.bios.putstrc.loop	X0	JAL

-> .bios.putstrc.done
	SP 8			RA	LD
	SP 0			S0	LD
	SP 16			SP	ADDI
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

\ Get a line of text from the user's console.
\ This routine is genuinely very basic.  It's intended for bootstrapping
\ purposes only.
\ 
\ Takes a pointer to a Line Input Control Block.  You are responsible for
\ initializing the control block prior to calling this procedure.
\ The Buffer field must point to the input buffer.  The Capacity field must
\ contain the maximum size of the buffer.  Unless you know exactly what you're
\ doing, you will want to set the Length field to zero.
\ 
\ Upon return from this procedure, the Length field will contain the number of
\ valid bytes in the buffer.  Note that this procedure WILL NOT null-terminate
\ the buffer contents.  If this is important for your purposes, you'll need to
\ manually terminate the buffer yourself.
-> bios_getline ( licb )
		\  A0
	SP -16			SP	ADDI
	RA			SP 0	SD
	S0			SP 8	SD

	ZERO A0			S0	OR

-> wait-for-key
	bios_chkchar		RA	JAL
	X0 A0			wait-for-key BEQ
	bios_getchar		RA	JAL

	S0 blicb_length		T2	LD

	\ If the user presses ENTER, we accept the buffer as-is.
	\ It's up to the consumer to check for zero-length buffers.
	ZERO 10			T3	ADDI
	A0 T3			B> not-cr BNE

	SP 8			S0	LD
	SP 0			RA	LD
	SP 16			SP	ADDI
	RA 0			X0	JALR

	\ If backspace, and buffer non-empty, back up one space.
-> not-cr
	ZERO 127		T3	ORI
	A0 T3			B> bs-del BEQ
	ZERO 8			T3	ORI
	A0 T3			B> not-bs BNE

-> bs-del
	X0 T2			wait-for-key BEQ

	T2 -1			T2	ADDI
	T2			S0 blicb_length SD

	0			A0	AUIPC	( print bs, space, bs )
	A0 12			A0	ADDI
	bios_putstrz		RA	JAL
	wait-for-key		X0	JAL
	8 B, 32 B, 8 B, 0 B,

	\ Ignore key press if there's no room to place it.
-> not-bs
	S0 blicb_capacity	T3	LD
	T2 T3			wait-for-key BEQ

	\ Place the byte, and increment the buffer length.
	S0 blicb_buffer		T3	LD
	T2 T3			T3	ADD
	A0			T3 0	SB
	T2 1			T2	ADDI
	T2			S0 blicb_length SD

	bios_putchar		RA	JAL
	wait-for-key		X0	JAL

