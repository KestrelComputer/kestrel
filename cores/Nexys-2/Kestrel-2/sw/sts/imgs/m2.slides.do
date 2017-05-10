#!/bin/bash
#
# We're a bit of a special case.  This isn't easy to automate.  Yet.
SLIDES=slides-forthday-2014.fs
cd ../..
redo-ifchange slide-asm.fs $SLIDES
gforth slide-asm.fs $SLIDES -e 'bye'

