#!/bin/bash
a from example.asm to example.bin
xxd -g 8 -c 8 example.bin | awk -e '{print substr($2,15,2)substr($2,13,2)substr($2,11,2)substr($2,9,2)substr($2,7,2)substr($2,5,2)substr($2,3,2)substr($2,1,2);}' >example.hex
