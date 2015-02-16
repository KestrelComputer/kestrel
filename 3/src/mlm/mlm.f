\ Machine Language Monitor V1
\ Kestrel-3
\ Copyright (c) Samuel A. Falvo II
\ Please see LICENSE file for rights granted.

INCLUDE ../src/vasm/va.f

INCLUDE ../src/mlm/uart.i

INCLUDE ../src/mlm/rodata.asm
$CC $2000 ADVANCE
INCLUDE ../src/mlm/code.asm

2 argv >rom
BYE

