#!/bin/bash
redo-ifchange ../../asm.fs ../PRG.m2.fs
REDO_OUT=$3 gforth -e 'warnings off' ../../asm.fs ../PRG.m2.fs -e 'bye'

