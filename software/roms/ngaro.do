VMSRC=../src/ngaro

redo-ifchange ../bin/a
redo-ifchange $VMSRC/*.asm $VMSRC/ngaro.asm
a from $VMSRC/vm.asm to $3 quiet
