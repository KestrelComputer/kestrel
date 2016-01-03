; Contents of a data file, /rom/m2.slides .

start_m2slidesRV3:
	incbin	"m2.slides.riscv.3"
end_m2slidesRV3:

; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_m2slidesRV3:
	dword	rombase+start_m2slidesRV3
prg_m2slidesRV3_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_m2slidesRV3-prg_m2slidesRV3_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

	align	8
i_len_m2slidesRV3:
	dword	end_m2slidesRV3-start_m2slidesRV3
prg_m2slidesRV3_len:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_len_m2slidesRV3-prg_m2slidesRV3_len(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)
