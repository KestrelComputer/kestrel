; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;
; This implements the BIOS Jump Table.

bios_jumptab:	jalr	a0, 0(ra)
		jal	x0, mgia_canout		; bios_canout
		jal	x0, mgia_chrout		; bios_chrout
		jal	x0, bios_strout
		jal	x0, bios_i_strout
