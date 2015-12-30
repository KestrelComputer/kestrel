; BIOS Data Area.

bd_tag		= 0			; D BIOS Data Format tag ($B105)
bd_bitplane	= bd_tag + 8		; D Pointer to MGIA framebuffer.
bd_planesz	= bd_bitplane + 8	; D Size of said framebuffer, bytes.

bd_cx		= bd_planesz + 8	; H Cursor X position
bd_cy		= bd_cx + 2		; H Cursor Y position
bd_maxcol	= bd_cy + 2		; H Maximum number of columns (typ. 80)
bd_maxrow	= bd_maxcol+2		; H Maximum number of rows (typ. 60)

bd_planebw	= bd_maxrow+2		; H Width of bitmap in bytes
bd_planeh	= bd_planebw+2		; H Height of bitmap in pixels
bd_padding0	= bd_planeh+2		; H reserved.
bd_padding1	= bd_padding0+2		; H reserved.

bd_fontform	= bd_padding1+4		; D Pointer to system font image.
