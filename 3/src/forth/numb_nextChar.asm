; Get the next character in the word to convert.

numbNextChar:  ld      a0, zpWordStart(x0)
               ld      a1, zpWordIndex(x0)
               add     a0, a0, a1
               lb      a0, 0(a0)
               jalr    x0, 0(rt)

; Advance to the next character in the word.

numbEatChar:   ld      a0, zpWordIndex(x0)
               ld      a1, zpWordLength(x0)
               bgeu    a0, a1, nEC0
               addi    a0, a0, 1
               sd      a0, zpWordIndex(x0)
nEC0:          jalr    x0, 0(rt)


