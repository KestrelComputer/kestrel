SRC=../src/bin2v
redo-ifchange $SRC/*.py
# Copy everything over, except for bin2v.py; otherwise, redo will complain.
# Our dirty trick: rename a.py to what redo expects us to create.
# Don't worry; redo will rename it back for us.
cp -pr $SRC/*.py .
mv ./bin2v.py $3
