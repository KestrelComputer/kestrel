ASM=gforth ../asm.fs

IPLIMG=sys/\$$IPL

SYSIMG=sys/\$$SYS
SYSSRCS=SYS.*

PRGSRCS=PRG.*

card: sdimage.bin
	dd if=sdimage.bin of=/dev/sdg bs=512 count=64 && sync

sdimage.bin: ${SYSIMG} ${IPLIMG} ${PRGIMG} ${PRGSRCS} Makefile
	util/bin/mkimg

${SYSIMG}: ${SYSSRCS}
	${ASM} SYS.fs

${IPLIMG}: IPL.fs
	${ASM} IPL.fs

