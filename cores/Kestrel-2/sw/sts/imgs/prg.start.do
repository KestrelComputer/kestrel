#!/bin/bash
redo-ifchange ../../asm.fs ../PRG.start.fs lib.textiface
REDO_OUT=$3 gforth -e 'warnings off' ../../asm.fs ../PRG.start.fs -e 'bye'

