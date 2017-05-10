SIM=iverilog -I rtl/verilog

.PHONY: test polaris xrs alu

test: polaris xrs alu

rtl/verilog/seq.v: rtl/SMG/seq.smg
	smg.shen rtl/SMG/seq.smg >rtl/verilog/seq.v

polaris: bench/verilog/polaris.v rtl/verilog/polaris.v rtl/verilog/xrs.v rtl/verilog/seq.v rtl/verilog/alu.v
	$(SIM) -Wall bench/verilog/polaris.v rtl/verilog/polaris.v rtl/verilog/xrs.v rtl/verilog/seq.v rtl/verilog/alu.v
	vvp -n a.out

xrs:
	$(SIM) -Wall bench/verilog/xrs.v rtl/verilog/xrs.v
	vvp -n a.out

alu:
	$(SIM) -Wall bench/verilog/alu.v rtl/verilog/alu.v
	vvp -n a.out

