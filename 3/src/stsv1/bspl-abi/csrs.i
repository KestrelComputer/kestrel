; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

; Configuration and Status Registers.
; Note: Not all registers may be implemented in hardware.
; Not all registers may be implemented in the emulator either.
; Always consult mcpuid and mimpid for supported features.

; Machine-Mode CSRs

mcpuid          = $F00
mimpid          = $F01
mhartid         = $F10
mstatus         = $300
mtvec           = $301
mtdeleg         = $302
mie             = $304
mtimecmp        = $321
mtime           = $701
mtimeh          = $741
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
htimew          = $B01
htimehw         = $B81
mtohost         = $780
mfromhost       = $781

; Hypervisor-Mode CSRs

hstatus         = $200
htvec           = $201
htdeleg         = $202
htimecmp        = $221
htime           = $E01
htimeh          = $E81
hscratch        = $240
hepc            = $241
hcause          = $242
hbadaddr        = $243
stimew          = $A01
stimehw         = $A81

; Supervisor-Mode CSRs

sstatus		= $100
stvec		= $101
sie		= $104
stimecmp	= $121
stime		= $D01
stimeh		= $D81
sscratch	= $140
sepc		= $141
scause		= $D42
sbadaddr	= $D43
sip		= $144
sptbr		= $180
sasid		= $181
cyclew		= $900
timew		= $901
instretw	= $902
cyclehw		= $980
timehw		= $981
instrethw	= $982

; User-Mode CSRs

fflags          = $001
frm             = $002
fcsr            = $003
cycle           = $C00
time            = $C01
instret         = $C02
cycleh          = $C80
timeh           = $C81
instreth        = $C82

