redo-ifchange ../src/sdb/sdb.fs ../src/sdb/kestrel3.fs
gforth ../src/sdb/kestrel3.fs >/dev/null
mv sdb.rom $3
