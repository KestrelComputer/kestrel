; Contents of a data file, /rom/m2.slides .

start_m2slides:
	incbin	"m2.slides"
end_m2slides:

; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_m2slides:
	dword	rombase+start_m2slides
prg_m2slides_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_m2slides-prg_m2slides_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

	align	8
i_len_m2slides:
	dword	end_m2slides-start_m2slides
prg_m2slides_len:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_len_m2slides-prg_m2slides_len(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)
