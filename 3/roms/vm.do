ASMSRC=../a
VMSRC=.
redo-ifchange $ASMSRC/*.py
redo-ifchange $VMSRC/*.asm
redo-ifchange $VMSRC/*.m4
m4 $VMSRC/ngaro.asm.m4 >$VMSRC/ngaro.asm
$ASMSRC/a.py from $VMSRC/vm.asm to $3 quiet
