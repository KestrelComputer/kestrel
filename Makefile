CFLAGS=`sdl-config --cflags`
LDFLAGS=`sdl-config --libs`

.c.o:
	gcc ${CFLAGS} -c -o $@ $<

ks: ks.o
	gcc -o $@ $< ${LDFLAGS}

