#!/bin/bash
redo-ifchange ../../asm.fs ../SYS.fs ../SYS.*.fs
REDO_OUT=$3 gforth -e 'warnings off' ../../asm.fs ../SYS.fs

