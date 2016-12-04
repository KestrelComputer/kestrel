; Configuration and Status Registers.
; Note: Not all registers may be implemented in hardware.
; Always consult mcpuid and mimpid for supported features.

; Machine-Mode CSRs

misa		= $F10
mvendorid	= $F11
marchid		= $F12
mimpid		= $F13
mhartid		= $F14

mstatus         = $300
medeleg         = $302
mideleg		= $303
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

