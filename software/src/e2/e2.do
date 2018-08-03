#!/bin/bash
redo-ifchange main.o processor.o
gcc -o $3 main.o processor.o
