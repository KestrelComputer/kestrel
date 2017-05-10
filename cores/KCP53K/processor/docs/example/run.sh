#!/bin/bash
iverilog computer.v address_decode.v output_csr.v rom.v arbiter.v bridge.v ../../rtl/verilog/polaris.v ../../rtl/verilog/xrs.v ../../rtl/verilog/seq.v ../../rtl/verilog/alu.v 
vvp -n a.out

