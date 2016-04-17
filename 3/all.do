# Allows building ROMs even if bin isn't in path.
export PATH="$PATH:$(pwd)/bin"

redo-ifchange bin/e

redo-ifchange roms/mlm
redo-ifchange roms/ngaro
redo-ifchange roms/sdtest
redo-ifchange roms/sdb
redo-ifchange roms/forth

echo "Be sure to add bin/ to your \$PATH if you haven't already." >&2
echo "  export PATH=\$PATH:$(pwd)/bin" >&2
