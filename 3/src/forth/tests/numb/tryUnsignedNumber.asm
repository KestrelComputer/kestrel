setvecs:	sd	a0, zpV(x0)
		jalr	x0, 0(ra)

setWord:	sd	a0, zpWordStart(x0)
		sd	a1, zpWordLength(x0)
		jalr	x0, 0(ra)

; If we attempt to convert a zero-length string to a number,
; we expect a zero value in the accumulator.  Software which
; is sensitive to "" not being a valid number is expected to
; check the length ahead of calling any numb* functions.

numb0len_setWord:
		addi	a1, x0, 0
		jal	x0, setWord

		byte	"NUMB0LEN"
testNumb0Length:
		sd	ra, zpTestPC(x0)
		addi	a0, x0, 10
		sd	a0, zpBase(x0)
		sd	a0, zpValue(x0)
		sd	x0, zpWordIndex(x0)
		jal	ra, numb0len_setWord
		jal	ra, numbTryUnsignedNumber
		ld	a0, zpBase(x0)
		addi	a1, x0, 10
		jal	ra, asrtEquals
		ld	a0, zpValue(x0)
		jal	ra, asrtIsZero
		ld	a0, zpWordIndex(x0)
		jal	ra, asrtIsZero
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; When we attempt to convert an unconvertable character, we need to know where it's located in the string.


numbuncv_setvecs:
		jal	a0, setvecs
		jal	x0, numbuncv_mathMultiply

numbuncv_mathMultiply:
		addi	rp, rp, -16
		sd	rt, 0(rp)
		sd	a0, 8(rp)
		ori	a0, a1, 0
		addi	a1, x0, 10
		jal	rt, asrtEquals

		ld	a0, 8(rp)	; A0 = 10*A0
		slli	t0, a0, 2
		add	a0, a0, t0
		slli	a0, a0, 1

		ld	rt, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)


numbuncv_setWord:
		addi	a1, x0, numbuncv_wordlen
		jal	a0, setWord
numbuncv_word:	byte	"123g456"
numbuncv_wordlen = *-numbuncv_word
		align	4

		byte	"NUMBUNCV"
testNumbUnconvertable:
		sd	ra, zpTestPC(x0)
		jal	ra, numbuncv_setvecs
		addi	a0, x0, 10
		sd	a0, zpBase(x0)
		sd	x0, zpWordIndex(x0)
		jal	ra, numbuncv_setWord
		jal	ra, numbTryUnsignedNumber
		ld	a0, zpWordIndex(x0)
		addi	a1, x0, 3
		jal	ra, asrtEquals
		ld	a0, zpValue(x0)
		addi	a1, x0, 123
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; When converting a number that is valid, we expect the accumulator to reflect the corresponding value.

numbconv_setvecs:
		jal	a0, setvecs
		jal	x0, numbconv_mathMultiply

numbconv_mathMultiply:
		addi	rp, rp, -16
		sd	rt, 0(rp)

		slli	t0, a0, 2
		add	a0, a0, t0
		slli	a0, a0, 1

		ld	rt, 0(rp)
		addi	rp, rp, 16
		jalr	x0, 0(rt)


numbconv_setWord:
		addi	a1, x0, numbconv_wordlen
		jal	a0, setWord
numbconv_word:	byte	"123456"
numbconv_wordlen = *-numbconv_word
		align	4

tNC0:		word	123456
		byte	"NUMBCONV"
testNumbConvertable:
		sd	ra, zpTestPC(x0)
tNC1:		auipc	gp, 0
		jal	ra, numbconv_setvecs
		addi	a0, x0, 10
		sd	a0, zpBase(x0)
		sd	x0, zpWordIndex(x0)
		jal	ra, numbconv_setWord
		jal	ra, numbTryUnsignedNumber
		ld	a0, zpWordIndex(x0)
		addi	a1, x0, 6
		jal	ra, asrtEquals
		ld	a0, zpValue(x0)
		lw	a1, tNC0-tNC1(gp)
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; When converting a number that is valid, we expect the accumulator to reflect the corresponding value.

numbhexupper_setvecs:
		jal	a0, setvecs
		jal	x0, numbhexupper_mathMultiply

numbhexupper_mathMultiply:
		slli	a0, a0, 4
		jalr	x0, 0(rt)


numbhexupper_setWord:
		addi	a1, x0, numbhexupper_wordlen
		jal	a0, setWord
numbhexupper_word:	byte	"DEADBEEFFEEDFACE"
numbhexupper_wordlen = *-numbhexupper_word
		align	8

tHCU0:		dword	$DEADBEEFFEEDFACE
		byte	"NUMBHCNV"
testNumbUpperHex:
		sd	ra, zpTestPC(x0)
tHCU1:		auipc	gp, 0
		jal	ra, numbhexupper_setvecs
		addi	a0, x0, 16
		sd	a0, zpBase(x0)
		sd	x0, zpWordIndex(x0)
		jal	ra, numbhexupper_setWord
		jal	ra, numbTryUnsignedNumber
		ld	a0, zpWordIndex(x0)
		addi	a1, x0, 16
		jal	ra, asrtEquals
		ld	a0, zpValue(x0)
		ld	a1, tHCU0-tHCU1(gp)
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

; When converting a number that is valid, we expect the accumulator to reflect the corresponding value.

numbhexlower_setvecs:
		jal	a0, setvecs
		jal	x0, numbhexlower_mathMultiply

numbhexlower_mathMultiply:
		slli	a0, a0, 4
		jalr	x0, 0(rt)


numbhexlower_setWord:
		addi	a1, x0, numbhexlower_wordlen
		jal	a0, setWord
numbhexlower_word:	byte	"deadbeeffeedface"
numbhexlower_wordlen = *-numbhexlower_word
		align	8

tHCL0:		dword	$DEADBEEFFEEDFACE
		byte	"NUMBLCNV"
testNumbLowerHex:
		sd	ra, zpTestPC(x0)
tHCL1:		auipc	gp, 0
		jal	ra, numbhexlower_setvecs
		addi	a0, x0, 16
		sd	a0, zpBase(x0)
		sd	x0, zpWordIndex(x0)
		jal	ra, numbhexlower_setWord
		jal	ra, numbTryUnsignedNumber
		ld	a0, zpWordIndex(x0)
		addi	a1, x0, 16
		jal	ra, asrtEquals
		ld	a0, zpValue(x0)
		ld	a1, tHCL0-tHCL1(gp)
		jal	ra, asrtEquals
		ld	ra, zpTestPC(x0)
		jalr	x0, 0(ra)

