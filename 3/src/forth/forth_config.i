; The two stacks are laid out in upper RAM, keeping them both well away from
; each other and from the main dictionary.
;
; They each cover a range [lboundXX, uboundXX).

uboundRS        = $0000000001000000
lboundRS        = $0000000000F00000
uboundDS        = $0000000000F00000
lboundDS        = $0000000000E00000

