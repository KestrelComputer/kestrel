redo-ifchange sdimage.bin
(dd if=sdimage.bin of=/dev/sdg bs=512 count=256 && sync) 1>&2

