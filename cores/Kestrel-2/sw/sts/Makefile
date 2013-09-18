ASM=gforth ../asm.fs

IPLIMG=sys/\$$IPL

SYSIMG=sys/\$$SYS
SYSSRCS=SYS.*

card: sdimage.bin
	dd if=sdimage.bin of=/dev/sdg bs=512 count=25 && sync

sdimage.bin: ${SYSIMG} ${IPLIMG}
	util/bin/mkimg

${SYSIMG}: ${SYSSRCS}
	${ASM} SYS.fs

${IPLIMG}: IPL.fs
	${ASM} IPL.fs

