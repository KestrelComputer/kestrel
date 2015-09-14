ASMSRC=../src/a
VMSRC=../src/ngaro
redo-ifchange $ASMSRC/*.py
redo-ifchange $VMSRC/*.asm $VMSRC/ngaro.asm
a from $VMSRC/vm.asm to $3 quiet
