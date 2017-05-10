export SRC=../src/e
redo-ifchange $SRC/*.c $SRC/testrunner.c $SRC/test-*.c $SRC/*.h

gcc -o $3 -I /opt/cut/include -I $SRC -L/opt/cut/lib $SRC/testrunner.c $SRC/test-sdcard.c $SRC/address_space.c $SRC/processor.c $SRC/options.c $SRC/sdcard.c -lcut
