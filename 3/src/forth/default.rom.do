BIND=../../bin

redo-ifchange $BIND/a
redo-ifchange *.asm *.i cpu/*.i

a from $2.asm to $3 quiet

