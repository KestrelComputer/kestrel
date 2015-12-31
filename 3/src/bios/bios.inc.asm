; Kestrel-3 BIOS (Basic Input/Output System)
; Copyright (C) 2015 Samuel A. Falvo II
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

; CPU Register Definitions

 x0 =  0
 x1 =  1
 x2 =  2
 x3 =  3
 x4 =  4
 x5 =  5
 x6 =  6
 x7 =  7
 x8 =  8
 x9 =  9
x10 = 10
x11 = 11
x12 = 12
x13 = 13
x14 = 14
x15 = 15
x16 = 16
x17 = 17
x18 = 18
x19 = 19
x20 = 20
x21 = 21
x22 = 22
x23 = 23
x24 = 24
x25 = 25
x26 = 26
x27 = 27
x28 = 28
x29 = 29
x30 = 30
x31 = 31

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


; BIOS ABI Register Roles.
;
; The BIOS ABI conforms to the preliminary specification
; as documented on page 3 (PDF) or page 91 (book) of
; https://blog.riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf

zero = x0	; Hardwired to zero.
ra   = x1	; Return Address
sp   = x2	; Stack Pointer
gp   = x3	; Globals Pointer
tp   = x4	; Thread-local Storage Pointer
t0   = x5	; Temporaries; callee may modify at will.
t1   = x6
t2   = x7
s0   = x8	; Saved; callee must preserve before using.
s1   = x9
a0   = x10	; Arguments; callee may modify at will.
a1   = x11
a2   = x12
a3   = x13
a4   = x14
a5   = x15
a6   = x16
a7   = x17
s2   = x18	; Saved.
s3   = x19
s4   = x20
s5   = x21
s6   = x22
s7   = x23
s8   = x24
s9   = x25
s10  = x26
s11  = x27
t3   = x28	; Temporaries.
t4   = x29
t5   = x30
t6   = x31

; BIOS_BASE is the physical address at which the BIOS image starts in
; the Kestrel-3's memory map.

BIOS_BASE		= $FFFFFFFFFFF00000

; DEFAULT_TRAP_BASE is the physical address where BIOS expects its ROM-
; resident interrupt and trap vectors to reside.  This value is loaded
; into the mtvec CSR upon cold boot, and is expected to stick.

DEFAULT_TRAP_BASE       = $FFFFFFFFFFFFFE00

; The CPU jumps unconditionally to one of the TRAP_FROM_x addresses whenever
; an interrupt or exception occurs.  Which vector the CPU uses depends on
; which operating mode it was operating in at the time the trap was taken.

TRAP_FROM_U             = $00
TRAP_FROM_S             = $40
TRAP_FROM_H             = $80
TRAP_FROM_M             = $C0

; If the CPU supports non-maskable interrupts, the CPU will jump unconditionally
; to TRAP_NMI.  Note that NMIs are always handled in machine mode.

TRAP_NMI		= $FC

; The Polaris CPU always starts execution at this address after hard reset.
; The MTVEC CSR will be set to DEFAULT_TRAP_BASE by default.  RISC-V CPUs
; which boot from low memory are incompatible with this BIOS unless a
; trampoline can bounce control to high memory.

RESET_BASE              = $FFFFFFFFFFFFFF00

; BIOS stores a pointer to its jump table at physical address 8.

BIOS_JUMPTAB		= 8

; BIOS call offsets to the jump table.

BIOS_CANOUT		= 0
BIOS_CHROUT		= 4
BIOS_STROUT		= 8
BIOS_I_STROUT		= 12
BIOS_CANINP		= 16
BIOS_CHRINP		= 20
