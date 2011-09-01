CFLAGS=`sdl-config --cflags` -g
LDFLAGS=`sdl-config --libs` -g
FORTH=sf

.c.o:
	gcc ${CFLAGS} -O4 -fomit-frame-pointer -c -o $@ $<

all: ks asm.f romfile

docs: ks.html preen.html asm.html

help:
	cat Makefile | grep :

ks.c: ks.nw
	notangle -Rks.c ks.nw >ks.c

ks: ks.o
	gcc -o $@ $< ${LDFLAGS}

preen.f: preen.nw
	notangle -Rpreen.f preen.nw >preen.f

asm.f: asm.nw
	notangle -Rasm.f asm.nw >asm.f

ks.html: ks.nw
	noweave -html -index ks.nw >ks.html

preen.html: preen.nw
	noweave -html -index preen.nw >preen.html

asm.html: asm.nw
	noweave -html -index asm.nw >asm.html

romfile: preen.f
	${FORTH} preen.f

clean:
	rm -f asm.f asm.html preen.f preen.html ks ks.c ks.html ks.o romfile

