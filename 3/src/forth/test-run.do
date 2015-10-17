BIND=../../bin

roms="numb/test/eitherHexOrDecimal.rom"
roms+=" numb/test/tryConversion.rom"
roms+=" numb/test/tryUnsignedNumber.rom"

roms+=" dict/test/compareNames.rom"
roms+=" dict/test/compareNamesUpToLength.rom"
roms+=" dict/test/findWord.rom"

roms+=" kern/test/enqueue.rom"

roms+=" test/char.rom"
roms+=" test/dstk.rom"
roms+=" test/math.rom"
roms+=" test/oint.rom"
roms+=" test/scan.rom"

redo-ifchange $BIND/e
redo-ifchange $roms

for rom in $roms; do (e romfile $rom >&2); done

