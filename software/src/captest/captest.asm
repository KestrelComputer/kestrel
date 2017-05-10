; This program attempts to determine how big of a memory segment the Kestrel-3
; has reserved for it, without knowing much hardware-specific details ahead of
; time.  What it does know is that, per the standard Kestrel-3 memory map,
; RAM appears between $00000000_00000000 and $00FFFFFF_FFFFFFFF.  How much RAM
; is actually supported in actual hardware will depend on the specific
; implementation of the machine.
;
; To assemble:
;
; a from captest.asm to captest.bin
;
; To program into FPGA:
;
; bin2v from captest.bin to captest.hex bytes 2 byteswap
; (then use ISE and/or djtgcfg to program the appropriate chip.)


; CPU register assignments
; There's nothing special about these register assignments.
; If you're planning on porting this code to run in a larger project,
; it's best to remove these definitions and rely on the same register
; bindings as the rest of the software.

x0		= 0
ra		= 1
sp		= 2
gp		= 3
a0		= 4
a1		= 5
a2		= 6
a3		= 7
a4		= 8
a5		= 9
a6		= 10
a7		= 11

; Global 64-bit variables:
; Check value
g_chkval	= 0

; Known memory capacity
g_memcap	= g_chkval+8

; Frame buffer pointer
g_frmbuf	= g_memcap+8


; Global 80-byte Structures:
; Line format buffer
g_linbuf	= g_frmbuf+8

; Global 2KB Structures (read-only)
; Font
g_font		= g_linbuf+80

font:		include "font.asm"

; Constants:
; Where to find our global variables.
G_GP0		= $0000000000000010

; Where to place our runtime stack.
G_SP0		= $0000000000010000

; Where the MGIA frame buffer resides in memory
G_FRMBUF	= $0000000000010000

; Minimum memory allotment we can detect.
G_MINMEM	= 256

; Where ROM appears in the computer's memory map.
G_ROMADR	= $FFFFFFFFFFF00000

; Where to advance in ROM image to find trap handler.
G_MTVEC0	= $FFE00

; Where to advance in ROM image to find reset handler.
G_RESET0	= $FFF00


; Create a new value to store(new value):
; LET new value be the previous value shifted left 8 places, ORed with low byte of previous value plus 1.
newchk:		ld	a0, g_chkval(gp)
		slli	a1, a0, 8
		addi	a2, a0, 1
		andi	a2, a2, 255
		or	a1, a1, a2
		sd	a1, g_chkval(gp)
		jalr	x0, 0(ra)

; We continue to find RAM(capacity):
; Create a new value to store(check value).
ramfnd:		addi	sp, sp, -8
		sd	ra, 0(sp)
		jal	ra, newchk

; Store value at capacity limit.
		ld	a0, g_chkval(gp)
		ld	a1, g_memcap(gp)
		sd	a0, 0(a1)

; IF value at location 0 matches our new value THEN
		ld	a2, 0(x0)
		bne	a0, a2, rf1

; We reached RAM's end; FALSE.
		addi	a0, x0, 0
		jal	x0, rfend

; ELSE
; We have not reached capacity yet; TRUE.
rf1:		addi	a0, x0, 1

; END
rfend:		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)

; We haven't exhausted maximum possible capacity(capacity):
; IF capacity < 2^56 THEN
rammax:		addi	a1, x0, 1
		slli	a1, a1, 56
		ld	a0, g_memcap(gp)
;	TRUE.
; ELSE
;	FALSE.
		slt	a0, a0, a1
; END
		jalr	x0, 0(ra)

; Find the largest supported capacity:
fndcap:		addi	sp, sp, -8
		sd	ra, 0(sp)

; Store check value at location 0.
		ld	a0, g_chkval(gp)
		sd	a0, 0(x0)

; IF location 0 does not match the check value THEN
		ld	a1, 0(x0)
		beq	a0, a1, fc1

; Assume no RAM exists.
		addi	a0, x0, 0
		sd	a0, g_memcap(gp)
		jal	x0, fcend

; ELSE
; Assume at least one dword of RAM capacity.
fc1:		addi	a0, x0, G_MINMEM
		sd	a0, g_memcap(gp)

; WHILE we continue to find RAM(capacity) AND we haven't exhausted maximum possible capacity(capacity) DO
fc2:		jal	ra, rammax
		beq	a0, x0, fc3
		jal	ra, ramfnd
		beq	a0, x0, fc3

; Double the known memory capacity.
		ld	a0, g_memcap(gp)
		slli	a0, a0, 1
		sd	a0, g_memcap(gp)

; END
		jal	x0, fc2
fc3:

; IF we've exhausted the largest possible memory capacity, THEN
; Assume a full compliment of RAM.
; END
; END
fcend:		ld	ra,0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)


; Convert a single digit:
digit:
;	LET dword BE dword rotated left by four bits.
		slli	a2, a0, 4
		srli	a0, a0, 60
		or	a0, a0, a2

;	Mask off bottom four bits.
		andi	a2, a0, 15

;	Convert to ASCII
		addi	a3, x0, 10
		blt	a2, a3, d1
		addi	a2, a2, 7
d1:		addi	a2, a2, $30

;	Store character in format buffer.
		sb	a2, 0(a1)
		addi	a1, a1, 1
		jalr	x0, 0(ra)


; Print the largest capacity supported:
prtcap:		addi	sp, sp, -8
		sd	ra, 0(sp)

;	Prepare 80-column format buffer.
		addi	a0, gp, g_linbuf
		addi	a1, a0, 80
		addi	a2, x0, 32
pc0:		bge	a0, a1, pc1
		sb	a2, 0(a0)
		addi	a0, a0, 1
		jal	x0, pc0

;	Copy "Largest Detected Memory Capacity: $0000000000000000 to $" to buffer.
pc1:		auipc	a0, 0
		addi	a0, a0, pcmsg-pc1
		addi	a1, gp, g_linbuf
pc2:		lbu	a2, 0(a0)
		beq	a2, x0, pc3
		sb	a2, 0(a1)
		addi	a0, a0, 1
		addi	a1, a1, 1
		jal	x0, pc2
			
;	Convert memory capacity (minus 1) into hexadecimal in the format buffer.
pc3:		ld	a0, g_memcap(gp)
		addi	a0, a0, -1
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit
		jal	ra, digit

;	Print the format buffer.
		ld	ra, 0(sp)
		addi	sp, sp, 8

		; fall through

; Print the format buffer:
prtfmt:
;	Start with the top-most font raster.
		ld	a0, g_font(gp)

;	Start at the current frame buffer position.
		ld	a1, g_frmbuf(gp)

;	FOR all raster rows in font DO
		addi	a7, a0, 1024
		addi	a7, a7, 1024
pf0:		bge	a0, a7, pf1

;	  Start at beginning of format buffer.
		addi	a2, gp, g_linbuf

;	  FOR all characters in the format buffer DO
		addi	a6, a2, 80
pf2:		bge	a2, a6, pf3

;		Map current character code to glyph byte.
		lbu	a3, 0(a2)
		add	a3, a3, a0
		lbu	a3, 0(a3)
			
;		Store byte into corresponding frame buffer byte.
		sb	a3, 0(a1)

;		Advance format buffer and frame buffer references.
		addi	a1, a1, 1
		addi	a2, a2, 1

;	  END
		jal	x0, pf2
pf3:
;	  Advance to the next raster.
		addi	a0, a0, 256

;	END
		jal	x0, pf0
pf1:
pf1b:		jalr	x0, 0(ra)

pcmsg:		byte	"Largest Detected Memory Capacity: $0000000000000000 to $",0
		align	4

; Initialize:
init:

;	Start at top-left corner of the screen.
i0:		auipc	a0, 0
		ld	a0, i_frmbuf-i0(a0)
		sd	a0, g_frmbuf(gp)

;	Clear the screen.
		addi	a1, x0, 1024
		addi	a1, a1, 1024
i1:		sd	x0, 0(a0)
		addi	a0, a0, 8
		addi	a1, a1, -1
		bne	a1, x0, i1

;	Initialize check value to '1111111111111111'X.
i2:		auipc	a0, 0
		ld	a0, i_chkval-i2(a0)
		sd	a0, g_chkval(gp)

;	Initialize font.
i3:		auipc	a0, 0
		ld	a0, i_font-i3(a0)
		sd	a0, g_font(gp)

		jalr	x0, 0(ra)

		align	8
i_frmbuf:	dword	G_FRMBUF
i_chkval:	dword	$1111111111111111
i_font:		dword	font + G_ROMADR

; Main Program:
		adv	G_MTVEC0, $CC
		jal	x0, *

		adv	G_RESET0, $CC
m0:		auipc	gp, 0
		ld	sp, sp0-m0(gp)
		ld	gp, gp0-m0(gp)

;	Initialize.
		jal	ra, init


;	Find the largest supported capacity.
		jal	ra, fndcap

;	Print the largest capacity supported.
		jal	ra, prtcap

;	Halt.
		jal	x0, *

		align	8
sp0:		dword	G_SP0
gp0:		dword	G_GP0

		adv	$100000,$CC

