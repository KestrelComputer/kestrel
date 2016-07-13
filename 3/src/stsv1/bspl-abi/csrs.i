; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

; Configuration and Status Registers.
; Note: Not all registers may be implemented in hardware.
; Not all registers may be implemented in the emulator either.
; Always consult mcpuid and mimpid for supported features.

; Machine-Mode CSRs

misa		= $F10
mvendorid	= $F11
marchid		= $F12
mimpid		= $F13
mhartid		= $F14

mstatus         = $300
medeleg         = $302
midelet		= $303
mie             = $304
mtvec           = $305

mscratch        = $340
mepc            = $341
mcause          = $342
mbadaddr        = $343
mip             = $344

mbase           = $380
mbound          = $381
mibase          = $382
mibound         = $383
mdbase          = $384
mdbound         = $385

mcycle		= $F00
mtime           = $F01
minstret	= $F02

mtohost         = $780
mfromhost       = $781

