`default_nettype none
`timescale 1ns / 1ps

`include "asserts.vh"
`include "sia.vh"

// The sia_wb core provides a Wishbone B.4 pipelined compatible slave
// port to allow bus masters to talk to the SIA's receiver and transmitter.
// Additional status bits are exposed beyond those defined by Wishbone,
// providing support for things like interrupts, DMA transfer requests, etc.
//
// This Wishbone interface defines a 16-bit serial controller.
// See sia_wb.v for register definitions.

module sia_wb_tb();
	reg		clk_i, reset_i;
	reg	[11:0]	story_to;
	reg		fault_to;

	reg	[3:1]	wbs_adr_i;
	reg		wbs_we_i, wbs_cyc_i, wbs_stb_i;
	reg	[15:0]	wbs_dat_i;
	reg	[1:0]	wbs_sel_i;
	wire	[15:0]	wbs_dat_o;
	wire		wbs_ack_o, wbs_stall_o;

	wire	[4:0]	bits_o;
	wire		eedc_o;
	wire		eedd_o;
	wire	[2:0]	txcmod_o;
	wire		rxcpol_o;
	wire	[3:0]	intena_o;
	wire	[19:0]	bitrat_o;

	wire		rxq_pop_o;
	wire		rxq_oe_o;
	reg	[15:0]	rxq_dat_i;
	reg		rxq_full_i;
	reg		rxq_not_empty_i;

	wire		txq_we_o;
	wire	[15:0]	txq_dat_o;
	reg		txq_not_full_i;
	reg		txq_empty_i;

	always begin
		#5; clk_i <= ~clk_i;
	end

	sia_wb wbs(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.adr_i(wbs_adr_i),
		.we_i(wbs_we_i),
		.cyc_i(wbs_cyc_i),
		.stb_i(wbs_stb_i),
		.dat_i(wbs_dat_i),
		.sel_i(wbs_sel_i),
		.dat_o(wbs_dat_o),
		.ack_o(wbs_ack_o),
		.stall_o(wbs_stall_o),

		.bits_o(bits_o),
		.eedc_o(eedc_o),
		.eedd_o(eedd_o),
		.txcmod_o(txcmod_o),
		.rxcpol_o(rxcpol_o),
		.intena_o(intena_o),
		.bitrat_o(bitrat_o),

		.rxq_pop_o(rxq_pop_o),
		.rxq_oe_o(rxq_oe_o),
		.rxq_dat_i(rxq_dat_i),
		.rxq_full_i(rxq_full_i),
		.rxq_not_empty_i(rxq_not_empty_i),

		.txq_we_o(txq_we_o),
		.txq_dat_o(txq_dat_o),
		.txq_not_full_i(txq_not_full_i),
		.txq_empty_i(txq_empty_i)
	);

	`STANDARD_FAULT

	`DEFASSERT(bits, 4, o)
	`DEFASSERT(txcmod, 2, o)
	`DEFASSERT(intena, 3, o)
	`DEFASSERT(bitrat, 19, o)
	`DEFASSERT(txq_dat, 15, o)
	`DEFASSERT0(eedc, o)
	`DEFASSERT0(eedd, o)
	`DEFASSERT0(rxcpol, o)
	`DEFASSERT0(rxq_oe, o)
	`DEFASSERT0(rxq_pop, o)
	`DEFASSERT0(txq_we, o)

	`DEFASSERT(wbs_dat, 15, o)
	`DEFASSERT0(wbs_ack, o)
	`DEFASSERT0(wbs_stall, o)

	initial begin
		$dumpfile("sia_wb.vcd");
		$dumpvars;

		{wbs_adr_i, wbs_we_i, wbs_cyc_i, wbs_stb_i, wbs_sel_i, wbs_dat_i, clk_i, reset_i, fault_to, rxq_dat_i, rxq_full_i, rxq_not_empty_i, txq_not_full_i, txq_empty_i} <= 0;

		wait(~clk_i); wait(clk_i); #1;
		reset_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		reset_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		assert_wbs_dat(0);
		assert_wbs_ack(0);
		assert_wbs_stall(0);

		assert_bits(10);	// 8N1 framing
		assert_txcmod(3'b100);
		assert_intena(0);
		assert_bitrat(83332);
		assert_eedc(1);
		assert_eedd(1);
		assert_rxcpol(0);

		// Alter core configuration

		wbs_cyc_i <= 1;
		wbs_stb_i <= 1;
		wbs_adr_i <= `SIA_ADR_CONFIG;
		wbs_we_i <= 1;
		wbs_dat_i <= 16'b00_1_111_11_000_01111;
		wbs_sel_i <= 2'b11;
		wait(~clk_i); wait(clk_i); #1;
		wbs_stb_i <= 0;
		wbs_we_i <= 0;
		wbs_sel_i <= 0;
		assert_wbs_ack(1);
		wait(~clk_i); wait(clk_i); #1;
		assert_wbs_ack(0);

		assert_bits(15);
		assert_txcmod(3'b111);
		assert_intena(0);
		assert_bitrat(83332);
		assert_eedc(1);
		assert_eedd(1);
		assert_rxcpol(1);

		wbs_cyc_i <= 0;

		wait(~clk_i); wait(clk_i); #1;

		// Read back our configuration

		wbs_cyc_i <= 1;
		wbs_stb_i <= 1;
		wbs_we_i <= 0;
		wbs_adr_i <= `SIA_ADR_CONFIG;
		wbs_sel_i <= 2'b11;

		wait(~clk_i); wait(clk_i); #1;

		wbs_stb_i <= 0;

		assert_wbs_ack(1);
		assert_wbs_dat(16'h3F0F);

		wait(~clk_i); wait(clk_i); #1;

		wbs_cyc_i <= 0;

		// Check core status

		wait(~clk_i); wait(clk_i); #1;

		wbs_cyc_i <= 1;
		wbs_stb_i <= 1;
		wbs_adr_i <= `SIA_ADR_STATUS;
		wbs_we_i <= 0;
		wbs_sel_i <= 2'b11;

		wait(~clk_i); wait(clk_i); #1;

		rxq_not_empty_i <= 1;
		txq_empty_i <= 1;

		#1; assert_wbs_dat(16'h0000);
		assert_wbs_ack(1);

		wait(~clk_i); wait(clk_i); #1;
		
		assert_wbs_dat(16'h8005);
		assert_wbs_ack(1);

		wbs_stb_i <= 0;

		wait(~clk_i); wait(clk_i); #1;

		wbs_cyc_i <= 0;

		// Alter and verify interrupt enable bits

		wait(~clk_i); wait(clk_i); #1;

		wbs_cyc_i <= 1;
		wbs_stb_i <= 1;
		wbs_adr_i <= `SIA_ADR_INTENA;
		wbs_we_i <= 1;
		wbs_sel_i <= 2'b01;
		wbs_dat_i <= 16'h000F;

		wait(~clk_i); wait(clk_i); #1;

		wbs_stb_i <= 0;
		wbs_adr_i <= 0;
		wbs_we_i <= 0;
		wbs_sel_i <= 0;
		wbs_dat_i <= 0;

		assert_wbs_ack(1);
		assert_intena(15);

		wait(~clk_i); wait(clk_i); #1;
		wbs_cyc_i <= 0;

		wait(~clk_i); wait(clk_i); #1;
		wbs_cyc_i <= 1;
		wbs_stb_i <= 1;
		wbs_adr_i <= `SIA_ADR_INTENA;
		wbs_we_i <= 0;
		wbs_sel_i <= 2'b01;

		wait(~clk_i); wait(clk_i); #1;
		wbs_stb_i <= 0;
		wbs_adr_i <= 0;
		wbs_sel_i <= 0;

		assert_wbs_ack(1);
		assert_intena(15);
		assert_wbs_dat(15);

		wait(~clk_i); wait(clk_i); #1;
		wbs_cyc_i <= 0;

		// Attempt to read from the receive queue.

		rxq_dat_i <= 16'hABCD;

		wait(~clk_i); wait(clk_i); #1;

		wbs_cyc_i <= 1;
		wbs_stb_i <= 1;
		wbs_adr_i <= `SIA_ADR_TRXDAT;
		wbs_we_i <= 0;
		wbs_sel_i <= 2'b11;

		wait(~clk_i); wait(clk_i); #1;

		assert_wbs_ack(1);
		assert_rxq_oe(1);
		assert_rxq_pop(1);
		assert_wbs_dat(16'hABCD);

		wbs_stb_i <= 0;

		wait(~clk_i); wait(clk_i); #1;

		wbs_cyc_i <= 0;

		wait(~clk_i); wait(clk_i); #1;

		// Attempt to write to transmit queue, 8 bits at a time.

		wbs_cyc_i <= 1;
		wbs_stb_i <= 1;
		wbs_adr_i <= `SIA_ADR_TRXDAT;
		wbs_we_i <= 1;
		wbs_sel_i <= 2'b01;
		wbs_dat_i <= 16'hBEEF;

		wait(~clk_i); wait(clk_i); #1;

		assert_wbs_ack(1);

		wbs_sel_i <= 2'b10;

		wait(~clk_i); wait(clk_i); #1;

		assert_wbs_ack(1);

		assert_txq_we(1);
		assert_txq_dat(16'hBEEF);

		wbs_stb_i <= 0;

		wait(~clk_i); wait(clk_i); #1;

		wbs_cyc_i <= 0;

		#100;
		$display("@I Done.");
		$stop;
	end
endmodule

