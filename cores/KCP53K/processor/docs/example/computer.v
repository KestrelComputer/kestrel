`timescale 1ns / 1ps

module computer(
`ifdef VERILATOR
	input clk,
	input reset
`endif
);
	wire iack;
	wire [63:0] iadr;
	wire istb;
	wire [31:0] idatiL;
	wire [63:32] idatiH;	// unused; just to make iverilog happy.

	wire [63:0] ddato, ddati, dadr;
	wire [1:0] dsiz;
	wire dwe, dcyc, dstb, dsigned, dack;

	wire [11:0] cadr;
	wire coe, cwe, cvalid;
	wire [63:0] cdato, cdati;

	wire STB;
	wire [63:0] romQ;

	wire [1:0] xsiz;
	wire [63:0] xadr;
	wire [63:0] xdati, xdato;
	wire xstb, xack, xsigned;

//	initial begin
//	$dumpfile("wtf.vcd"); $dumpvars;
//	end

`ifndef VERILATOR
	reg clk, reset;
	initial begin
		clk <= 0;
		reset <= 1;
		#60; reset <= 0;
	end

	always begin
		#20 clk <= ~clk;
	end
`endif

	PolarisCPU cpu(
		.fence_o(),
		.trap_o(),
		.cause_o(),
		.mepc_o(),
		.mpie_o(),
		.mie_o(),
		.ddat_o(ddato),
		.dadr_o(dadr),
		.dwe_o(dwe),
		.dcyc_o(dcyc),
		.dstb_o(dstb),
		.dsiz_o(dsiz),
		.dsigned_o(dsigned),
		.irq_i(1'b0),
		.iack_i(iack),
		.idat_i(idatiL),
		.iadr_o(iadr),
		.istb_o(istb),
		.dack_i(dack),
		.ddat_i(ddati),
		.cadr_o(cadr),
		.coe_o(coe),
		.cwe_o(cwe),
		.cvalid_i(cvalid),
		.cdat_o(cdato),
		.cdat_i(cdati),
		.clk_i(clk),
		.reset_i(reset)
	);

	arbiter arbiter(
		.idat_i(64'd0),	// CPU cannot write via I-port.
		.iadr_i(iadr),
		.iwe_i(1'b0),
		.icyc_i(istb),
		.istb_i(istb),
		.isiz_i({istb, 1'b0}),
		.isigned_i(1'b0),
		.iack_o(iack),
		.idat_o({idatiH, idatiL}),

		.ddat_i(ddato),
		.dadr_i(dadr),
		.dwe_i(dwe),
		.dcyc_i(dcyc),
		.dstb_i(dstb),
		.dsiz_i(dsiz),
		.dsigned_i(dsigned),
		.dack_o(dack),
		.ddat_o(ddati),

		.xdat_o(xdato),
		.xadr_o(xadr),
		.xwe_o(),
		.xcyc_o(),
		.xstb_o(xstb),
		.xsiz_o(xsiz),
		.xsigned_o(xsigned),
		.xack_i(xack),
		.xdat_i(xdati),

		.clk_i(clk),
		.reset_i(reset)
	);

	bridge bridge(
		.f_signed_i(xsigned),
		.f_siz_i(xsiz),
		.f_adr_i(xadr[2:0]),
		.f_dat_i(xdato),
		.f_dat_o(xdati),

		.wb_sel_o(),
		.wb_dat_i(romQ),
		.wb_dat_o()
	);

	rom rom(
		.A(xadr[11:3]),
		.Q(romQ),
		.STB(STB)
	);

	address_decode ad(
		.iadr_i(xadr[12]),
		.istb_i(xstb),
		.iack_o(xack),
		.STB_o(STB)
	);

	output_csr outcsr(
		.cadr_i(cadr),
		.cvalid_o(cvalid),
		.cdat_o(cdati),
		.cdat_i(cdato),
		.coe_i(coe),
		.cwe_i(cwe),
		.clk_i(clk)
	);
endmodule

