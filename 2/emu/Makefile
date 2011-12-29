CFLAGS=`sdl-config --cflags` -g
LDFLAGS=`sdl-config --libs` -g
FORTH=sf
HDRFTR=header.html footer.html

.c.o:
	gcc ${CFLAGS} -O4 -fomit-frame-pointer -c -o $@ $<

all: ks romfile

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

ks.html: ks.nw ${HDRFTR}
	noweave -delay -html -index ks.nw >ks.body
	cat header.html ks.body footer.html >ks.html

preen.html: preen.nw ${HDRFTR}
	noweave -delay -html -index preen.nw >preen.body
	cat header.html preen.body footer.html >preen.html

asm.html: asm.nw ${HDRFTR}
	noweave -delay -html -index asm.nw >asm.body
	cat header.html asm.body footer.html >asm.html

romfile: asm.f preen.f
	${FORTH} preen.f

clean:
	rm -f asm.f asm.html preen.f preen.html ks ks.c ks.html ks.o romfile

run: romfile ks
	./ks

