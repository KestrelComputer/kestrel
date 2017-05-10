; This procedure multiplies two signed or unsigned 64-bit integers to
; yield a 128-bit result.  A0 and A1 hold the multiplicands on entry.
; On exit, A1 holds the most significant partial product, and A0 holds
; the least-significant partial product.
; 
; This routine can be made ever-so-slightly faster if you don't preserve
; the temporary registers; however, this will break Ngaro, and I'm not
; motivated to fix the register dependency issues.  Besides, if you
; really want performance, replace this routine with a CPU `mul` and `mulhi`
; instruction pair.

mathMultiply:   addi    sp, sp, -48
                sd      ra, 0(sp)
                sd      t0, 8(sp)
                sd      t1, 16(sp)
                sd      t2, 24(sp)
                sd      t3, 32(sp)              ; Scratch register.
                sd      t4, 40(sp)

                ori     t0, a1, 0               ; Sign-extend A0 into T4:T0
                srli    t4, a1, 63
                xori    t4, t4, -1
                addi    t4, t4, 1

                ori     t1, a0, 0               ; Sign-extend A1 into T2:T1
                srli    t2, a0, 63
                xori    t2, t2, -1
                addi    t2, t2, 1

                ori     a0, x0, 0               ; Start with zero product
                ori     a1, x0, 0

m_m_again:      bne     t4, x0, *+8             ; If no more 1 bits left in the
                beq     t0, x0, m_m_done        ;    multiplicand, stop early.

                andi    t3, t0, 1               ; If multiplicand odd,
                beq     t3, x0, m_m_even        ;    accumulate partial product.
                add     a0, a0, t1
                add     a1, a1, t2
                bgeu    a0, t1, m_m_even
                addi    a1, a1, 1

m_m_even:       srli    t0, t0, 1               ; Divide T4:T0 by two.
                slli    t3, t4, 63
                or      t0, t0, t3
                srli    t4, t4, 1

                slli    t2, t2, 1               ; Multiply T2:T1 by two.
                srli    t3, t1, 63
                or      t2, t2, t3
                slli    t1, t1, 1

                jal     x0, m_m_again           ; Repeat until we're done.

m_m_done:       ld      ra, 0(sp)
                ld      t0, 8(sp)
                ld      t1, 16(sp)
                ld      t2, 24(sp)
                ld      t3, 32(sp)
                ld      t4, 40(sp)
                addi    sp, sp, 48
                jalr    x0, 0(ra)


; This procedure performs a 128-bit by 64-bit unsigned division.  Upon
; entry, A1:A0 holds the 128-bit numerator, and A2 holds the denominator.
; Upon exit, A1 holds the remainder, and A0 the quotient.
;
; I use the long-division algorithm as documented in the eponymous Wikipedia
; article.

mathUDivMod:    addi    sp, sp, -48
                sd      ra, 0(sp)
                sd      a2, 8(sp)
                sd      t0, 16(sp)
                sd      t1, 24(sp)
                sd      t2, 32(sp)
                sd      t3, 40(sp)

                addi    t0, x0, 0               ; Quotient
                addi    t1, x0, 0               ; Remainder
                addi    t3, x0, 128             ; Our input (A1:A0) has 128 bits
mUDM0:          beq     t3, x0, mUDM1           ; While we have bits to process...

                slli    t1, t1, 1               ; Shift R:N as a 192-bit quantity left 1 bit
                srli    t2, a1, 63              ; (multiplies by two)
                or      t1, t1, t2
                slli    a1, a1, 1
                srli    t2, a0, 63
                or      a1, a1, t2
                slli    a0, a0, 1

                slli    t0, t0, 1               ; Shift quotient left by 1 too.
                bltu    t1, a2, mUDM2           ; If we can subtract, then
                sub     t1, t1, a2              ;    Perform subtraction off of remainder.
                ori     t0, t0, 1               ;    Account for it in the quotient.

mUDM2:          addi    t3, t3, -1              ;  Repeat for all bits.
                jal     x0, mUDM0

mUDM1:          ori     a0, t0, 0
                ori     a1, t1, 0
                ld      ra, 0(sp)
                ld      a2, 8(sp)
                ld      t0, 16(sp)
                ld      t1, 24(sp)
                ld      t2, 32(sp)
                ld      t3, 40(sp)
                addi    sp, sp, 48
                jalr    x0, 0(ra)


; This procedure performs a 128-bit by 64-bit signed division.
; Upon entry, A1:A0 holds the 128-bit numerator, while A2 holds the
; denominator.  Upon exit, A1 holds the signed remainder, while A0 holds the
; signed quotient.
; 
; I use the same algorithm as that documented in the eponymous article on
; Wikipedia.  A simple test shows the following results:
;
;         N     D        R       Q
;       A1:A0   A2      A1'     A0'
;       ==========      ===========
;        -45    -8      -5       5
;        -45     8       3      -6
;         45    -8      -3      -6
;         45     8       5       5
;       ==========      ===========
;
; I confirmed this behavior matches the behavior of 64-bit GForth 0.7.0 under
; MacOS X.
;
; This behavior differs from C-based Ngaro VM implementations, and is most
; likely a bug for doing so.  This is what a C-compatible implementation
; would return:
;
;         N     D        R       Q
;       A1:A0   A2      A1'     A0'
;       ==========      ===========
;        -45    -8      -5       5
;        -45     8      -5      -5
;         45    -8       5      -5
;         45     8       5       5
;       ==========      ===========
;
; I will need to discuss this with @crcx to determine if this is an
; acceptable ambiguity, or if I should actually have full compliance here.
; The code is easy enough to change to match C-style semantics, but I'd
; prefer to use Forth-style semantics since that's what everyone familiar with
; Forth will come to expect from an RPN language.

mathSDivMod:    addi    sp, sp, -56
                sd      ra, 0(sp)
                sd      a1, 8(sp)               ; preserve sign of numerator
                sd      a2, 16(sp)              ; preserve sign of denominator
                sd      t0, 24(sp)
                sd      t1, 32(sp)
                sd      t2, 40(sp)
                sd      t3, 48(sp)

                bge     a1, x0, mSDM_a1pos      ; Take absolute value of A1:A0
                xori    a1, a1, -1
                xori    a0, a0, -1
                addi    a0, a0, 1
                bgeu    a0, x0, mSDM_a1pos	; BUG? We want to carry when roll over to 0,
                addi    a1, a1, 1		; not when we're still negative.

mSDM_a1pos:     bge     a2, x0, mSDM_a2pos      ; Take absolute value of A2
                xori    a2, a2, -1
                addi    a2, a2, 1

mSDM_a2pos:     jal     ra, mathUDivMod         ; perform the core division

                ld      t0, 8(sp)               ; t0[63] = sign of numerator
                ld      t1, 16(sp)              ; t1[63] = sign of denominator
                addi    t2, x0, 0               ; t2 = final remainder

                xor     t3, t0, t1              ; If sgn(num) != sgn(denom)
                bge     t3, x0, mSDM_signok     ;   then adjust results.
                xori    a0, a0, -1              ; negate and subtract one.
                add     t2, t2, t1              ; adjust remainder.

mSDM_signok:    bge     t0, x0, mSDM_dpos       ; If num < 0, negate remainder.
                xori    a1, a1, -1
                addi    a1, a1, 1

mSDM_dpos:      add     t2, t2, a1              ; accumulate final remainder
                ori     a1, t2, 0

                ld      ra, 0(sp)
                ld      a2, 16(sp)
                ld      t0, 24(sp)
                ld      t1, 32(sp)
                ld      t2, 40(sp)
                ld      t3, 48(sp)
                addi    sp, sp, 56
                jalr    x0, 0(ra)

