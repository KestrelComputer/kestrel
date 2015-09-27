SRC=../src/bspl
redo-ifchange $SRC/*.fs $SRC/bspl.fm/*.fs
cp -pr $SRC/bspl.fm .
cp -pr $SRC/$2 $3
