help:
	@echo "make sia_receiver.waves Run gtkwave on results from simulating SIA components"
	@echo "make sia_rxq.waves"
	@echo "make sia_txq.waves"
	@echo "make sia_wb.waves"
	@echo
	@echo "make clean             remove output files"
	@echo

sia_receiver.waves:
	iverilog -s sia_receiver_tb ../common/*.v bench/verilog/*.v rtl/verilog/*.v -I../common && vvp -n a.out && gtkwave sia_receiver.vcd

sia_rxq.waves:
	iverilog -s sia_rxq_tb ../common/*.v bench/verilog/*.v rtl/verilog/*.v -I../common && vvp -n a.out && gtkwave sia_rxq.vcd

sia_wb.waves:
	iverilog -s sia_wb_tb ../common/*.v bench/verilog/*.v rtl/verilog/*.v -I../common && vvp -n a.out && gtkwave sia_wb.vcd

sia_txq.waves:
	iverilog -s sia_txq_tb ../common/*.v bench/verilog/*.v rtl/verilog/*.v -I../common && vvp -n a.out && gtkwave sia_txq.vcd

clean:
	rm -f *.blif *.asc *.bin *.vcd

.PHONY: clean sia_receiver.waves sia_rxq.waves sia_wb.waves sia_txq.waves

