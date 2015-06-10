SRC=../src/e
redo-ifchange $SRC/e.c $SRC/address_space.[ch]
gcc -o $3 -I $SRC $SRC/e.c $SRC/address_space.c

