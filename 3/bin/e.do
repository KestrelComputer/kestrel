SRC=../src/e
redo-ifchange $SRC/*.c $SRC/*.h
gcc -O2 -o $3 $(pkg-config --cflags sdl2) -I $SRC $SRC/e.c $SRC/address_space.c $SRC/processor.c $SRC/options.c $SRC/sdcard.c $SRC/timeline.c $(pkg-config --libs sdl2)
