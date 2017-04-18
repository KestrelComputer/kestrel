ifeq ($(shell bash -c 'type -p icoprog'),)
SSH_RASPI ?= ssh pi@raspi
else
SSH_RASPI ?= sh -c
endif

help:
	@echo
	@echo "make ramcon.waves      Run gtkwave on results from simulating RAMCON"
	@echo "make sia.waves         Run gtkwave on results from simulating SIA"
	@echo
	@echo "make ramtest.blif      run synthesis, generate BLIF netlist"
	@echo "make ramtest.asc       run place and route, generate IceStorm ASCII file"
	@echo "make ramtest.bin       run timing analysis, generate iCE40 BIN file"
	@echo
	@echo "make prog_sram         FPGA SRAM programming, (re)starts FPGA from SRAM"
	@echo "make prog_flash        serial flash programming, does not touch FPGA"
	@echo "make prog_erase        erase first flash block"
	@echo
	@echo "make reset_halt        stop FPGA and keep in reset"
	@echo "make reset_boot        (re)start FPGA from serial flash"
	@echo
	@echo "make clean             remove output files"
	@echo

ramcon.waves:
	iverilog -s ramcon_tb ramcon.v && vvp -n a.out && gtkwave ramcon.vcd

sia.waves:
	iverilog -s sia_tb sia.v sia_tb.v && vvp -n a.out && gtkwave sia.vcd

ramtest.blif: ramtest.v ramcon.v
	yosys -p 'synth_ice40 -blif ramtest.blif' ramtest.v ramcon.v

ramtest.asc: ramtest.blif icoboard.pcf
	arachne-pnr -d 8k -p icoboard.pcf -o ramtest.asc ramtest.blif

ramtest.bin: ramtest.asc
	icetime -d hx8k -c 100 ramtest.asc
	icepack ramtest.asc ramtest.bin

prog_sram: ramtest.bin
	$(SSH_RASPI) 'icoprog -p' < ramtest.bin

prog_flash: ramtest.bin
	$(SSH_RASPI) 'icoprog -f' < ramtest.bin

prog_erase:
	$(SSH_RASPI) 'icoprog -e'

reset_halt:
	$(SSH_RASPI) 'icoprog -R'

reset_boot:
	$(SSH_RASPI) 'icoprog -b'

clean:
	rm ramtest.blif ramtest.asc ramtest.bin

.PHONY: prog_sram prog_flash reset_halt reset_boot clean

