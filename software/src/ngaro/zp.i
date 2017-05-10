; "Zero-page" memory locations.  The first portion is copied from ROM into ZP
; RAM for easy access.

zp_uartBase	= 0
zp_initSP	= zp_uartBase+8
zp_initTable	= zp_initSP+8
zp_userRegs	= zp_initTable+8
zp_inpIndex	= zp_userRegs+32*8	; Reserving space for X0 avoids special-case logic.
zp_accumulator	= zp_inpIndex+8
zp_startAddr	= zp_accumulator+8
zp_licb		= zp_startAddr+8
zp_keyPress	= zp_licb+blicb_sizeof
zp_inpBuf	= zp_keyPress+1
zp_sizeof	= zp_inpBuf+81


