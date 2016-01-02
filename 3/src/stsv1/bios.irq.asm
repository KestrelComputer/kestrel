; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.


irq_spur_a2:	jalr	a2, 0(ra)
irq_spurtrap:	addi	a0, x0, 0
		jal	ra, bios_i_strout
		byte	"PANIC: Spurious interrupt or trap ",0
		align	4
		addi	a0, x0, 0
		csrrc	a1, x0, mcause
		jal	ra, bios_hex64out
		addi	a0, x0, 0
		jal	ra, bios_i_strout
		byte	".", 13, 10, "PANIC: BIOS halting.",0
		align	4
		jal	x0, *

