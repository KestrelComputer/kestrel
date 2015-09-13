 align 8
  dword $0E00000000000000
emit:
 ld    x16 , 0(dsp)
 addi  dsp, dsp, 8
LGP1 :
 auipc gp, 0
 ld    x17 , (emit-LGP1 )-8 (gp)
 sb    x16 , 0(x17 )
 jalr  x0, 0(ra)
 align 8
  dword $0000000000000001
  dword $0000000000000001
nextch:
 ld    x16 , 0(dsp)
 addi  dsp, dsp, 8
 ld    x17 , 0(dsp)
 addi  dsp, dsp, 8
LGP2 :
 auipc gp, 0
 ld    x18 , (nextch-LGP2 )-8 (gp)
 add   x17 , x17 , x18 
 addi  dsp, dsp, -8
 sd    x17 , 0(dsp)
 ld    x17 , (nextch-LGP2 )-16 (gp)
 sub   x16 , x16 , x17 
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jalr  x0, 0(ra)
 align 8
type:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
L0 :
 ld    x16 , 0 (dsp)
 beq   x16 , x0, L1 
 ld    x16 , 8 (dsp)
 lb    x16 , 0(x16 )
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, emit
 jal   ra, nextch
 jal   x0, L0 
L1 :
 ld    x16 , 0(dsp)
 addi  dsp, dsp, 8
 ld    x17 , 0(dsp)
 addi  dsp, dsp, 8
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $0000000000000001
place:
 ld    x16 , 0(dsp)
 addi  dsp, dsp, 8
 ld    x17 , 0 (dsp)
 sb    x16 , 0(x17 )
 ld    x16 , 0 (dsp)
LGP3 :
 auipc gp, 0
 ld    x17 , (place-LGP3 )-8 (gp)
 add   x16 , x16 , x17 
 sd    x16 , 0 (dsp)
 jalr  x0, 0(ra)
 align 8
  dword $0000000000000068
h:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP4 :
 auipc gp, 0
 ld    x16 , (h-LGP4 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $0000000000000065
e:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP5 :
 auipc gp, 0
 ld    x16 , (e-LGP5 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $000000000000006C
l:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP6 :
 auipc gp, 0
 ld    x16 , (l-LGP6 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $000000000000006F
o:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP7 :
 auipc gp, 0
 ld    x16 , (o-LGP7 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $0000000000000077
w:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP8 :
 auipc gp, 0
 ld    x16 , (w-LGP8 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $0000000000000072
r:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP9 :
 auipc gp, 0
 ld    x16 , (r-LGP9 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $0000000000000064
d:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP10 :
 auipc gp, 0
 ld    x16 , (d-LGP10 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $0000000000000020
space:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP11 :
 auipc gp, 0
 ld    x16 , (space-LGP11 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $000000000000000D
cr:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP12 :
 auipc gp, 0
 ld    x16 , (cr-LGP12 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $000000000000000A
lf:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
LGP13 :
 auipc gp, 0
 ld    x16 , (lf-LGP13 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, place
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
  dword $000000000000000D
string:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
 addi  x16 , gvp, -2048 
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 jal   ra, h
 jal   ra, e
 jal   ra, l
 jal   ra, l
 jal   ra, o
 jal   ra, space
 jal   ra, w
 jal   ra, o
 jal   ra, r
 jal   ra, l
 jal   ra, d
 jal   ra, cr
 jal   ra, lf
 addi  x16 , gvp, -2048 
 sd    x16 , 0 (dsp)
LGP14 :
 auipc gp, 0
 ld    x16 , (string-LGP14 )-8 (gp)
 addi  dsp, dsp, -8
 sd    x16 , 0(dsp)
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
 align 8
_:
 addi  rsp, rsp, -8
 sd    ra, 0(rsp)
 jal   ra, string
 jal   ra, type
 jal   ra, bye
 ld    ra, 0(rsp)
 addi  rsp, rsp, 8
 jalr  x0, 0(ra)
