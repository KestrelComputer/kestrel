;**************************************************************
; Kestrel-3 Machine Language Monitor
; Release 0.4
;**************************************************************

	include	"cpu/csrs.i"
	include "cpu/regs.i"
	include "debugio.i"

; BIOS Line Input Control Block (BLICB)

blicb_buffer	= 0
blicb_length	= blicb_buffer+8
blicb_capacity	= blicb_length+8
blicb_sizeof	= blicb_capacity+8

; "Zero-page" memory locations.  The first portion is copied from ROM into ZP
; RAM for easy access.

zp_uartBase	= 0
zp_gpiaBase	= zp_uartBase+8
zp_initSP	= zp_gpiaBase+8
zp_initTable	= zp_initSP+8
zp_userRegs	= zp_initTable+8
zp_inpIndex	= zp_userRegs+32*8	; Reserving space for X0 avoids special-case logic.
zp_accumulator	= zp_inpIndex+8
zp_startAddr	= zp_accumulator+8
zp_licb		= zp_startAddr+8
zp_keyPress	= zp_licb+blicb_sizeof
zp_inpBuf	= zp_keyPress+1
zp_sizeof	= zp_inpBuf+81


; Cold Reset Entrypoint.
;
; We start with a NOP to let the RA register point to initTable after the JAL
; instruction completes.  Otherwise, we'd need to account for the alignment
; through other, perhaps not as obvious, methods.

coldBoot:
	or	x0,x0,x0
	jal	ra, coldInit

	; BIOS Read-Only Data structure goes here.

initTable:
	dword	$0E00000000000000
	dword	$0100000000000000
	dword	$0000000000010000

banner:
	byte	"MLM/K3 V0.4", 10
bannerLength = *-banner

code0msg:	byte	"INSN ADDR AT       "
code1msg:	byte	"INSN ACCESS AT     "
code2msg:	byte	"ILLEGAL INSN AT    "
code3msg:	byte	"BREAK AT           "
code4msg:	byte	"LOAD ADDR AT       "
code5msg:	byte	"LOAD ACCESS AT     "
code6msg:	byte	"STORE ADDR AT      "
code7msg:	byte	"STORE ACCESS AT    "
code8msg:	byte	"ECALL FROM U AT    "
code9msg:	byte	"ECALL FROM S AT    "
codeAmsg:	byte	"ECALL FROM H AT    "
codeBmsg:	byte	"ECALL FROM M AT    "
codeCmsg:	byte	"UNKNOWN TRAP 0C AT "
codeDmsg:	byte	"UNKNOWN TRAP 0D AT "
codeEmsg:	byte	"UNKNOWN TRAP 0E AT "
codeFmsg:	byte	"UNKNOWN TRAP 0F AT "

b=$FFFFFFFFFFF00000

		align	8
codeMsgTab:	dword	code0msg+b, code1msg+b, code2msg+b, code3msg+b
		dword	code4msg+b, code5msg+b, code6msg+b, code7msg+b
		dword	code8msg+b, code9msg+b, codeAmsg+b, codeBmsg+b
		dword	codeCmsg+b, codeDmsg+b, codeEmsg+b, codeFmsg+b

codeMsgLen = code1msg - code0msg

mlmPrompt:
	byte	"* "

hexTable:
	byte	"0123456789ABCDEF"

spDotSp:
	byte	" . "

	align	4
coldInit:
	sd	ra,zp_initTable(x0)
	ld	t0,0(ra)		; T0 = UART base
	sd	t0,zp_uartBase(x0)
	ld	t0,8(ra)		; T0 = GPIA base
	sd	t0,zp_gpiaBase(x0)
	ld	t0,16(ra)		; T0 = initial SP
	sd	t0,zp_initSP(x0)
	or	sp,x0,t0
	ebreak				; Enter monitor.

	addi	a0,x0,42
	jal	ra,biosPutChar

brkEntry:
	; Save user register state.

	sd	x1, zp_userRegs+8(x0)
	sd	x2, zp_userRegs+16(x0)
	sd	x3, zp_userRegs+24(x0)
	sd	x4, zp_userRegs+32(x0)
	sd	x5, zp_userRegs+40(x0)
	sd	x6, zp_userRegs+48(x0)
	sd	x7, zp_userRegs+56(x0)
	sd	x8, zp_userRegs+64(x0)
	sd	x9, zp_userRegs+72(x0)
	sd	x10, zp_userRegs+80(x0)
	sd	x11, zp_userRegs+88(x0)
	sd	x12, zp_userRegs+96(x0)
	sd	x13, zp_userRegs+104(x0)
	sd	x14, zp_userRegs+112(x0)
	sd	x15, zp_userRegs+120(x0)
	sd	x16, zp_userRegs+128(x0)
	sd	x17, zp_userRegs+136(x0)
	sd	x18, zp_userRegs+144(x0)
	sd	x19, zp_userRegs+152(x0)
	sd	x20, zp_userRegs+160(x0)
	sd	x21, zp_userRegs+168(x0)
	sd	x22, zp_userRegs+176(x0)
	sd	x23, zp_userRegs+184(x0)
	sd	x24, zp_userRegs+192(x0)
	sd	x25, zp_userRegs+200(x0)
	sd	x26, zp_userRegs+208(x0)
	sd	x27, zp_userRegs+216(x0)
	sd	x28, zp_userRegs+224(x0)
	sd	x29, zp_userRegs+232(x0)
	sd	x30, zp_userRegs+240(x0)
	sd	x31, zp_userRegs+248(x0)
	csrrs	a0, x0, mstatus
	sd	a0, zp_userRegs(x0)

	ld	sp, zp_initSP(x0)
	ld	gp, zp_initTable(x0)

	addi	a0, gp, banner-initTable
	addi	a1, x0, bannerLength
	jal	ra, biosPutStrC

	csrrw	a1, x0, mcause
	slli	a1, a1, 3
	addi	a0, gp, codeMsgTab-initTable
	add	a0, a0, a1
	ld	a0, 0(a0)
	addi	a1, x0, codeMsgLen
	jal	ra, biosPutStrC
	csrrw	a0, x0, mepc
	jal	ra, puthex64
	addi	a0, x0, 10
	jal	ra, biosPutChar

doItAgain:
	sd	x0, zp_accumulator(x0)
	addi	t1, x0, -1
	sd	t1, zp_startAddr(x0)

	addi	a0, gp, mlmPrompt-initTable
	addi	a1, x0, 2
	jal	ra, biosPutStrC

	; Reset the line input buffer control block, and get the line of text.

	addi	a0, x0, zp_licb		; A0 -> MLM BLICB structure
	addi	t2, x0, zp_inpBuf
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

	addi	t1, x0, zp_licb		; t1 -> BIOS' BLICB
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
	ld	t1, zp_accumulator(x0)	; t1 = current accumulator

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
	sd	t1, zp_accumulator(x0)
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

	ld	s0, zp_startAddr(x0)	; start address for dump
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
	ld	t6, zp_initTable(x0)
	addi	a0, t6, spDotSp-initTable
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
	sd	t1, zp_startAddr(x0)
	sd	x0, zp_accumulator(x0)
	jalr	x0, 0(ra)

; Store a byte into memory.

eatComma:
	ld	t2, zp_startAddr(x0)
	sb	t1, 0(t2)
	addi	t2, t2, 1
	sd	t2, zp_startAddr(x0)
	srli	t1, t1, 8
	sd	t1, zp_accumulator(x0)
	jalr	x0, 0(ra)

; Goto!

eatG:
	; Jumping to a routine will replace all 32 GPRs.
	; This includes our stack pointer and return address!
	; The only reliable way to "return" to the debugger is
	; the EBREAK instruction.
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

	ld	x1, zp_accumulator(x0)
	csrrw	x0, x1, mepc

	ld	x1, zp_userRegs(x0)
	csrrw	x0, x1, mstatus

	ld	x1, zp_userRegs+8(x0)
	ld	x2, zp_userRegs+16(x0)
	ld	x3, zp_userRegs+24(x0)
	ld	x4, zp_userRegs+32(x0)
	ld	x5, zp_userRegs+40(x0)
	ld	x6, zp_userRegs+48(x0)
	ld	x7, zp_userRegs+56(x0)
	ld	x8, zp_userRegs+64(x0)
	ld	x9, zp_userRegs+72(x0)
	ld	x10, zp_userRegs+80(x0)
	ld	x11, zp_userRegs+88(x0)
	ld	x12, zp_userRegs+96(x0)
	ld	x13, zp_userRegs+104(x0)
	ld	x14, zp_userRegs+112(x0)
	ld	x15, zp_userRegs+120(x0)
	ld	x16, zp_userRegs+128(x0)
	ld	x17, zp_userRegs+136(x0)
	ld	x18, zp_userRegs+144(x0)
	ld	x19, zp_userRegs+152(x0)
	ld	x20, zp_userRegs+160(x0)
	ld	x21, zp_userRegs+168(x0)
	ld	x22, zp_userRegs+176(x0)
	ld	x23, zp_userRegs+184(x0)
	ld	x24, zp_userRegs+192(x0)
	ld	x25, zp_userRegs+200(x0)
	ld	x26, zp_userRegs+208(x0)
	ld	x27, zp_userRegs+216(x0)
	ld	x28, zp_userRegs+224(x0)
	ld	x29, zp_userRegs+232(x0)
	ld	x30, zp_userRegs+240(x0)
	ld	x31, zp_userRegs+248(x0)
	eret

; Compute user-mode register address in memory

eatX:
	andi	t1, t1, 31		; Extract register select bits
	slli	t1, t1, 3		; ...*8 since regs are 64-bits
	addi	t1, t1, zp_userRegs	; ...plus offset of regs array = address of register
	sd	t1, zp_accumulator(x0)	; Pretend user entered this address directly.
	ld	t2, zp_startAddr(x0)	; If start address not given, ...
	ori	t3, x0, -1
	bne	t2, t3, doneX
	andi	t1, t1, -8		; ...then specify it here.
	sd	t1, zp_startAddr(x0)

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
	jal	ra, puthex16

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
	jal	ra, puthex8

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
	jal	ra, puthex4

	or	a0, x0, s0
	ld	s0, 8(sp)
	ld	ra, 0(sp)
	addi	sp, sp, 16

puthex4:
	andi	a0, a0, 15
	ld	t6, zp_initTable(x0)
	add	a0, a0, t6
	lb	a0, hexTable-initTable(a0)

	; fall through to biosPutChar

; 
; BIOS Character Services
; 

; Print a single character to the user's console.
;
; biosPutChar(ch)
;             A0

biosPutChar:
	ld	t0, zp_uartBase(x0)
	sb	a0, UART_TX(t0)

	; just some quick testing code for the emulator.
	ori	t0, a0, 0		; T0 = ~A0<<8 | A0
	xori	t0, t0, 255
	slli	t0, t0, 8
	or	t0, t0, a0

	ld	t1, zp_gpiaBase(x0)	; select the slave device
	lb	t2, 8(t1)
	andi	t2, t2, $FF1
	sb	t2, 8(t1)

	ori	t3, x0, 16

bPC0:	srli	t4, t0, 13		; Merge in a bit
	andi	t4, t4, 4
	lb	t2, 8(t1)
	andi	t2, t2, $FFB
	or	t2, t2, t4
	sb	t2, 8(t1)

	ori	t2, t2, $008		; pulse the clock
	sb	t2, 8(t1)
	andi	t2, t2, $FF7
	sb	t2, 8(t1)

	slli	t0, t0, 1		; Shift our bits.

	addi	t3, t3, -1
	bne	t3, x0, bPC0

	ori	t3, x0, 8		; Pulse clock 8 more times
bPC1:	ori	t2, t2, $008
	sb	t2, 8(t1)
	andi	t2, t2, $FF7
	sb	t2, 8(t1)
	addi	t3, t3, -1
	bne	t3, x0, bPC1

	ori	t2, t2, $002		; Turn off device
	sb	t2, 8(t1)

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
	ld	t1, zp_uartBase(x0)	; t1 -> UART base
	lbu	a0, UART_STATUS(t1)	; data pending?
	andi	a0, a0, 1
	jalr	x0, 0(ra)


; Get a character.  This function will block until data becomes available.
;
; ch = biosGetChar()
; A0

biosGetChar:
	ld	t1, zp_uartBase(x0)	; t1 -> UART
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
	add	t3, t2, t3
	sb	a0, 0(t3)
	addi	t2, t2, 1
	sd	t2, blicb_length(s0)
	jal	ra, biosPutChar
	jal	x0, waitForKey

;
; CPU Vectors
;

	adv	$FFE00, $CC	; User -> Machine trap
	jal	x0, brkEntry
	adv	$FFE40, $CC	; Supervisor -> Machine trap
	jal	x0, brkEntry
	adv	$FFE80, $CC	; Hypervisor -> Machine trap
	jal	x0, brkEntry
	adv	$FFEC0, $CC	; Machine -> Machine trap
	jal	x0, brkEntry
	adv	$FFEFC, $CC	; NMI
	jal	x0, brkEntry
	jal	x0, coldBoot	; Reset Vector

