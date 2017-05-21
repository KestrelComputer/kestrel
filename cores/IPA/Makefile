help:
	@echo "make ipa.waves          Run gtkwave on results from simulationg IPA"
	@echo
	@echo "make clean             remove output files"
	@echo

ipa.waves:
	iverilog -s ipa_tb ../common/*.v bench/verilog/*.v rtl/verilog/*.v -I../common && vvp -n a.out && gtkwave ipa.vcd

clean:
	rm -f *.blif *.asc *.bin *.vcd

.PHONY: clean ipa.waves

