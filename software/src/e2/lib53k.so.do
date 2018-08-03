#!/bin/bash

redo-ifchange processor.c processor.h

gcc -MD -MF processor.d -shared -fPIC -o $3 processor.c
read DEPS <processor.d
redo-ifchange ${DEPS#*:}

