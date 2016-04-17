redo-ifchange ../src/forth/*.fs
gforth ../src/forth/forth.fs -e bye >/dev/null
mv forth.rom $3
