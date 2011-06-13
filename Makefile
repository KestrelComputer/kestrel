CFLAGS=`sdl-config --cflags`
LDFLAGS=`sdl-config --libs`

.c.o:
	gcc ${CFLAGS} -O4 -fomit-frame-pointer -c -o $@ $<

ks: ks.o
	gcc -o $@ $< ${LDFLAGS}

