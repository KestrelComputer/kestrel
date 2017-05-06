`default_nettype none
`timescale 1ns / 1ps

module sia(
	input		clk_i,
	input		reset_i,

	input	[3:1]	adr_i,
	input		we_i,
	input		cyc_i,
	input		stb_i,
	input	[1:0]	sel_i,
	input	[SRW:0]	dat_i,
	output	[SRW:0]	dat_o,
	output		ack_o,
	output		stall_o,
	output		irq_o,

	input		rxd_i,
	input		rxc_i,
	output		txd_o,
	output		txc_o

	output		rx_not_empty_o;
	output		tx_not_full_o;
);
	parameter	BAUD_RATE_WIDTH = 20;
	parameter	SHIFT_REG_WIDTH = 16;

	parameter	BRW = BAUD_RATE_WIDTH - 1;
	parameter	SRW = SHIFT_REG_WIDTH - 1;

	wire	[4:0]	wb_tr_bits;
	wire		wb_r_eedc, wb_r_eedd, wb_r_rxcpol;
	wire	[2:0]	wb_t_txcmod;
	wire	[BRW:0]	wb_tr_bitrat;
	wire		txclb, txdlb;
	wire		wb_r_pop, wb_r_oe;
	wire	[SRW:0]	r_wb_dat;
	wire		r_wb_full, r_wb_not_empty;
	wire		wb_t_we;
	wire	[SRW:0]	wb_t_dat;
	wire		t_wb_not_full, t_wb_empty, t_wb_idle;

	// Facilitates external DMA circuitry.  These would typically signal
	// an external bus master module, such as a dedicated DMAC module.
	assign rx_not_empty_o = r_wb_not_empty;
	assign tx_not_full_o = t_wb_not_full;

	wire rxd = txdlb ? txd_o : rxd_i;
	wire rxc = txclb ? txc_o : rxc_i;
	wire txd, txc;

	assign txd_o = txdlb ? 1'b0 : txd;
	assign txc_o = txclb ? wb_t_txcmod[0] : txc;

	sia_wb wb (
		.clk_i(clk_i),
		.reset_i(reset_i),

		.adr_i(adr_i),
		.we_i(we_i),
		.cyc_i(cyc_i),
		.stb_i(stb_i),
		.sel_i(sel_i),
		.dat_i(dat_i),
		.dat_o(dat_o),
		.ack_o(ack_o),
		.stall_o(stall_o),
		.irq_o(irq_o),

		.bits_o(wb_tr_bits),
		.eedc_o(wb_r_eedc),
		.eedd_o(wb_r_eedd),
		.txcmod_o(wb_t_txcmod),
		.rxcpol_o(wb_r_rxcpol),
		.intena_o(),
		.bitrat_o(wb_tr_bitrat),
		.txdlb_o(txdlb),
		.txclb_o(txclb),

		.rxq_pop_o(wb_r_pop),
		.rxq_oe_o(wb_r_oe),
		.rxq_dat_i(r_wb_dat),
		.rxq_full_i(r_wb_full),
		.rxq_not_empty_i(r_wb_not_empty),

		.txq_we_o(wb_t_we),
		.txq_dat_o(wb_t_dat),
		.txq_not_full_i(t_wb_not_full),
		.txq_empty_i(t_wb_empty),
		.txq_idle_i(t_wb_idle)
	);

	sia_rxq #(
		.BAUD_RATE_WIDTH(BAUD_RATE_WIDTH),
		.SHIFT_REG_WIDTH(SHIFT_REG_WIDTH)
	) rxq (
		.clk_i(clk_i),
		.reset_i(reset_i),

		.bits_i(wb_tr_bits),
		.baud_i(wb_tr_bitrat),
		.eedd_i(wb_r_eedd),
		.eedc_i(wb_r_eedc),
		.rxcpol_i(wb_r_rxcpol),

		.rxd_i(rxd),
		.rxc_i(rxc),

		.rxq_pop_i(wb_r_pop),
		.rxq_oe_i(wb_r_oe),
		.rxq_dat_o(r_wb_dat),
		.rxq_full_o(r_wb_full),
		.rxq_not_empty_o(r_wb_not_empty)
	);

	sia_txq #(
		.BAUD_RATE_WIDTH(BAUD_RATE_WIDTH),
		.SHIFT_REG_WIDTH(SHIFT_REG_WIDTH)
	) txq (
		.clk_i(clk_i),
		.reset_i(reset_i),

		.dat_i(wb_t_dat),
		.we_i(wb_t_we),

		.bits_i(wb_tr_bits),
		.baud_i(wb_tr_bitrat),
		.txcmod_i(wb_t_txcmod),

		.txd_o(txd),
		.txc_o(txc),
		.not_full_o(t_wb_not_full),
		.empty_o(t_wb_empty),
		.idle_o(t_wb_idle)
	);
endmodule

