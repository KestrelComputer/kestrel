SIM=iverilog -I rtl/verilog
SMG=smg.shen

.PHONY: test bottleneck

test: bottleneck

bottleneck: bench/verilog/bottleneck.v rtl/verilog/bottleneck.v rtl/verilog/BottleneckSequencer.v
	$(SIM) -Wall bench/verilog/bottleneck.v rtl/verilog/bottleneck.v rtl/verilog/BottleneckSequencer.v
	vvp -n a.out
