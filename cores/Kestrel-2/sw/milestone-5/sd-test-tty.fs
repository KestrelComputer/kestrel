page .( *** KESTREL BIOS TTY TEST ) cr
warnings off

$0400 origin
include test-tty.fs

pibptr @ $0400 - . .( payload bytes compiled/assembled) cr

$3C00 origin
include sdsc-boot.fs

pibptr @ $3C00 - . .( bootstrap bytes compiled/assembled) cr
pibptr ? .( bytes written )
pib $3C00 +  pib  1024  move
out" sd.bin"
.( to ./sd.bin) cr
bye
