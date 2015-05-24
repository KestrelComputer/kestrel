; The two stacks are laid out in upper RAM, keeping them both well away from
; each other and from the main dictionary.
;
; They each cover a range [lboundXX, uboundXX).

uboundRS        = $0000000001000000
lboundRS        = $000000000F000000
uboundDS        = $000000000F000000
lboundDS        = $000000000E000000

