;**************************************************************
; Kestrel-3 Machine Language Monitor
; Release 0.2
;**************************************************************

; Register Definitions

 x0 =  0
 x1 =  1
 x2 =  2
 x3 =  3
 x4 =  4
 x5 =  5
 x6 =  6
 x7 =  7
 x8 =  8
 x9 =  9
x10 = 10
x11 = 11
x12 = 12
x13 = 13
x14 = 14
x15 = 15
x16 = 16
x17 = 17
x18 = 18
x19 = 19
x20 = 20
x21 = 21
x22 = 22
x23 = 23
x24 = 24
x25 = 25
x26 = 26
x27 = 27
x28 = 28
x29 = 29
x30 = 30
x31 = 31

ra = x1
sp = x2
gp = x3
tp = x4
t0 = x5
t1 = x6
t2 = x7
s0 = x8
s1 = x9
a0 = x10
a1 = x11
a2 = x12
a3 = x13
a4 = x14
a5 = x15
a6 = x16
a7 = x17
s2 = x18
s3 = x19
s4 = x20
s5 = x21
s6 = x22
s7 = x23
s8 = x24
s9 = x25
s10 = x26
s11 = x27
t3 = x28
t4 = x29
t5 = x30
t6 = x31


; UART definitions.
;
; STATUS flags as follows:
; 
;   7   6   5   4   3   2   1   0
; +---+---+---+---+---+---+---+---+
; |///|///|///|///|///|///|///| R |
; +---+---+---+---+---+---+---+---+
; 
; R=1 if data is available to be read; 0 otherwise.

UART_TX		= 0
UART_STATUS	= UART_TX
UART_RX		= UART_STATUS + 1
UART_sizeof	= UART_RX + 1

; BIOS Line Input Control Block (BLICB)

blicb_buffer	= 0
blicb_length	= blicb_buffer+8
blicb_capacity	= blicb_length+8
blicb_sizeof	= blicb_capacity+8

; BIOS Read-Only Data Block (BROD).  This contains hardware-specific constants
; which lets the system software discover everything else that it needs to run.

brod_uartBase	= 0
brod_initSP	= brod_uartBase+8
brod_bcb	= brod_initSP+8
brod_sizeof	= brod_bcb+8

; BIOS maintains state in RAM as well.	For lack of better name, this is called
; the BIOS Control Block, or BCB.

bcb_userRegs	= 0
bcb_inpIndex	= bcb_userRegs+32*8	; Reserving space for X0 avoids special-case logic.
bcb_accumulator	= bcb_inpIndex+8
bcb_startAddr	= bcb_accumulator+8
bcb_licb	= bcb_startAddr+8
bcb_keyPress	= bcb_licb+blicb_sizeof
bcb_inpBuf	= bcb_keyPress+1
bcb_sizeof	= bcb_inpBuf+81


; BIOS Read-Only Data structure goes here.

	dword	$0F00000000000000	; brod_uartBase
	dword	$0100000000001000	; brod_initSP
	dword	$0100000000000000	; brod_bcb

banner:
	byte	"MLM/K3 V1b", 10
bannerLength	= *-banner

mlmPrompt:
	byte	"* "

hexTable:
	byte	"0123456789ABCDEF"

spDotSp:
	byte	" . "

	adv	$2000, $CC
;
; Cold Boot and MLM Entry Points
; 
; Currently they're the same, but this is an implementation detail.
; The reason the mlm-entry is at offset 8 is that it places the vector at
; $2008, which with a bit of massaging, allows this code:
; 
;	ori	t0, x0, $401
;	slli	t0, t0, 3
;	jalr	x0, 0(t0)
; 
; to invoke the debugger without the need for special loader support for
; relocating absolute addresses at runtime.  ($401 times 8 is $2008.)
; 

	jal	x0, coldBoot	; CPU boots here
	jal	x0, coldBoot
	jal	x0, mlmEntry	; MLM entry point
	jal	x0, mlmEntry

coldBoot:
mlmEntry:
	; Save user register state.
	; 
	; Implementation Detail: Until SBREAK and proper exceptions are supported,
	; we must use a single register as a base pointer to our debugger area.
	; I've chosen S11 because it's the least likely to be used register.
	; I hope.

	ld	s11, brod_bcb(x0)
	sd	x1, bcb_userRegs+8(s11)
	sd	x2, bcb_userRegs+16(s11)
	sd	x3, bcb_userRegs+24(s11)
	sd	x4, bcb_userRegs+32(s11)
	sd	x5, bcb_userRegs+40(s11)
	sd	x6, bcb_userRegs+48(s11)
	sd	x7, bcb_userRegs+56(s11)
	sd	x8, bcb_userRegs+64(s11)
	sd	x9, bcb_userRegs+72(s11)
	sd	x10, bcb_userRegs+80(s11)
	sd	x11, bcb_userRegs+88(s11)
	sd	x12, bcb_userRegs+96(s11)
	sd	x13, bcb_userRegs+104(s11)
	sd	x14, bcb_userRegs+112(s11)
	sd	x15, bcb_userRegs+120(s11)
	sd	x16, bcb_userRegs+128(s11)
	sd	x17, bcb_userRegs+136(s11)
	sd	x18, bcb_userRegs+144(s11)
	sd	x19, bcb_userRegs+152(s11)
	sd	x20, bcb_userRegs+160(s11)
	sd	x21, bcb_userRegs+168(s11)
	sd	x22, bcb_userRegs+176(s11)
	sd	x23, bcb_userRegs+184(s11)
	sd	x24, bcb_userRegs+192(s11)
	sd	x25, bcb_userRegs+200(s11)
	sd	x26, bcb_userRegs+208(s11)
;	sd	x27, bcb_userRegs+216(s11)	; Don't support X27 (aka S11) yet.
	sd	x28, bcb_userRegs+224(s11)
	sd	x29, bcb_userRegs+232(s11)
	sd	x30, bcb_userRegs+240(s11)
	sd	x31, bcb_userRegs+248(s11)

	ld	sp, brod_initSP(x0)

	addi	a0, x0, banner
	addi	a1, x0, bannerLength
	jal	ra, biosPutStrC

doItAgain:
	ld	t0, brod_bcb(x0)
	sd	x0, bcb_accumulator(t0)
	addi	t1, x0, -1
	sd	t1, bcb_startAddr(t0)

	addi	a0, x0, mlmPrompt
	addi	a1, x0, 2
	jal	ra, biosPutStrC

	; Reset the line input buffer control block, and get the line of text.

	ld	t0, brod_bcb(x0)
	addi	a0, t0, bcb_licb
	addi	t2, t0, bcb_inpBuf
	sd	t2, blicb_buffer(a0)	; licb.buffer -> inpBuf
	sd	x0, blicb_length(a0)	; licb.length = 0
	addi	t2, x0, 80		; licb.capacity = 80
	sd	t2, blicb_capacity(a0)
	jal	ra, biosGetLine

	; When you ENTER on biosGetLine, you don't actually move to next line.
	ori	a0, x0, 10
	jal	ra, biosPutChar

	; Convert each character in the buffer to uppercase, for easier
	; event dispatching.

	ld	t0, brod_bcb(x0)	; t0 -> BCB
	addi	t1, t0, bcb_licb	; t1 -> BIOS' BLICB
	ld	s1, blicb_buffer(t1)	; s1 -> start of buffer
	ld	s2, blicb_length(t1)	; S2 = length of line

lowercaseAgain:
	beq	s2, x0, interpretLine	; Break loop if done w/ buffer
	lb	s0, 0(s1)		; s0 = byte in buffer

	addi	s3, x0, 97		; If s0 < 'a', skip it
	bltu	s0, s3, notLowercase

	addi	s3, x0, 122		; If 'z' < s0, skip it
	bltu	s3, s0, notLowercase

	xori	s0, s0, $20		; Convert to uppercase
	sb	s0, 0(s1)

notLowercase:
	addi	s1, s1, 1
	addi	s2, s2, -1
	jal	x0, lowercaseAgain
	
	; Interpret the buffer, now consisting entirely of upper-case letters.

interpretLine:
	ld	a0, blicb_buffer(t1)	; A0 -> start of line
	ld	a1, blicb_length(t1)	; A1 = length of line
	jal	ra, interpretCmd	; Interpret the command line
	jal	x0, doItAgain		; Repeat the steps for the next line

; 
; Interpret a complete MLM command
; 

interpretCmd:
	addi	sp, sp, -24
	sd	ra, 0(sp)
	sd	s0, 8(sp)
	sd	s1, 16(sp)
	or	s0, x0, a0		; preserve args in s-regs
	or	s1, x0, a1

interpreterLoop:
	beq	s1, x0, doneInterpreting ; If no further input, goodbye.

	lb	a0, 0(s0)		; a0 = byte to interpret
	jal	ra, interpretChar	; interpret it.

	addi	s0, s0, 1
	addi	s1, s1, -1
	jal	x0, interpreterLoop

doneInterpreting:
	ld	s1, 16(sp)
	ld	s0, 8(sp)
	ld	ra, 0(sp)
	addi	sp, sp, 24
	jalr	x0, 0(ra)

; 
; Interpret a single byte of an MLM command.
; 

interpretChar:
	ld	t0, brod_bcb(x0)	; t0 -> BCB
	ld	t1, bcb_accumulator(t0)	; t1 = current accumulator

	ori	t2, x0, 48		; char < '0'?
	bltu	a0, t2, notDigit

	ori	t2, x0, 58		; char <= '9'?
	bltu	a0, t2, eatDigit

notDigit:
	ori	t2, x0, 65		; char < 'A'?
	bltu	a0, t2, notHex

	ori	t2, x0, 71		; char <= 'F'?
	bltu	a0, t2, eatHex

notHex:
	ori	t2, x0, 64		; char = '@'?
	beq	a0, t2, eatAt

	ori	t2, x0, 46		; char = '.'?
	beq	a0, t2, eatDot

	ori	t2, x0, 44		; char = ','?
	beq	a0, t2, eatComma

	ori	t2, x0, 71		; char = 'G'?
	beq	a0, t2, eatG

	ori	t2, x0, 58		; char = ':'?
	beq	a0, t2, eatColon

	ori	t2, x0, 88		; char = 'X'?
	beq	a0, t2, eatX

	jalr	x0, 0(ra)

; Accumulate hexadecimal digits.

eatHex:
	addi	a0, a0, -7		; sequentialize then fall through

eatDigit:
	addi	a0, a0, -48		; extract BCD digit

	slli	t1, t1, 4		; make room for digit
	or	t1, t1, a0		; merge digit
	sd	t1, bcb_accumulator(t0)
	jalr	x0, 0(ra)

; Dump user-mode register space

eatColon:
	ori	t1, t1, 7		; Regs are 8 bytes in size
	; fall through to eatAt

; Dump byte of memory or dump range of bytes

eatAt:
	addi	sp, sp, -40		; Preallocate slot for printRow's RA register.
	sd	ra, 0(sp)
	sd	s0, 8(sp)
	sd	s1, 16(sp)
	sd	s2, 24(sp)

	ld	s0, bcb_startAddr(t0)	; start address for dump
	ori	t2, x0, -1		; defaults to accumulator if start not set
	bne	s0, t2, ge2bytes
	or	s0, x0, t1

ge2bytes:
	andi	s1, s0, -16		; current peek pointer
	ori	s2, t1, 15		; end address for now
	addi	s2, s2, 1

anotherRow:
	jal	ra, printRow
	bltu	s1, s2, anotherRow

	ld	ra, 0(sp)
	ld	s0, 8(sp)
	ld	s1, 16(sp)
	ld	s2, 24(sp)
	addi	sp, sp, 40
	jalr	x0, 0(ra)

printRow:
	sd	ra, 32(sp)
	addi	t1, t1, 1		; to compensate for bgeu semantics

	or	a0, x0, s1		; print address and colon
	jal	ra, puthex64
	ori	a0, x0, 58
	jal	ra, biosPutChar

	ori	s3, x0, 16		; byte counter

printRowLoop:
	beq	x0, s3, doneWithRow

	bltu	s1, s0, aDot
	bgeu	s1, t1, aDot

	lb	a0, 0(s1)
	jal	ra, puthex8
	ori	a0, x0, 32
	jal	ra, biosPutChar

nextByte:
	addi	s1, s1, 1
	addi	s3, s3, -1
	jal	x0, printRowLoop

aDot:
	ori	a0, x0, spDotSp
	ori	a1, x0, 3
	jal	ra, biosPutStrC
	jal	x0, nextByte

doneWithRow:
	ori	a0, x0, 10
	jal	ra, biosPutChar
	ld	ra, 32(sp)
	addi	t1, t1, -1		; restore original value
	jalr	x0, 0(ra)

; Set start address register

eatDot:
	sd	t1, bcb_startAddr(t0)
	sd	x0, bcb_accumulator(t0)
	jalr	x0, 0(ra)

; Store a byte into memory.

eatComma:
	ld	t2, bcb_startAddr(t0)
	sb	t1, 0(t2)
	addi	t2, t2, 1
	sd	t2, bcb_startAddr(t0)
	srli	t1, t1, 8
	sd	t1, bcb_accumulator(t0)
	jalr	x0, 0(ra)

; Goto!

eatG:
	; Jumping to a routine will replace all 32 GPRs.
	; This includes our stack pointer and return address!
	; The only reliable way to "return" to the debugger is
	; the SBREAK instruction or by JALing to $2004.
	; 
	; IMPLEMENTATION DETAIL:
	; 
	; Until we have a proper supervisor mode, we cannot
	; reload all 32 GPRs as indicated above; we need one
	; left over as a base register pointing to the userRegs
	; structure.  
	; 
	; We use S11 because it's so high up in the S-register space
	; that we feel it generally won't be used much.  This is an
	; assumption of course, and we all know how well assumptions
	; work out for people.

	or	s11, x0, t0
	ld	x1, bcb_userRegs+8(s11)
	ld	x2, bcb_userRegs+16(s11)
	ld	x3, bcb_userRegs+24(s11)
	ld	x4, bcb_userRegs+32(s11)
	ld	x5, bcb_userRegs+40(s11)
	ld	x6, bcb_userRegs+48(s11)
	ld	x7, bcb_userRegs+56(s11)
	ld	x8, bcb_userRegs+64(s11)
	ld	x9, bcb_userRegs+72(s11)
	ld	x10, bcb_userRegs+80(s11)
	ld	x11, bcb_userRegs+88(s11)
	ld	x12, bcb_userRegs+96(s11)
	ld	x13, bcb_userRegs+104(s11)
	ld	x14, bcb_userRegs+112(s11)
	ld	x15, bcb_userRegs+120(s11)
	ld	x16, bcb_userRegs+128(s11)
	ld	x17, bcb_userRegs+136(s11)
	ld	x18, bcb_userRegs+144(s11)
	ld	x19, bcb_userRegs+152(s11)
	ld	x20, bcb_userRegs+160(s11)
	ld	x21, bcb_userRegs+168(s11)
	ld	x22, bcb_userRegs+176(s11)
	ld	x23, bcb_userRegs+184(s11)
	ld	x24, bcb_userRegs+192(s11)
	ld	x25, bcb_userRegs+200(s11)
	ld	x26, bcb_userRegs+208(s11)
;	ld	x27, bcb_userRegs+216(s11)    Don't overload S11 until SBREAK is supported.
	ld	x28, bcb_userRegs+224(s11)
	ld	x29, bcb_userRegs+232(s11)
	ld	x30, bcb_userRegs+240(s11)
	ld	x31, bcb_userRegs+248(s11)

	ld	s11, bcb_accumulator(s11)
	jalr	x0, 0(s11)

; Compute user-mode register address in memory

eatX:
	andi	t1, t1, 31		; Extract register select bits
	slli	t1, t1, 3		; ...*8 since regs are 64-bits
	add	t1, t1, t0		; ...plus BCB base address
	addi	t1, t1, bcb_userRegs	; ...plus offset of regs array = address of register
	sd	t1, bcb_accumulator(t0)	; Pretend user entered this address directly.
	ld	t2, bcb_startAddr(t0)	; If start address not given, ...
	ori	t3, x0, -1
	bne	t2, t3, doneX
	andi	t1, t1, -8		; ...then specify it here.
	sd	t1, bcb_startAddr(t0)

doneX:
	jalr	x0, 0(ra)

; 
; Print newline
; 

newline:
	ori	a0, x0, 10
	jal	x0, biosPutChar

; 
; Print out hexadecimal numbers of various widths.  These must appear
; immediately before bios_putchar (or else, adjust the puthex4 routine to jump
; to bios_putchar).
; 

puthex64:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	s0, 8(sp)

	or	s0, x0, a0
	srli	a0, a0, 32
	jal	ra, puthex32

	or	a0, x0, s0
	ld	s0, 8(sp)
	ld	ra, 0(sp)
	addi	sp, sp, 16

puthex32:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	s0, 8(sp)

	or	s0, x0, a0
	srli	a0, a0, 16
	jal	ra, puthex32

	or	a0, x0, s0
	ld	s0, 8(sp)
	ld	ra, 0(sp)
	addi	sp, sp, 16

puthex16:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	s0, 8(sp)

	or	s0, x0, a0
	srli	a0, a0, 8
	jal	ra, puthex32

	or	a0, x0, s0
	ld	s0, 8(sp)
	ld	ra, 0(sp)
	addi	sp, sp, 16

puthex8:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	s0, 8(sp)

	or	s0, x0, a0
	srli	a0, a0, 4
	jal	ra, puthex32

	or	a0, x0, s0
	ld	s0, 8(sp)
	ld	ra, 0(sp)
	addi	sp, sp, 16

puthex4:
	andi	a0, a0, 15

	; The following instruction replaces a more complex instruction
	; sequence, but it only works if hexTable sits below 2K in ROM.
	; If we didn't know ahead of time where hexTable sat, we'd need this:
	; 
	; auipc	 x31,0
	; ld     t3,_addr_hexTable
	; add	 a0,a0,t3
	; lb	 a0,0(a0)

	lb	a0, hexTable(a0)

	; fall through to biosPutChar

; 
; BIOS Character Services
; 

; Print a single character to the user's console.
;
; biosPutChar(ch)
;             A0

biosPutChar:
	ld	t0, brod_uartBase(x0)
	sb	a0, UART_TX(t0)
	jalr	x0, 0(ra)


; Print a counted string to the user's console.
; This routine makes no attempt to interpret terminal control codes.
;
; biosPutStrC(strp, strlen)
;              A0     A1

biosPutStrC:
	addi	sp, sp, -16
	sd	s0, 0(sp)
	sd	ra, 8(sp)
	or	s0, x0, a0

biosPutStrC_loop:
	beq	a1, x0, biosPutStrC_done
	lbu	a0, 0(s0)
	jal	ra, biosPutChar
	addi	s0, s0, 1
	addi	a1, a1, -1
	jal	x0, biosPutStrC_loop

biosPutStrC_done:
	ld	ra, 8(sp)
	ld	s0, 0(sp)
	addi	sp, sp, 16
	jalr	x0, 0(ra)

; Print a zero-terminated string to the user's console.
; This routine makes no attempt to interpret terminal control codes.
;
; biosPutStrZ(strp)
;              A0

biosPutStrZ:
	addi	sp, sp, -16
	sd	s0, 0(sp)
	sd	ra, 8(sp)
	ori	s0, a0, 0

biosPutStrZ_loop:
	lbu	a0, 0(s0)
	beq	x0, a0, biosPutStrZ_rtn
	jal	ra, biosPutChar
	addi	s0, s0, 1
	jal	x0, biosPutStrZ_loop

biosPutStrZ_rtn:
	ld	ra, 8(sp)
	ld	s0, 0(sp)
	addi	sp, sp, 16
	jalr	x0, 0(ra)


; Check to see if a key has been pressed.
; Returns non-zero if the debug port has data waiting.
; Returns zero otherwise.
;
; flag = biosChkChar()
;  A0

biosChkChar:
	ld	t1, brod_uartBase(x0)	; t1 -> UART base
	lbu	a0, UART_STATUS(t1)	; data pending?
	andi	a0, a0, 1
	jalr	x0, 0(ra)


; Get a character.  This function will block until data becomes available.
;
; ch = biosGetChar()
; A0

biosGetChar:
	ld	t1, brod_uartBase(x0)	; t1 -> UART
biosGetChar_again:
	lbu	a0, UART_STATUS(t1)	; wait for data
	beq	x0, a0, biosGetChar_again
	lbu	a0, UART_RX(t1)		; grab the next available byte
	jalr	x0, 0(ra)


; Get a line of text from the user's console.
; This routine is genuinely very basic.  It's intended for bootstrapping
; purposes only.
; 
; Takes a pointer to a Line Input Control Block.  You are responsible for
; initializing the control block prior to calling this procedure.
; The Buffer field must point to the input buffer.  The Capacity field must
; contain the maximum size of the buffer.  Unless you know exactly what you're
; doing, you will want to set the Length field to zero.
; 
; Upon return from this procedure, the Length field will contain the number of
; valid bytes in the buffer.  Note that this procedure WILL NOT null-terminate
; the buffer contents.  If this is important for your purposes, you'll need to
; manually terminate the buffer yourself.
;
; biosGetLine(licb)
;              A0

biosGetLine:
	addi	sp, sp, -16
	sd	ra, 0(sp)
	sd	s0, 8(sp)
	or	s0, x0, a0

waitForKey:
	jal	ra, biosChkChar
	beq	x0, a0, waitForKey
	jal	ra, biosGetChar

	ld	t2, blicb_length(s0)

	; If the user presses ENTER, we accept the buffer as-is.
	; It's up to the consumer to check for zero-length buffers.
	addi	t3, x0, 10
	bne	a0, t3, notCR

	ld	s0, 8(sp)
	ld	ra, 0(sp)
	addi	sp, sp, 16
	jalr	x0, 0(ra)

	; If backspace, and buffer non-empty, back up one space.
notCR:
	ori	t3, x0, 127
	beq	a0, t3, BSorDEL
	ori	t3, x0, 8
	bne	a0, t3, notBS

BSorDEL:
	beq	x0, t2, waitForKey

	addi	t2, t2, -1
	sd	t2, blicb_length(s0)

	auipc	a0, 0		; print bs, space, bs
	addi	a0, a0, 12
	jal	ra, biosPutStrZ
	jal	x0, waitForKey
	byte	8, 32, 8, 0

	; Ignore key press if there's no room to place it.
notBS:
	ld	t3, blicb_capacity(s0)
	beq	t2, t3, waitForKey

	; Place the byte, and increment the buffer length.
	ld	t3, blicb_buffer(s0)
	add	t3, t3, t2
	sb	a0, 0(t3)
	addi	t2, t2, 1
	sd	t2, blicb_length(s0)
	jal	ra, biosPutChar
	jal	x0, waitForKey

