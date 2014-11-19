#!/bin/bash
redo-ifchange ../LIB.textiface.fs ../textiface/*.fs ../../asm.fs
REDO_OUT=$3 gforth -e 'warnings off' ../../asm.fs ../LIB.textiface.fs -e 'bye'

