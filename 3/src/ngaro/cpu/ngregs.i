; Ngaro-specific Register usage

; sp = x2
; gp = x3
; tp = x4
; t0 = x5
; t1 = x6
; t2 = x7
; s0 = x8
; s1 = x9
; a0 = x10
; a1 = x11
; a2 = x12
; a3 = x13
; a4 = x14
; a5 = x15
; a6 = x16
; a7 = x17
; s2 = x18
; s3 = x19
; s4 = x20
; s5 = x21
; s6 = x22
; s7 = x23

dbase = x24	; Pointer to bottom of data stack
abase = x25	; Pointer to bottom of address stack
ap = x26	; Address stack Pointer
dp = x27	; Data stack Pointer
dt = x28	; Top of Data Stack cache
vport = x29	; Pointer to virtual I/O port vector
vbase = x30	; Pointer to virtual machine memory image
vip = x31	; Virtual instruction pointer.

