#!/bin/bash
redo-ifchange ../../asm.fs ../IPL.fs
REDO_OUT=$3 gforth -e 'warnings off' ../../asm.fs ../IPL.fs

