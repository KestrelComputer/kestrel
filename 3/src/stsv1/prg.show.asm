; Show -- slurp in 38400 bytes from a file and put it into the framebuffer.
;
; Uses prefix shw.


rombase = $FFFFFFFFFFF00000

shwFH		= 0		; File handle / SCB
shwRSP		= 8		; OS RSP
shwDSP		= 16		; OS DSP
shwStsBase	= 24		; STS jump table address

	include	"stsapi.inc"

; Start of Milestone-2 port.

	align	8
start_show:
	jalr	x0, 0(x1)
	word	0		; Padding to preserve 64-bit alignment
	jal	x0, shwStart

shwStart:	addi	rsp, rsp, -8
		sd	ra, 0(rsp)

		jal	ra, shwData
		ld	dr16, 0(dsp)
		sd	dr16, shwStsBase(dr23)
		sd	rsp, shwRSP(dr23)
		sd	dsp, shwDSP(dr23)

		; skip leading spaces to filename

		ld	dr16, 40(dsp)	; filename length
		ld	dr17, 48(dsp)	; pointer to filename
shwSkSpc:	beq	dr16, x0, shwOpen
		lbu	dr18, 0(dr17)
		addi	dr19, x0, 33
		bgeu	dr18, dr19, shwOpen
		addi	dr17, dr17, 1
		addi	dr16, dr16, -1
		jal	x0, shwSkSpc

		; If we cannot open the file, then just exit.

shwOpen:	addi	dsp, dsp, -16
		sd	dr17, 8(dsp)
		sd	dr16, 0(dsp)
		ld	dr16, shwStsBase(dr23)
		jalr	ra, STS_OPEN(dr16)
		ld	dr16, 0(dsp)
		bne	dr16, x0, shwQuit
		jal	ra, shwData
		ld	dr16, 8(dsp)
		sd	dr16, shwFH(dr23)

		; Otherwise, read the file directly into the frame buffer.

		addi	dsp, dsp, -24
		sd	dr16, 0(dsp)		; SCB

		addi	dr16, x0, 480		; of length 38400
		slli	dr16, dr16, 3		; 480*8 = 3840
		slli	dr17, dr16, 2		; 5*3840 = 19200
		add	dr16, dr16, dr17
		slli	dr16, dr16, 1		; 19200*2 = 38400
		sd	dr16, 8(dsp)

		addi	dr16, x0, 255		; buffer at $FF0000
		slli	dr16, dr16, 16
		sd	dr16, 16(dsp)

		jal	ra, shwData
		ld	dr16, shwStsBase(dr23)
		jalr	ra, STS_READ(dr16)

		; Close the file.

		addi	dsp, dsp, -8
		jal	ra, shwData
		ld	dr16, shwFH(dr23)
		sd	dr16, 0(dsp)
		ld	dr16, shwStsBase(dr23)
		jalr	ra, STS_CLOSE(dr16)

		; Wait for the user to press a key.  Any will do.

shwWait:

		; Return to STS

shwQuit:	jal	ra, shwData
		ld	dsp, shwDSP(dr23)
		ld	rsp, shwRSP(dr23)
		ld	ra, 0(rsp)
		addi	rsp, rsp, 8
		jalr	x0, 0(ra)

		align	8
		addi	x0, x0, 0
shwData:	jalr	dr23, 0(ra)
		dword	0, 0, 0, 0
		dword	0, 0, 0, 0
		dword	0, 0, 0, 0
		dword	0, 0, 0, 0

; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_show:
	dword	rombase+start_show
prg_show_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	dr16, i_start_show-prg_show_start(gp)
	sd	dr16, 0(dsp)
	jalr	x0, 0(ra)

	align	8
i_len_show:
	dword	end_show-start_show
prg_show_len:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	dr16, i_len_show-prg_show_len(gp)
	sd	dr16, 0(dsp)
	jalr	x0, 0(ra)

end_show:
