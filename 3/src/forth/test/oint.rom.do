SRCD=..
SRCF=$(basename $2 .rom)

redo-ifchange $SRCD/asrt.i $SRCD/asrt.asm
redo-ifchange $SRCD/oint.asm

a from $SRCF.asm to $3 quiet

