0 constant x0
1 constant x1
2 constant x2
3 constant x3
4 constant x4


       0 x2 auipc
   x2 16 x3 lw
   x0 65 x4 addi
    x4 x3 0 sb
      -8 x0 jal
  $0F000000 w,

