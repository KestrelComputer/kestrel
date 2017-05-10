; Contents of a data file, /rom/m2.slides .

start_m2slidesR:
	incbin	"m2.slides.report"
end_m2slidesR:

; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_m2slidesR:
	dword	rombase+start_m2slidesR
prg_m2slidesR_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_m2slidesR-prg_m2slidesR_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

	align	8
i_len_m2slidesR:
	dword	end_m2slidesR-start_m2slidesR
prg_m2slidesR_len:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_len_m2slidesR-prg_m2slidesR_len(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)
