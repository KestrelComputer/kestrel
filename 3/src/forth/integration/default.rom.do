BIND=../../../bin
SRCD=..
SRCF=$(basename $2 .rom)

redo-ifchange $BIND/a

redo-ifchange $SRCD/asrt.i $SRCD/asrt.asm
redo-ifchange $SRCD/oint.asm $SRCD/dict.asm $SRCD/scan.asm $SRCD/char.asm
redo-ifchange $SRCD/numb.asm $SRCD/dstk.asm $SRCD/err.asm $SRCD/math.asm

a from $SRCF.asm to $3 quiet

