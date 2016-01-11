; Contents of a data file, /rom/m2.slides .

start_img_rocket_chip_site:
	incbin	"img.rocket-chip-site.bin"
end_img_rocket_chip_site:

; This code is not normally part of an application.  It exists only
; to overcome limitations with BSPL's ability to include an address
; of a symbol literally.

	align	8
i_start_img_rocket_chip_site:
	dword	rombase+start_img_rocket_chip_site
img_rocket_chip_site_start:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_start_img_rocket_chip_site-img_rocket_chip_site_start(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)

	align	8
i_len_img_rocket_chip_site:
	dword	end_img_rocket_chip_site-start_img_rocket_chip_site
img_rocket_chip_site_len:
	auipc	gp, 0
	addi	dsp, dsp, -8
	ld	x16, i_len_img_rocket_chip_site-img_rocket_chip_site_len(gp)
	sd	x16, 0(dsp)
	jalr	x0, 0(ra)
