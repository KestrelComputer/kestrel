; Contents of a data file, /rom/m2.slides .

start_img_kestrel:
	incbin	"img.kestrel.bin"
end_img_kestrel:

; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_img_kestrel:
	dword	rombase+start_img_kestrel
img_kestrel_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_img_kestrel-img_kestrel_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

	align	8
i_len_img_kestrel:
	dword	end_img_kestrel-start_img_kestrel
img_kestrel_len:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_len_img_kestrel-img_kestrel_len(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)
