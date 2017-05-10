; This integration test confirms that the Forth outer interpreter works.
; We pass in a command line and let the oint module interpret it.  This
; involves invoking words, pushing numeric literals in different formats,
; etc.
; 
; If this works, then invoking oint repeatedly is the key to making an
; interactive Forth environment.


		include	"../asrt.i"
		include "../oint.asm"
		include "../scan.asm"
		include	"../dict.asm"
		include	"../numb.asm"
		include	"../err.asm"
		include	"../dstk.asm"
		include	"../char.asm"
		include	"../math.asm"


nam_add:	byte	"+"
len_add		= *-nam_add

nam_xor:	byte	"xor"
len_xor		= *-nam_xor

		align	8

hdr_add:	dword	romBase+hdr_xor, romBase+nam_add, len_add
cod_add:	ld	t0, 0(dp)
		addi	dp, dp, 8
		add	dt, dt, t0
		jalr	x0, 0(rt)

hdr_xor:	dword	0, romBase+nam_xor, len_xor
cod_xor:	ld	t0, 0(dp)
		addi	dp, dp, 8
		xor	dt, dt, t0
		jalr	x0, 0(rt)

ointGetAndInterpretLine:
errReport:	jalr	x0, 0(rt)

dictIsWordFound:
		ld	a0, zpWordFound(x0)
		jalr	x0, 0(rt)

dictLocateWord:	addi	rp, rp, -8
		sd	rt, 0(rp)
		ld	a0, zpWordStart(x0)
		ld	a1, zpWordLength(x0)
		jal	rt, dictFindWord
		sd	a0, zpWordFound(x0)
		sd	a0, zpWordBody(x0)
		beq	a0, x0, dLW
		addi	a0, a0, wh_sizeof
		sd	a0, zpWordBody(x0)
dLW:		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(rt)


		align	8
		byte	"OINTDICT"
testOintDict:	addi	rp, rp, -8
		sd	rt, 0(rp)
		addi	t0, x0, 10
		sd	t0, zpBase(x0)
tOD_LGP0:	auipc	gp, 0
		addi	t0, gp, hdr_add-tOD_LGP0
		sd	t0, zpContext(x0)
		addi	t0, gp, tOD_cmdline-tOD_LGP0
		sd	t0, zpLineBuffer(x0)
		addi	t0, x0, tOD_cmdline_len
		sd	t0, zpLineLength(x0)
		jal	rt, ointInterpretLine

		addi	a0, dt, 0
		addi	a1, x0, $1234 / 4
		slli	a1, a1, 2
		jal	rt, asrtEquals

		ld	rt, 0(rp)
		addi	rp, rp, 8
		jalr	x0, 0(ra)

tOD_cmdline:	byte	"512 $1000 + 52 xor"
tOD_cmdline_len	= *-tOD_cmdline

		align	4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	1
		dword	romBase+testOintDict

		include	"../asrt.asm"
