; DX-Forth Copy Loop
; Copyright (c) 2017-2019 Samuel A. Falvo II
; See LICENSE file in this or nearest parent directory.
;
; V1.1 : 2018-??-??
; Initial release for Kestrel-3/E2.
; BIOS dependency removed; DX-Forth *is* the new BIOS.
;
; This code takes control immediately after the CPU boots.
; Because the Kestrel-3's ROM is so slow (40+ cycles overhead
; per fetch!), and because the Forth environment was designed
; to be loaded into RAM for the Kestrel-2DX originally,
; this loop exists to migrate the contents of DX-Forth in ROM
; into RAM for final execution.

	include	"regs.i"
	include "dxforth.regs.i"


	; This is the cold-boot entry point of the KCP53K
	; family of processors.  Our task is to copy the
	; DX-Forth image to its final resting place in RAM.
	; Then, jump into RAM to start the DX-Forth image.
_bios_entry:
	auipc	gp,0		; GP := 0, basically.
	lw	a0,_n1-_bios_entry(gp)
	lw	a1,_n2-_bios_entry(gp)
	lw	a2,_n3-_bios_entry(gp)

_bios_copy:
	ld	a3,0(a0)
	sd	a3,0(a2)
	addi	a0,a0,8
	addi	a2,a2,8
	blt	a0,a1,_bios_copy

_bios_boot:
	lw	D,_n3-_bios_entry(gp)
	jalr	x0,0(D)

_n1:	word	_start
_n2:	word	_end
_n3:	word	$40000000

	; This is the official starting image of the DX-Forth
	; program image.  This jump instruction will appear
	; at $40000000 if all goes according to plan, and this
	; will then cause DX-Forth to launch.
_start:
	incbin	"dxforth-image.bin"
_end:
