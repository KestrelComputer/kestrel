; The CPU jumps unconditionally to one of the TRAP_FROM_x addresses whenever an
; interrupt or exception occurs.  Which vector the CPU uses depends on which
; operating mode it was operating in at the time the trap was taken.

DEFAULT_TRAP_BASE       = $FFFFFFFFFFFFFE00
TRAP_FROM_U             = $00
TRAP_FROM_S             = $40
TRAP_FROM_H             = $80
TRAP_FROM_M             = $C0

; The Polaris CPU always starts execution at this address after hard reset.
; The MTVEC CSR will be set to DEFAULT_TRAP_BASE by default.

RESET_BASE              = $FFFFFFFFFFFFFF00

