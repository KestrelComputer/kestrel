redo-ifchange ../../../bin/a dxforth.asm dxforth-boot.asm
exec >&2
../../../bin/a from dxforth.asm to dxforth-image.bin
../../../bin/a from dxforth-boot.asm to $3
