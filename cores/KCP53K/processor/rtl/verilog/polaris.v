`timescale 1ns / 1ps

`define PHASE 20	// 20ns per phase, 40ns per cycle, 25MHz

module PolarisCPU(
	// MISC DIAGNOSTICS

	output			fence_o,
	output			trap_o,
	output	[3:0]		cause_o,
	output	[63:0]		mepc_o,
	output			mpie_o,
	output			mie_o,

	input			irq_i,

	// I MASTER

	input			iack_i,
	input	[31:0]		idat_i,
	output	[63:0]		iadr_o,
	output			istb_o,

	// D MASTER

	input			dack_i,
	input	[63:0]		ddat_i,
	output	[63:0]		ddat_o,
	output	[63:0]		dadr_o,
	output			dwe_o,
	output			dcyc_o,
	output			dstb_o,
	output	[1:0]		dsiz_o,
	output			dsigned_o,

	// CSR ACCESS

	output	[11:0]		cadr_o,
	output			coe_o,
	output			cwe_o,
	input			cvalid_i,
	output	[63:0]		cdat_o,
	input	[63:0]		cdat_i,

	// SYSCON

	input			clk_i,
	input			reset_i
);
	// Sequencer outputs
	wire		pc_mbvec, pc_pcPlus4;
	wire		ft0_o;
	wire		iadr_pc;
	wire		ir_idat;

	// Sequencer inputs
	reg		ft0;

	// Internal working wires and registers
	reg		rst;
	reg	[63:0]	pc, ia;
	wire	[63:0]	pc_mux, ia_mux;
	reg	[31:0]	ir;
	wire	[31:0]	ir_mux;
	reg		xt0, xt1, xt2, xt3, xt4;
	wire		xt0_o, xt1_o, xt2_o, xt3_o, xt4_o;
	wire	[4:0]	ra_mux;
	wire		ra_ir1, ra_ir2, ra_ird;
	wire		rdat_alu, rdat_pc;
	wire	[63:0]	rdat_i, rdat_o;
	wire		rwe_o;
	reg	[63:0]	alua, alub;
	wire	[63:0]	alua_mux, alub_mux;
	wire		alua_rdat, alua_0, alua_ia;
	wire		alub_rdat, alub_imm12i, alub_imm12s, alub_imm20u, alub_imm20uj;
	wire	[63:0]	imm12i, imm12s, imm12sb;
	wire		pc_alu;
	wire		cflag_i;
	wire		sum_en;
	wire		and_en;
	wire		xor_en;
	wire		invB_en;
	wire		lsh_en;
	wire		rsh_en;
	wire		ltu_en, lts_en;
	wire	[63:0]	aluResult, aluXResult;
	wire		cflag_o;
	wire		vflag_o;
	wire		zflag_o;
	wire	[3:0]	rmask_i;
	wire		sx32_en;
	wire		alua_alua;
	wire		alub_alub;
	wire	[63:0]	imm20u, imm20uj;
	wire		ia_pc;
	wire		dadr_alu;
	wire		dcyc_1;
	wire		dstb_1;
	wire		dsiz_fn3;
	wire		rdat_ddat;
	wire		ddat_rdat;
	wire	[7:0]	ccr_mux;
	reg	[7:0]	ccr;
	wire		ccr_alu;
	wire		alub_imm12sb;
	reg		trap;
	wire		mcause_2, mcause_3, mcause_11;
	wire		pc_mtvec;
	reg	[63:0]	mepc;
	wire	[63:0]	mepc_mux;
	wire		mepc_ia;
	wire		pc_mepc;
	wire		mie, mpie;
	wire		mie_0, mie_mpie;
	wire		mpie_mie, mpie_1;
	wire		rdat_cdat, cdat_rdat;
	wire		coe_1, cwe_1;
	wire		cdat_imm5;
	wire		cdat_alu;
	wire		alub_imm5;
	wire		alua_cdat;
	wire		icvalid_i;
	wire	[63:0]	icdat_i;
	wire	[63:0]	mtvec_i;
	wire		take_irq;
	wire		mepc_pc;
	wire		mcause_irq_o;

	wire		cvalid = icvalid_i | cvalid_i;
	wire	[63:0]	ucdat_i = icdat_i | cdat_i;

	wire rdNotZero = |ir[11:7];
	wire r1NotZero = |ir[19:15];
	wire [63:0] imm5 = {59'b0, ir[19:15]};
	assign coe_o = coe_1 & rdNotZero;
	assign cwe_o = cwe_1 & r1NotZero;
	assign cadr_o = ir[31:20];
	assign cdat_o = (cdat_rdat ? rdat_o : 0) |
			(cdat_alu ? aluXResult : 0) |
			(cdat_imm5 ? imm5 : 0);

	wire ltFlag = aluXResult[63] ^ vflag_o;
	assign ccr_mux = ccr_alu ? {cflag_o, ~cflag_o, ~ltFlag, ltFlag, 2'b00, ~zflag_o, zflag_o} : ccr;
	assign dsigned_o = dsiz_fn3 & ~ir[14];
	assign dsiz_o = dsiz_fn3 ? ir[13:12] : 2'b00;
	assign dcyc_o = dcyc_1;
	assign dstb_o = dstb_1;
	assign dadr_o = (dadr_alu ? aluXResult : 64'd0);
	assign ddat_o = (ddat_rdat ? rdat_o : 0);

	assign aluXResult = (sx32_en ? {{32{aluResult[31]}}, aluResult[31:0]} : aluResult);
	assign imm12i = {{52{ir[31]}}, ir[31:20]};
	assign imm12s = {{52{ir[31]}}, ir[31:25], ir[11:7]};
	assign imm12sb = {{51{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
	assign imm20u = {{32{ir[31]}}, ir[31:12], 12'd0};
	assign imm20uj = {{43{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
	assign alua_alua = ~|{alua_rdat, alua_0, alua_ia, alua_cdat};
	assign alub_alub = ~|{alub_rdat, alub_imm12i, alub_imm12s, alub_imm12sb, alub_imm20u, alub_imm20uj, alub_imm5};
	assign alua_mux =	// ignore alua_0 since that will force alua=0.
			(alua_ia ? ia : 0) |
			(alua_rdat ? rdat_o : 0) |
			(alua_cdat ? ucdat_i : 0) |
			(alua_alua ? alua : 0);
	assign alub_mux =
			(alub_rdat ? rdat_o : 0) |
			(alub_imm12i ? imm12i : 0) |
			(alub_imm12s ? imm12s : 0) |
			(alub_imm12sb ? imm12sb : 0) |
			(alub_imm20u ? imm20u : 0) |
			(alub_imm20uj ? imm20uj : 0) |
			(alub_imm5 ? imm5 : 0) |
			(alub_alub ? alub : 0);
	assign rdat_i = (rdat_alu ? aluXResult : 0) |
			(rdat_ddat ? ddat_i : 0) |
			(rdat_cdat ? ucdat_i : 0) |
			(rdat_pc ? pc : 0);
	assign ra_mux = (ra_ir1 ? ir[19:15] : 0) |
			(ra_ir2 ? ir[24:20] : 0) |
			(ra_ird ? ir[11:7] : 0);	// Defaults to 0
	wire pc_pc    = ~|{pc_mbvec,pc_pcPlus4,pc_alu,pc_mtvec,pc_mepc};
	assign pc_mux = (pc_mbvec ? 64'hFFFF_FFFF_FFFF_FF00 : 64'h0) |
			(pc_pcPlus4 ? pc + 4 : 64'h0) |
			(pc_alu ? aluXResult : 64'h0) |
			(pc_mtvec ? mtvec_i : 64'h0) |
			(pc_mepc ? mepc_o : 64'h0) |
			(pc_pc ? pc : 64'h0);	// base case
	wire ia_ia    = ~ia_pc;
        assign ia_mux = (ia_pc ? pc : 0) |
			(ia_ia ? ia : 0);
	assign iadr_o = iadr_pc ? pc : 0;
	wire ir_ir    = ~ir_idat;
	assign ir_mux = (ir_idat ? idat_i : 0) |
			(ir_ir ? ir : 0);	// base case

	always @(posedge clk_i) begin
		rst <= reset_i;
		pc <= pc_mux;
		ia <= ia_mux;
		ft0 <= ft0_o;
		xt0 <= xt0_o;
		xt1 <= xt1_o;
		xt2 <= xt2_o;
		xt3 <= xt3_o;
		xt4 <= xt4_o;
		ir <= ir_mux;
		alua <= alua_mux;
		alub <= alub_mux;
		ccr <= ccr_mux;
		trap <= trap_o;
	end

	Sequencer s(
		.xt0_o(xt0_o),
		.xt1_o(xt1_o),
		.xt2_o(xt2_o),
		.xt3_o(xt3_o),
		.xt0(xt0),
		.xt1(xt1),
		.xt2(xt2),
		.xt3(xt3),
		.ft0(ft0),
		.istb_o(istb_o),
		.iadr_pc(iadr_pc),
		.iack_i(iack_i),
		.pc_mbvec(pc_mbvec),
		.pc_pcPlus4(pc_pcPlus4),
		.ir_idat(ir_idat),
		.ir(ir),
		.ft0_o(ft0_o),
		.rdat_pc(rdat_pc),
		.sum_en(sum_en),
		.pc_alu(pc_alu),
		.ra_ir1(ra_ir1),
		.ra_ir2(ra_ir2),
		.ra_ird(ra_ird),
		.alua_rdat(alua_rdat),
		.alub_rdat(alub_rdat),
		.alub_imm12i(alub_imm12i),
		.rwe_o(rwe_o),
		.rdat_alu(rdat_alu),
		.and_en(and_en),
		.xor_en(xor_en),
		.invB_en(invB_en),
		.lsh_en(lsh_en),
		.rsh_en(rsh_en),
		.cflag_i(cflag_i),
		.sx32_en(sx32_en),
		.alua_0(alua_0),
		.alub_imm20u(alub_imm20u),
		.ia_pc(ia_pc),
		.alua_ia(alua_ia),
		.dadr_alu(dadr_alu),
		.dcyc_1(dcyc_1),
		.dstb_1(dstb_1),
		.dsiz_fn3(dsiz_fn3),
		.rdat_ddat(rdat_ddat),
		.dack_i(dack_i),
		.ddat_rdat(ddat_rdat),
		.alub_imm12s(alub_imm12s),
		.dwe_o(dwe_o),
		.alub_imm20uj(alub_imm20uj),
		.ccr_alu(ccr_alu),
		.alub_imm12sb(alub_imm12sb),
		.xt4_o(xt4_o),
		.xt4(xt4),
		.ccr(ccr),
		.fence_o(fence_o),
		.trap_o(trap_o),
		.trap(trap),
		.mcause_2(mcause_2),
		.mcause_3(mcause_3),
		.mcause_11(mcause_11),
		.pc_mtvec(pc_mtvec),
		.mepc_ia(mepc_ia),
		.pc_mepc(pc_mepc),
		.mpie_mie(mpie_mie),
		.mpie_1(mpie_1),
		.mie_mpie(mie_mpie),
		.mie_0(mie_0),
		.csrok_i(cvalid),
		.rdat_cdat(rdat_cdat),
		.coe_o(coe_1),
		.cdat_rdat(cdat_rdat),
		.cwe_o(cwe_1),
		.cdat_imm5(cdat_imm5),
		.cdat_alu(cdat_alu),
		.alub_imm5(alub_imm5),
		.alua_cdat(alua_cdat),
		.take_irq(take_irq),
		.mepc_pc(mepc_pc),
		.mcause_irq_o(mcause_irq_o),
		.ltu_en(ltu_en),
		.lts_en(lts_en),
		.rst(rst)
	);

	xrs xrs(
		.clk_i(clk_i),
		.ra_i(ra_mux),
		.rdat_i(rdat_i),
		.rdat_o(rdat_o),
		.rmask_i({4{rwe_o}})
	);

	alu alu(
		.inA_i(alua),
		.inB_i(alub),
		.cflag_i(cflag_i),
		.sum_en_i(sum_en),
		.and_en_i(and_en),
		.xor_en_i(xor_en),
		.invB_en_i(invB_en),
		.lsh_en_i(lsh_en),
		.rsh_en_i(rsh_en),
		.ltu_en_i(ltu_en),
		.lts_en_i(lts_en),
		.out_o(aluResult),
		.cflag_o(cflag_o),
		.vflag_o(vflag_o),
		.zflag_o(zflag_o)
	);

	CSRs csrs(
		.cadr_i(cadr_o),
		.cvalid_o(icvalid_i),
		.cdat_o(icdat_i),
		.cdat_i(cdat_o),
		.coe_i(coe_o),
		.cwe_i(cwe_o),

		.mie_0(mie_0),
		.mie_mpie(mie_mpie),
		.mpie_mie(mpie_mie),
		.mpie_1(mpie_1),
		.mtvec_o(mtvec_i),
		.mepc_o(mepc_o),
		.mie_o(mie_o),
		.mpie_o(mpie_o),
		.ft0_i(ft0),
		.tick_i(1'b0),	// for now
		.mcause_2(mcause_2),
		.mcause_3(mcause_3),
		.mcause_11(mcause_11),
		.mepc_ia(mepc_ia),
		.mepc_pc(mepc_pc),
		.ia_i(ia),
		.pc_i(pc),
		.cause_o(cause_o),
		.irq_i(irq_i),
		.take_irq_o(take_irq),
		.mcause_irq_i(mcause_irq_o),

		.reset_i(reset_i),
		.clk_i(clk_i)
	);
endmodule


module CSRs(
	input	[11:0]	cadr_i,
	output		cvalid_o,
	output	[63:0]	cdat_o,
	input	[63:0]	cdat_i,
	input		coe_i,
	input		cwe_i,

	input		mie_0,
	input		mie_mpie,
	input		mpie_mie,
	input		mpie_1,
	output	[63:0]	mtvec_o,
	output	[63:0]	mepc_o,
	output	[3:0]	cause_o,
	input	[63:0]	ia_i,
	input	[63:0]	pc_i,
	output		mie_o,
	output		mpie_o,
	input		ft0_i,
	input		tick_i,
	input		mcause_2,
	input		mcause_3,
	input		mcause_11,
	input		mcause_irq_i,
	input		mepc_ia,
	input		mepc_pc,
	input		irq_i,
	output		take_irq_o,

	input		reset_i,
	input		clk_i
);
	reg		mpie, mie;
	reg	[63:0]	mtvec;
	reg	[63:0]	mscratch;
	reg	[63:0]	mepc;
	reg	[4:0]	mcause;		// Compacted; bit 4 here maps to bit 63 in software
	reg	[63:0]	mbadaddr;
	reg	[63:0]	mcycle;
	reg	[63:0]	mtime;
	reg	[63:0]	minstret;
	reg		irqEn;

	wire		mpie_mux, mie_mux;
	wire	[63:0]	mtvec_mux;
	wire	[63:0]	mscratch_mux;
	wire	[63:0]	mepc_mux;
	wire	[4:0]	mcause_mux;
	wire	[63:0]	mbadaddr_mux;
	wire	[63:0]	mcycle_mux;
	wire	[63:0]	mtime_mux;
	wire	[63:0]	minstret_mux;

	assign mtvec_o = mtvec;
	assign mepc_o = mepc;

	wire		csrv_misa = (cadr_i == 12'hF10);
	wire		csrv_mvendorid = (cadr_i == 12'hF11);
	wire		csrv_marchid = (cadr_i == 12'hF12);
	wire		csrv_mimpid = (cadr_i == 12'hF13);
	wire		csrv_mhartid = (cadr_i == 12'hF14);
	wire		csrv_mstatus = (cadr_i == 12'h300);
	wire		csrv_medeleg = (cadr_i == 12'h302);
	wire		csrv_mideleg = (cadr_i == 12'h303);
	wire		csrv_mie = (cadr_i == 12'h304);
	wire		csrv_mtvec = (cadr_i == 12'h305);
	wire		csrv_mscratch = (cadr_i == 12'h340);
	wire		csrv_mepc = (cadr_i == 12'h341);
	wire		csrv_mcause = (cadr_i == 12'h342);
	wire		csrv_mbadaddr = (cadr_i == 12'h343);
	wire		csrv_mip = (cadr_i == 12'h344);
	wire		csrv_mcycle = (cadr_i == 12'hF00);
	wire		csrv_mtime = (cadr_i == 12'hF01);
	wire		csrv_minstret = (cadr_i == 12'hF02);

	assign cvalid_o = |{
		csrv_misa, csrv_mvendorid, csrv_marchid,
		csrv_mimpid, csrv_mhartid, csrv_mstatus,
		csrv_medeleg, csrv_mideleg, csrv_mie,
		csrv_mtvec, csrv_mscratch, csrv_mepc,
		csrv_mcause, csrv_mbadaddr, csrv_mip,
		csrv_mcycle, csrv_mtime, csrv_minstret
	};

	wire	[63:0]	csrd_misa = {2'b10, 36'd0, 26'b00000001000000000100000000};
	wire	[63:0]	csrd_mvendorid = 64'd0;
	wire	[63:0]	csrd_marchid = 64'd0;
	wire	[63:0]	csrd_mimpid = 64'h1161008010000000;
	wire	[63:0]	csrd_mhartid = 64'd0;
	wire	[63:0]	csrd_mstatus = {
		1'b0,		// SD
		34'd0,		// reserved		
		5'b00000,	// VM
		4'b0000,	// reserved
		3'b000,		// MXR, PUM, MPRV
		2'b00,		// XS
		2'b00,		// FS
		2'b11,		// MPP
		2'b10,		// HPP
		1'b1,		// SPP
		mpie, 3'b000,
		mie, 3'b000
	};
	wire	[63:0]	csrd_medeleg = 64'd0;
	wire	[63:0]	csrd_mideleg = 64'd0;
	wire	[63:0]	csrd_mie = {
		52'd0,
		irqEn,
		11'd0
	};
	wire	[63:0]	csrd_mtvec = mtvec;
	wire	[63:0]	csrd_mscratch = mscratch;
	wire	[63:0]	csrd_mepc = mepc;
	wire	[63:0]	csrd_mcause = {
		mcause[4],
		59'd0,		// reserved
		mcause[3:0]
	};
	wire	[63:0]	csrd_mbadaddr = mbadaddr;
	wire	[63:0]	csrd_mip = {
		52'd0,
		irq_i,
		11'd0
	};
	wire	[63:0]	csrd_mcycle = mcycle;
	wire	[63:0]	csrd_mtime = mtime;
	wire	[63:0]	csrd_minstret = minstret;

	assign take_irq_o = mie & irqEn & irq_i;
	assign cdat_o =
		(csrv_misa ? csrd_misa : 0) |
		(csrv_mvendorid ? csrd_mvendorid : 0) |
		(csrv_marchid ? csrd_marchid : 0) |
		(csrv_mimpid ? csrd_mimpid : 0) |
		(csrv_mhartid ? csrd_mhartid : 0) |
		(csrv_mstatus ? csrd_mstatus : 0) |
		(csrv_medeleg ? csrd_medeleg : 0) |
		(csrv_mideleg ? csrd_mideleg : 0) |
		(csrv_mie ? csrd_mie : 0) |
		(csrv_mtvec ? csrd_mtvec : 0) |
		(csrv_mscratch ? csrd_mscratch : 0) |
		(csrv_mepc ? csrd_mepc : 0) |
		(csrv_mcause ? csrd_mcause : 0) |
		(csrv_mbadaddr ? csrd_mbadaddr : 0) |
		(csrv_mip ? csrd_mip : 0) |
		(csrv_mcycle ? csrd_mcycle : 0) |
		(csrv_mtime ? csrd_mtime : 0) |
		(csrv_minstret ? csrd_minstret : 0);

	wire irqEn_cdat = csrv_mie & cwe_i;
	wire irqEn_irqEn = ~|{irqEn_cdat, reset_i};
	wire irqEn_mux =
			(irqEn_cdat ? cdat_i[11] : 0) |
			(irqEn_irqEn ? irqEn : 0);

	wire mstatus_we = csrv_mstatus & cwe_i;
	wire mie_mie = ~|{mie_0, mie_mpie, mstatus_we};
	assign mie_mux =
			(mie_0 ? 0 : 0) |
			(mie_mpie ? mpie : 0) |
			(mstatus_we ? cdat_i[3] : 0) |
			(mie_mie ? mie : 0);

	wire mpie_mpie = ~|{mpie_mie, mpie_1, mstatus_we};
	assign mpie_mux =
			(mpie_mie ? mie : 0) |
			(mpie_1 ? 1 : 0) |
			(mstatus_we ? cdat_i[7] : 0) |
			(mpie_mpie ? mpie : 0);
	assign mie_o = mie;
	assign mpie_o = mpie;

	wire mtvec_we = csrv_mtvec & cwe_i;
	wire mtvec_mtvec = ~|{mtvec_we, reset_i};
	assign mtvec_mux =
			(mtvec_we ? cdat_i : 0) |
			(reset_i ? 64'hFFFF_FFFF_FFFF_FE00 : 0) |
			(mtvec_mtvec ? mtvec : 0);

	wire mscratch_we = csrv_mscratch & cwe_i;
	assign mscratch_mux = (mscratch_we ? cdat_i : mscratch);

	wire mepc_we = csrv_mepc & cwe_i;
	wire mepc_mepc = ~|{mepc_we, mepc_ia, mepc_pc};
	assign mepc_mux =
			(mepc_we ? cdat_i : 0) |
			(mepc_ia ? ia_i : 0) |
			(mepc_pc ? pc_i : 0) |
			(mepc_mepc ? mepc : 0);

	wire mcause_we = csrv_mcause & cwe_i;
	wire mcause_mcause = ~|{mcause_2, mcause_3, mcause_11, mcause_we};
	assign cause_o = mcause_mux[3:0];
	assign mcause_mux =
			(mcause_we ? {cdat_i[63], cdat_i[3:0]} : 0) |
			(mcause_2 ? {mcause_irq_i, 4'd2} : 0) |
			(mcause_3 ? {mcause_irq_i, 4'd3} : 0) |
			(mcause_11 ? {mcause_irq_i, 4'd11} : 0) |
			(mcause_mcause ? mcause : 0);

	wire mbadaddr_we = csrv_mbadaddr & cwe_i;
	assign mbadaddr_mux = (mbadaddr_we ? cdat_i : mbadaddr);

	assign mcycle_mux = (~reset_i ? mcycle + 1 : 0);
	assign minstret_mux =
			(~reset_i & ft0_i ? minstret + 1 : 0) |
			(~reset_i & ~ft0_i ? minstret : 0);
	assign mtime_mux =
			(~reset_i & tick_i ? mtime + 1 : 0) |
			(~reset_i & ~tick_i ? mtime : 0);

	always @(posedge clk_i) begin
		mie <= mie_mux;
		mpie <= mpie_mux;
		mtvec <= mtvec_mux;
		mscratch <= mscratch_mux;
		mepc <= mepc_mux;
		mcause <= mcause_mux;
		mbadaddr <= mbadaddr_mux;
		mcycle <= mcycle_mux;
		minstret <= minstret_mux;
		mtime <= mtime_mux;

		irqEn <= irqEn_mux;
	end
endmodule

