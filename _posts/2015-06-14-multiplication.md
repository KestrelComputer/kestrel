---
layout: post
title:  "Stepwise Refinement of an Event-Driven Forth Interpreter Part 3: Multiplication"
date:   2015-06-14 19:30:00
---

<blockquote>“Life is good for only two things, discovering mathematics and teaching mathematics.”
&mdash; <a href="http://izquotes.com/quote/146953">Simeon Poisson</a></blockquote>

In the previous installment of this journey,
I'd basically proven (informally) the correctness of the *design* for Forth's outer interpreter.
Along the way, I performed some additional refinements,
while glossing over others.
One of those refinements that I glossed over was how to accumulate digits into a single number.

Accumulation of digits into a complete number is actually pretty simple:
you first multiply what you have already by the base, then add the new stuff.
I'll quickly walk through the code I've written so far.

First, we need to get the next character from the token being converted:

                        jal     rt, numbNextChar
                        ori     t1, a0, 0
                        jal     rt, numbEatChar

We check to make sure the value falls within our current base setting.
For brevity, I don't properly account for hexadecimal or higher bases.
Just assume that it "magically" works for now.

                        addi    t1, t1, -48
                        ld      a1, zpBase(x0)
                        bltu    t1, a1, nTUN1

If we discover a character which doesn't qualify as a digit,
we mark its location and early-exit from the procedure.

                        ld      a0, zpWordIndex(x0)
                        addi    a0, a0, -1
                        sd      a0, zpWordIndex(x0)
                        jal     x0, nTUN0

Otherwise, we "accumulate" the digit.
Note that register `A1` will already contain our base value from the check above.
We invoke a multiplication subroutine because the (first-generation) Polaris CPU definition for Kestrel-3 explicitly lacks support for multiplication.
I made this decision specifically to ease hardware implementation and verification.
I'll add multiplication support later, once I have the rest of the CPU implementation working.
In the mean time, we need to emulate it in software:

        nTUN1:          ld      a0, zpValue(x0)
                        jal     rt, math_multiply
                        add     a0, a0, t1
                        sd      a0, zpValue(x0)
                        jal     x0, nTUN2

In various unit tests, I stub out `math_multiply` as needed.
Now it's time to define our requirements for `math_multiply`.

## Multiplication Requirements

This procedure is going to be somewhat different from the rest,
in that I'm using CPU registers instead of memory-resident variables for communication.
Specifically, registers `A0` and `A1` hold our input multiplicands.
Looking at the code above, we also see that `A0` holds the least significant 64 bits of the result as well.
We also cannot change any other register.

Strictly speaking,
I don't need to add support for signed multiplication.
As you can see from the pseudo-code in the previous two parts,
numeric conversion always happens with unsigned numbers (sign is applied only after conversion of the unsigned part of the number).
However, I would like this routine to be re-used to implement the `*` and `*/` operators in Forth.
Thus, I'll consider sign up front.

Also, because I'm aiming to support `*/` out of the box,
the result of the multiplication should be a full, 128-bit product.
In other words, `A0` holds the least-significant 64 bits of the product, while `A1` holds the most significant.

## Algorithm

As it happens, signed and unsigned multiplication is the same algorithm.
You can check this out yourself using any ANSI or Forth-83 compatible Forth system:

        -5 -3 UM* DROP .  15 OK
        -5  3 UM* DROP .  -15 OK
         5 -3 UM* DROP .  -15 OK
         5  3 UM* DROP .  15 OK
        _

Indeed, if you look at Bill Muench's EForth, he [explicitly defines](https://github.com/hagna/eforth/blob/master/doc/EFORTH.ASM#L856) `*` as `UM* DROP`.

Thus, we need only concern ourselves with the needs of performing 128-bit arithmetic on a 64-bit RISC architecture without a carry bit.  :)
I choose to use the [Russian Peasant's Algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm#Peasant_or_binary_multiplication).

        PROCEDURE Multiply(A0, A1): QWORD
                Save registers.
                Sign-extend A1 into T4:T0.
                Sign-extend A0 into T2:T1.
                Set product in A1:A0 to 0.
                WHILE T0 is not zero DO
                        IF T0 is odd THEN
                                Add T2:T1 into product.
                        END
                        Shift T4:T0 right by 1 logically.
                        Shift T2:T1 left by 1 logically.
                END.
                Restore registers.
                RETURN product.

I won't bother proving the correctness of this algorithm; I suspect several hundred to several thousand years of use has done an adequate job of that.
Instead, I want to focus on finer-grained details of the algorithm.

### Sign-extending to a 128-bit number

We sign-extend our inputs to 128-bits to ensure mathematically correct results.
Both inputs are so extended; however, below, we illustrate the process for only one parameter.
The process is the same for the other; only the choice of registers differs.

First, we realize that the lower 64 bits remains intact, so we simply preserve them as-is.

        Move A0 to T1.

To perform the sign-extension, however, I compute either 0 for positive, and 1 for negative, then negate this value, giving me either 0 or -1.
As it happens, the choice of 0 or 1 matches the binary value of bit 63 of A0.
So, I simply shift bits around, like so.

        Shift top bit of A0 into T2.
        Negate T2.

If bit 63 of `A0` is zero, then negating zero in `T2` should yeild zero.
Otherwise, if bit 63 of `A0` is one, then `T2` will be set to negative one.
In this way, `T2` properly sign-extends `A0`.

Being a RISC-V processor, Polaris can do this without destroying the value in `A0`.

        ori     t1, a0, 0
        srli    t2, a0, 63
        xori    t2, t2, -1
        addi    t2, t2, 1

### 128-bit Addition

Addition of two quad-words is perhaps a bit non-obvious at first, but it's actually fairly easy to do.
We start by performing a carry-save addition of the two 64-bit halves.
Then, we fix the result up by manually propegating any pending carry.

        Add low words together.
        Add high words together.
        Propegate carry.

We propegate carry like so:

        IF low result is less than the low half of an addend, THEN
                Add 1 to the top half of the result.
        END

In assembly language, this translates to:

        add     a0, a0, t1
        add     a1, a1, t2
        bgeu    a0, t1, *+8
        addi    a1, a1, 1

If you pretend the registers are only 6 or 8 bits wide, you can easily confirm this implementation works.

### Shifting 128 Bits Left or Right by One Bit

We need to shift our addend left by one bit, and the multiplicand right by one bit.
Problem is, each of these are 128-bit quantities, and Polaris is only a 64-bit CPU without a carry flag.

We use a combination of shifts and logical operators to treat this as a bit-field access problem.
For example, to shift to the addend left one bit, we need to first make room for incoming bits:

        slli    t2, t2, 1

We then take whatever is in bit 63 of the lower word and place it at bit 0, to be logically-ORed with the recently vacated bit 0 in the high word:

        srli    t3, t1, 63
        or      t2, t2, t3

Finally, shift the low word accordingly.

        slli    t1, t1, 1

We take the same approach for the multiplicand, but in the opposite direction:

        srli    t0, t0, 1
        slli    t3, t4, 63
        or      t0, t0, t3
        srli    t4, t4, 1

## Implementation

I now list the implementation of the multiplication routine, as of this writing.
I've changed some of the registers around to reduce the cognative load of the reader, and to ease debugging effort.

I'll elide tests in this blog post, but check the repo (look for `src/forth/test_math.asm` and its related files).

        math_multiply:  addi    rp, rp, -48
                        sd      rt, 0(rp)
                        sd      t0, 8(rp)
                        sd      t1, 16(rp)
                        sd      t2, 24(rp)
                        sd      t3, 32(rp)
                        sd      t4, 40(rp)

                        ori     t0, a1, 0               ; 128-bit control multiplacand
                        srli    t4, a1, 63
                        xori    t4, t4, -1
                        addi    t4, t4, 1

                        ori     t1, a0, 0               ; 128-bit partial sum multiplacand
                        srli    t2, a0, 63
                        xori    t2, t2, -1
                        addi    t2, t2, 1

                        ori     a0, x0, 0               ; Zero product
                        ori     a1, x0, 0

        m_m_again:      bne     t4, x0, *+8
                        beq     t0, x0, m_m_done        ; Complete when no more 1 bits exist.
                        andi    t3, t0, 1               ; Multiplicand odd?
                        beq     t3, x0, m_m_even
                        add     a0, a0, t1              ; Yes, perform 128-bit partial addition.
                        add     a1, a1, t2
                        bgeu    a0, t1, m_m_even
                        addi    a1, a1, 1

        m_m_even:       srli    t0, t0, 1
                        slli    t3, t4, 63
                        or      t0, t0, t3
                        srli    t4, t4, 1

                        slli    t2, t2, 1
                        srli    t3, t1, 63
                        or      t2, t2, t3
                        slli    t1, t1, 1

                        jal     x0, m_m_again

        m_m_done:       ld      rt, 0(rp)
                        ld      t0, 8(rp)
                        ld      t1, 16(rp)
                        ld      t2, 24(rp)
                        ld      t3, 32(rp)
                        ld      t4, 40(rp)
                        addi    rp, rp, 48
                        jalr    x0, 0(rt)

Happily, this implementation actually gets computation of the upper 64 bits correct.
If you test `UM*` on a 64-bit GForth 0.7 version under Linux, you'll find that the high 64 bits take on bizarre values.

        -5 -3 UM* . .  -8 15 OK
        -5  3 UM* . .  4 -15 OK
         5 -3 UM* . .  2 -15 OK
         5  3 UM* . .  0 15 OK

## Conclusion

The core of the multiplication loop would be far simpler and faster if we restricted our math to just 64-bits.
However, Forth's support for the `*/` operator requires double-width products.
The code above provides correct results for both signed and unsigned inputs.

Eventually, when Polaris supports actual multiply instructions, this whole piece of code disappears, replaced with:

        mul     a0, xa, xb
        mulhi   a1, xa, xb

Until that happens, though, this code will need to suffice.

