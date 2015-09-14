ASMSRC=../src/a
VMSRC=../src/ngaro
redo-ifchange $ASMSRC/*.py
redo-ifchange $VMSRC/*.asm
redo-ifchange $VMSRC/*.m4
m4 $VMSRC/ngaro.asm.m4 >$VMSRC/ngaro.asm
a from $VMSRC/vm.asm to $3 quiet
