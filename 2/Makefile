CFLAGS=`sdl-config --cflags`
LDFLAGS=`sdl-config --libs`

help:
	cat Makefile | grep :

.c.o:
	gcc ${CFLAGS} -O4 -fomit-frame-pointer -c -o $@ $<

ks.c: ks.nw
	notangle -Rks.c ks.nw >ks.c

ks: ks.o
	gcc -o $@ $< ${LDFLAGS}

img.f: img.nw
	notangle -Rimg.f img.nw >img.f

asm.f: asm.nw
	notangle -Rasm.f asm.nw >asm.f

ks.html: ks.nw
	noweave -html -index ks.nw >ks.html

img.html: img.nw
	noweave -html -index img.nw >img.html

asm.html: asm.nw
	noweave -html -index asm.nw >asm.html

clean:
	rm -f asm.f asm.html img.f img.html ks ks.c ks.html ks.o romfile

