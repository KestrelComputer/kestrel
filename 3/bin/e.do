SRC=../src/e
redo-ifchange $SRC/*.c $SRC/*.h
gcc -o $3 -I $SRC $SRC/e.c $SRC/address_space.c $SRC/processor.c $SRC/options.c $SRC/sdcard.c
