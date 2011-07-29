CFLAGS=`sdl-config --cflags`
LDFLAGS=`sdl-config --libs`

.c.o:
	gcc ${CFLAGS} -O4 -fomit-frame-pointer -c -o $@ $<

ks.c: ks.nw
	notangle -Rks.c ks.nw >ks.c

ks: ks.o
	gcc -o $@ $< ${LDFLAGS}

img.f: img.nw
	notangle -Rimg.f img.nw >img.f

ks.html: ks.nw
	noweave -html -index ks.nw >ks.html

img.html: img.nw
	noweave -html -index img.nw >img.html

clean:
	rm -f img.f img.html ks ks.c ks.html ks.o romfile

