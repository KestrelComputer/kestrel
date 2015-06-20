	include	"cpu/csrs.i"
	include "cpu/regs.i"
	include "cpu/ngregs.i"
	include "debugio.i"
	include "bios.i"
	include	"zp.i"

ngaro:	include	"ngaro.asm"

	align	4
retroImage:
	include "retroImage.i"
retroImageSize = *-retroImage

	adv	$F0000, $CC
	include "mlm.asm"
	jal	x0, ngaro

