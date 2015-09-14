# Allows building ROMs even if bin isn't in path.
export PATH=$PATH:$(pwd)/bin

redo-ifchange bin/a
redo-ifchange bin/bspl.fs
redo-ifchange bin/e

redo-ifchange roms/mlm
redo-ifchange roms/ngaro

echo "Be sure to add bin/ to your \$PATH if you haven't already." >&2
echo "  export PATH=\$PATH:$(pwd)/bin" >&2
