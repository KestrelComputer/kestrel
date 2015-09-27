redo-ifchange *.c
redo-ifchange test-*.c

cutgen -o $3 test-*.c
