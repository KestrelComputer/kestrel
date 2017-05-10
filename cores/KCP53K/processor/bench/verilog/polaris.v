`timescale 1ns / 1ps

`define PHASE 20	// 20ns per phase, 40ns per cycle, 25MHz

module PolarisCPU_tb();
	reg	[31:0]	story_o;
	reg		clk_i;
	reg		reset_i;

	reg		iack_i;
	reg	[31:0]	idat_i;
	wire	[63:0]	iadr_o;
	wire		istb_o;
	wire		trap_o;
	wire	[3:0]	cause_o;

	reg		dack_i;
	reg	[63:0]	ddat_i;
	wire	[63:0]	ddat_o;
	wire	[63:0]	dadr_o;
	wire	[1:0]	dsiz_o;
	wire		dsigned_o;
	wire		dcyc_o;
	wire		dstb_o;
	wire		dwe_o;

	wire	[11:0]	cadr_o;
	wire	[63:0]	cdat_o;
	reg	[63:0]	cdat_i;
	wire		coe_o, cwe_o;
	reg		cvalid_i;

	wire	[63:0]	mepc_o;
	wire		mpie_o, mie_o;

	reg		irq_i;

	task scenario;		// Pointless task helps with searching in text editor.
	input [15:0] story;
	begin
		story_o <= {story, 16'h0000};
		@(clk_i);
		@(~clk_i);
		#(`PHASE/2);
		$display("@S SCENARIO %0d (16'h%X)", story, story);
	end
	endtask

	task tick;
	input [15:0] story;
	begin
		story_o <= {story_o[31:16], story};
		#(`PHASE * 2);
	end
	endtask

	task assert_iadr;
	input [63:0] expected;
	begin
		if(iadr_o !== expected) begin
		$display("@E %08X IADR_O Expected=%016X Got=%016X", story_o, expected, iadr_o);
		$stop;
		end
	end
	endtask

	task assert_cdat;
	input [63:0] expected;
	begin
		if(cdat_o !== expected) begin
		$display("@E %08X CDAT_O Expected=%016X Got=%016X", story_o, expected, cdat_o);
		$stop;
		end
	end
	endtask

	task assert_cadr;
	input [11:0] expected;
	begin
		if(cadr_o !== expected) begin
		$display("@E %08X CADR_O Expected=%03X Got=%03X", story_o, expected, cadr_o);
		$stop;
		end
	end
	endtask

	task assert_mepc;
	input [63:0] expected;
	begin
		if(mepc_o !== expected) begin
		$display("@E %08X MEPC_O Expected=%016X Got=%016X", story_o, expected, mepc_o);
		$stop;
		end
	end
	endtask

	task assert_istb;
	input expected;
	begin
		if(istb_o !== expected) begin
		$display("@E %08X ISTB_O Expected=%x Got=%x", story_o, expected, istb_o);
		$stop;
		end
	end
	endtask

	task assert_trap;
	input expected;
	begin
		if(trap_o !== expected) begin
		$display("@E %08X TRAP_O Expected=%b Got=%b", story_o, expected, trap_o);
		$stop;
		end
	end
	endtask

	task assert_mpie;
	input expected;
	begin
		if(mpie_o !== expected) begin
		$display("@E %08X MPIE_O Expected=%b Got=%b", story_o, expected, mpie_o);
		$stop;
		end
	end
	endtask

	task assert_mie;
	input expected;
	begin
		if(mie_o !== expected) begin
		$display("@E %08X MIE_O Expected=%b Got=%b", story_o, expected, mie_o);
		$stop;
		end
	end
	endtask

	task assert_cause;
	input [3:0] expected;
	begin
		if(cause_o !== expected) begin
		$display("@E %08X CAUSE_O Expected=%d Got=%d", story_o, expected, cause_o);
		$stop;
		end
	end
	endtask

	task assert_dadr;
	input [63:0] expected;
	begin
		if(dadr_o !== expected) begin
		$display("@E %08X DADR_O Expected=%016X Got=%016X", story_o, expected, dadr_o);
		$stop;
		end
	end
	endtask

	task assert_ddat;
	input [63:0] expected;
	begin
		if(ddat_o !== expected) begin
		$display("@E %08X DDAT_O Expected=%016X Got=%016X", story_o, expected, ddat_o);
		$stop;
		end
	end
	endtask

	task assert_dsiz;
	input [1:0] expected;
	begin
		if(dsiz_o !== expected) begin
		$display("@E %08X DSIZ_O Expected=%x Got=%x", story_o, expected, dsiz_o);
		$stop;
		end
	end
	endtask

	task assert_dcyc;
	input expected;
	begin
		if(dcyc_o !== expected) begin
		$display("@E %08X DCYC_O Expected=%x Got=%x", story_o, expected, dcyc_o);
		$stop;
		end
	end
	endtask

	task assert_coe;
	input expected;
	begin
		if(coe_o !== expected) begin
		$display("@E %08X COE_O Expected=%d Got=%d", story_o, expected, coe_o);
		$stop;
		end
	end
	endtask

	task assert_cwe;
	input expected;
	begin
		if(cwe_o !== expected) begin
		$display("@E %08X CWE_O Expected=%d Got=%d", story_o, expected, cwe_o);
		$stop;
		end
	end
	endtask

	task assert_dstb;
	input expected;
	begin
		if(dstb_o !== expected) begin
		$display("@E %08X DSTB_O Expected=%x Got=%x", story_o, expected, dstb_o);
		$stop;
		end
	end
	endtask

	task assert_dwe;
	input expected;
	begin
		if(dwe_o !== expected) begin
		$display("@E %08X DWE_O Expected=%x Got=%x", story_o, expected, dwe_o);
		$stop;
		end
	end
	endtask

	task assert_dsigned;
	input expected;
	begin
		if(dsigned_o !== expected) begin
		$display("@E %08X DSIGNED_O Expected=%x Got=%x", story_o, expected, dsigned_o);
		$stop;
		end
	end
	endtask

	always begin
		#`PHASE clk_i <= ~clk_i;
	end

	PolarisCPU cpu(
		// Miscellaneous Diagnostics

		.trap_o(trap_o),
		.cause_o(cause_o),
		.mepc_o(mepc_o),
		.mie_o(mie_o),
		.mpie_o(mpie_o),

		.irq_i(irq_i),

		// I MASTER

		.iack_i(iack_i),
		.idat_i(idat_i),
		.iadr_o(iadr_o),
		.istb_o(istb_o),

		// D MASTER

		.dack_i(dack_i),
		.ddat_i(ddat_i),
		.ddat_o(ddat_o),
		.dadr_o(dadr_o),
		.dwe_o(dwe_o),
		.dcyc_o(dcyc_o),
		.dstb_o(dstb_o),
		.dsiz_o(dsiz_o),
		.dsigned_o(dsigned_o),

		// CSRs

		.cadr_o(cadr_o),
		.coe_o(coe_o),
		.cwe_o(cwe_o),
		.cvalid_i(cvalid_i),
		.cdat_o(cdat_o),
		.cdat_i(cdat_i),

		// SYSCON

		.clk_i(clk_i),
		.reset_i(reset_i)
	);

	// Exercise the CPU's behavior on cold reset.
	task test_bootstrap;
	begin
		scenario(0);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		tick(2);
		assert_istb(0);
		reset_i <= 0;
		tick(3);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		iack_i <= 0;
		tick(4);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		iack_i <= 0;
		tick(5);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		iack_i <= 1;
		tick(6);
		assert_istb(0);
		tick(7);
		assert_istb(0);
		assert_trap(1);		// illegal instruction trap!
		assert_cause(2);
		tick(8);		// internal cycle setting registers...
		assert_trap(0);
		tick(9);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FE00);
	end
	endtask

	// Exercise the CPU's ability to execute OP-I instructions.
	task test_op_i;
	begin
		scenario(1);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		iack_i <= 1;
		idat_i <= 32'h0000_0013;	// ADDI X0, X0, 0 (aka NOP)
		tick(3);
		assert_istb(0);
		assert_trap(0);
		tick(4);
		assert_istb(0);
		assert_trap(0);
		tick(5);
		assert_istb(0);
		assert_trap(0);
		tick(6);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF04);
		assert_istb(1);
		assert_trap(0);

		idat_i <= 32'h1240_0113;	// ADDI X2, X0, $124
		tick(7);
		assert_istb(0);
		tick(8);
		assert_istb(0);
		tick(9);
		assert_istb(0);
		tick(10);
		assert_istb(1);
		idat_i <= 32'h0001_0067;	// JALR X0, 0(X2)
		tick(11);
		tick(12);
		tick(13);
		tick(14);
		tick(15);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0124);
		idat_i <= 32'h1241_0113;	// @0124 ADDI X2, X2, $124
		tick(16);
		tick(17);
		tick(18);
		tick(19);
		assert_istb(1);
		idat_i <= 32'h0001_00E7;	// @0128 JALR X1, 0(X2)
		tick(20);			// X1 = $12C
		tick(21);
		tick(22);
		tick(23);
		tick(24);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0248);
		idat_i <= 32'hFFC0_8067;	// @0248 JALR X0, -4(X1)
		tick(25);
		tick(26);
		tick(27);
		tick(28);
		tick(29);
		assert_iadr(64'h0000_0000_0000_0128);
		assert_istb(1);
		idat_i <= 32'b000011111111_00010_111_00010_0010011;
		tick(30);			// X2 = $248
		tick(31);			// ANDI X2, X2, 255
		tick(32);
		tick(33);
		assert_iadr(64'h0000_0000_0000_012C);
		assert_istb(1);
		idat_i <= 32'b000000010000_00010_001_00010_0010011;
		tick(35);			// SLLI X2, X2, 16
		tick(36);
		tick(37);
		tick(38);
		assert_iadr(64'h0000_0000_0000_0130);
		assert_istb(1);
		idat_i <= 32'b000000000000_00010_000_00000_1100111;
		tick(40);			// JALR X0, 0(X2)
		tick(41);
		tick(42);
		tick(43);
		tick(44);
		assert_iadr(64'h0000_0000_0048_0000);
		assert_istb(1);
		// OP-IMM-32
		idat_i <= 32'b000000000001_00000_000_00011_0010011;
		tick(50);			// ADDI X3, X0, 1
		tick(51);
		tick(52);
		tick(53);
		idat_i <= 32'b000000011111_00011_001_00011_0011011;
		tick(55);			// SLLIW X3, X3, 31
		tick(56);
		tick(57);
		tick(58);
		idat_i <= 32'b000000000000_00011_000_00000_1100111;
		tick(60);			// JALR X0, 0(X3)
		tick(61);
		tick(62);
		tick(63);
		tick(64);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_8000_0000);

		// Bug https://github.com/KestrelComputer/polaris/issues/18
		idat_i <= 32'b111111111111_00000_000_00001_0010011;	// ADDI X1, X0, -1
		tick(100);
		tick(101);
		tick(102);
		tick(103);
		idat_i <= 32'b000000000001_00001_010_00010_0010011;	// SLTI X2, X1, 1
		tick(105);
		tick(106);
		tick(107);
		tick(108);
		idat_i <= 32'b000000000000_00010_000_00000_1100111;	// JALR 0, 0(2)
		tick(110);
		tick(111);
		tick(112);
		tick(113);
		tick(114);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0001);

		idat_i <= 32'b111111111111_00000_000_00001_0010011;	// ADDI X1, X0, -1
		tick(100);
		tick(101);
		tick(102);
		tick(103);
		idat_i <= 32'b000000000001_00001_011_00010_0010011;	// SLTUI X2, X1, 1
		tick(105);
		tick(106);
		tick(107);
		tick(108);
		idat_i <= 32'b000000000000_00010_000_00000_1100111;	// JALR 0, 0(2)
		tick(110);
		tick(111);
		tick(112);
		tick(113);
		tick(114);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0000);
	end
	endtask

	// Exercise the CPU's ability to execute OP-R instructions.
	task test_op_r;
	begin
		scenario(2);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		iack_i <= 1;

		// We don't yet have loads implemented as I write this code,
		// so excrutiatingly tedious manual construction is required.
		// Please replace with cleaner code once design is bootstrapped.
		// ADDI X2, X0, -1
		idat_i <= 32'b111111111111_00000_000_00010_0010011;
		tick(0);
		tick(1);
		tick(2);
		tick(3);
		// ADDI X3, X0, $0AA
		idat_i <= 32'b000010101010_00000_000_00011_0010011;
		tick(5);
		tick(6);
		tick(7);
		tick(8);
		// ADDI X4, X0, $055
		idat_i <= 32'b000001010101_00000_000_00100_0010011;
		tick(10);
		tick(11);
		tick(12);
		tick(13);
		// SLLI X3, X3, 16
		idat_i <= 32'b000000010000_00011_001_00011_0010011;
		tick(15);
		tick(16);
		tick(17);
		tick(18);
		// XOR  X2, X2, X3
		idat_i <= 32'b0000000_00011_00010_100_00010_0110011;
		tick(20);
		tick(21);
		tick(22);
		tick(23);
		tick(24);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF14);

		// SLLI X3, X3, 8
		idat_i <= 32'b000000001000_00011_001_00011_0010011;
		tick(25);
		tick(26);
		tick(27);
		tick(28);
		// XOR  X2, X2, X3
		idat_i <= 32'b0000000_00011_00010_100_00010_0110011;
		tick(30);
		tick(31);
		tick(32);
		tick(33);
		tick(34);
		// SLLI X4, X4, 32
		idat_i <= 32'b000000100000_00100_001_00100_0010011;
		tick(35);
		tick(36);
		tick(37);
		tick(38);
		// XOR  X2, X2, X4
		idat_i <= 32'b0000000_00100_00010_100_00010_0110011;
		tick(40);
		tick(41);
		tick(42);
		tick(43);
		tick(44);
		// SLLI X4, X4, 8
		idat_i <= 32'b000000001000_00100_001_00100_0010011;
		tick(45);
		tick(46);
		tick(47);
		tick(48);
		// XOR  X2, X2, X4
		idat_i <= 32'b0000000_00100_00010_100_00010_0110011;
		tick(50);
		tick(51);
		tick(52);
		tick(53);
		tick(54);
		// JALR X0, 0(X2)
		idat_i <= 32'b000000000000_00010_000_00000_1100111;
		tick(90);			// JALR X0, 0(X2)
		tick(91);
		tick(92);
		tick(93);
		tick(94);
		assert_istb(1);
		assert_iadr(64'hFFFF_AAAA_5555_FFFF);
	end
	endtask

	task test_lui_auipc;
	begin
		scenario(3);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		iack_i <= 1;


		// LUI X2, $DEADBEEF
		idat_i <= 32'b1101_1110_1010_1101_1011_00010_0110111;
		tick(10);
		tick(11);
		tick(12);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF04);

		// JALR X0, 0(X2)
		idat_i <= 32'b000000000000_00010_000_00000_1100111;
		tick(20);
		tick(21);
		tick(22);
		tick(23);
		tick(24);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_DEAD_B000);

		// AUIPC X5, *+$524000
		idat_i <= 32'b0000_0000_0101_0010_0100_00101_0010111;
		tick(30);
		tick(31);
		tick(32);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_DEAD_B004);

		// JALR X0, 0(X5)
		idat_i <= 32'b000000000000_00101_000_00000_1100111;
		tick(40);
		tick(41);
		tick(42);
		tick(43);
		tick(44);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_DEFF_F000);
	end
	endtask

	task test_ld_st;
	begin
		scenario(4);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		assert_dsiz(2'b00);
		assert_dsigned(0);
		assert_dwe(0);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		iack_i <= 1;


		// LUI X2, $DEADBEEF
		idat_i <= 32'b1101_1110_1010_1101_1011_00010_0110111;
		tick(10);
		tick(11);
		tick(12);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF04);

		// LHU X1,$123(X2)
		idat_i <= 32'b0001_0010_0011_00010_101_00001_0000011;
		tick(20);
		tick(21);
		tick(22);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dsiz(2'b01);
		assert_dsigned(0);
		assert_dwe(0);
		assert_dadr(64'hFFFF_FFFF_DEAD_B123);

		tick(23);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dsiz(2'b01);
		assert_dsigned(0);
		assert_dwe(0);

		tick(24);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dsiz(2'b01);
		assert_dsigned(0);
		assert_dwe(0);

		ddat_i <= 64'h0000_0000_0000_FFFC;
		dack_i <= 1;
		tick(25);
		assert_dcyc(0);
		assert_dstb(0);
		assert_istb(1);

		// LB X1,4(X1)
		idat_i <= 32'b0000_0000_0100_00001_000_00001_0000011;
		tick(30);
		tick(31);
		tick(32);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dsiz(2'b00);
		assert_dsigned(1);
		assert_dwe(0);
		assert_dadr(64'h0000_0000_0001_0000);

		ddat_i <= 64'h0000_0000_0000_FFFC;
		dack_i <= 1;
		tick(35);
		assert_dcyc(0);
		assert_dstb(0);
		assert_istb(1);

		// SD X1, 12(X1)
		idat_i <= 32'b0000000_00001_00001_011_01100_0100011;
		dack_i <= 0;
		tick(40);
		tick(41);
		tick(42);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dsiz(2'b11);
		assert_dwe(1);
		assert_dadr(64'h0000_0000_0001_0008);
		assert_ddat(64'h0000_0000_0000_FFFC);

		tick(43);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dsiz(2'b11);
		assert_dwe(1);
		assert_dadr(64'h0000_0000_0001_0008);
		assert_ddat(64'h0000_0000_0000_FFFC);

		dack_i <= 1;
		tick(44);
		assert_dcyc(0);
		assert_dstb(0);
		assert_istb(1);
	end
	endtask

	task test_jal;
	begin
		scenario(5);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		assert_dsiz(2'b00);
		assert_dsigned(0);
		assert_dwe(0);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		iack_i <= 1;


		// JAL X5, *-$FF00
		idat_i <= 32'b1001_0000_0000_1111_0000_00101_1101111;
		tick(10);
		tick(11);
		tick(12);
		tick(13);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_0000);

		// SD X5, 0(X0)
		idat_i <= 32'b0000000_00101_00000_011_00000_0100011;
		tick(20);
		tick(21);
		tick(22);
		assert_dsiz(2'b11);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dadr(64'd0);
		assert_ddat(64'hFFFF_FFFF_FFFF_FF04);
		assert_dwe(1);
	end
	endtask

	task test_b;
	begin
		scenario(6);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		assert_dsiz(2'b00);
		assert_dsigned(0);
		assert_dwe(0);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		iack_i <= 1;

		//	addi	x1, x0, 0
		idat_i <= 32'b0000_0000_0000_00000_000_00001_0010011;
		tick(10);
		tick(11);
		tick(12);
		tick(13);
		assert_istb(1);

		//	beq	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_000_10000_1100011;
		tick(20);
		tick(21);
		tick(22);
		tick(23);
		tick(24);
		tick(25);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF14);

		//	bne	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_001_10000_1100011;
		tick(30);
		tick(31);
		tick(32);
		tick(33);
		tick(34);
		tick(35);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF18);

		//	blt	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_100_10000_1100011;
		tick(40);
		tick(41);
		tick(42);
		tick(43);
		tick(44);
		tick(45);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF1C);

		//	bge	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_101_10000_1100011;
		tick(50);
		tick(51);
		tick(52);
		tick(53);
		tick(54);
		tick(55);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF2C);

		//	bltu	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_110_10000_1100011;
		tick(60);
		tick(61);
		tick(62);
		tick(63);
		tick(64);
		tick(65);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF30);

		//	bgeu	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_111_10000_1100011;
		tick(70);
		tick(71);
		tick(72);
		tick(73);
		tick(74);
		tick(75);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF40);

		//	addi	x1, x0, -1
		idat_i <= 32'b1111_1111_1111_00000_000_00001_0010011;
		tick(110);
		tick(111);
		tick(112);
		tick(113);
		assert_istb(1);

		//	beq	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_000_10000_1100011;
		tick(120);
		tick(121);
		tick(122);
		tick(123);
		tick(124);
		tick(125);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF48);

		//	bne	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_001_10000_1100011;
		tick(130);
		tick(131);
		tick(132);
		tick(133);
		tick(134);
		tick(135);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF58);

		//	blt	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_100_10000_1100011;
		tick(140);
		tick(141);
		tick(142);
		tick(143);
		tick(144);
		tick(145);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF68);

		//	bge	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_101_10000_1100011;
		tick(150);
		tick(151);
		tick(152);
		tick(153);
		tick(154);
		tick(155);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF6C);

		//	bltu	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_110_10000_1100011;
		tick(160);
		tick(161);
		tick(162);
		tick(163);
		tick(164);
		tick(165);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF70);

		//	bgeu	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_111_10000_1100011;
		tick(170);
		tick(171);
		tick(172);
		tick(173);
		tick(174);
		tick(175);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF80);

		//	addi	x1, x0, 1
		idat_i <= 32'b0000_0000_0001_00000_000_00001_0010011;
		tick(210);
		tick(211);
		tick(212);
		tick(213);
		assert_istb(1);

		//	beq	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_000_10000_1100011;
		tick(220);
		tick(221);
		tick(222);
		tick(223);
		tick(224);
		tick(225);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF88);

		//	bne	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_001_10000_1100011;
		tick(230);
		tick(231);
		tick(232);
		tick(233);
		tick(234);
		tick(235);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF98);

		//	blt	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_100_10000_1100011;
		tick(240);
		tick(241);
		tick(242);
		tick(243);
		tick(244);
		tick(245);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF9C);

		//	bge	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_101_10000_1100011;
		tick(250);
		tick(251);
		tick(252);
		tick(253);
		tick(254);
		tick(255);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FFAC);

		//	bltu	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_110_10000_1100011;
		tick(260);
		tick(261);
		tick(262);
		tick(263);
		tick(264);
		tick(265);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FFB0);

		//	bgeu	x1, x0, *+16
		idat_i <= 32'b0000000_00000_00001_111_10000_1100011;
		tick(270);
		tick(271);
		tick(272);
		tick(273);
		tick(274);
		tick(275);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FFC0);
	end
	endtask

	task test_fence;
	begin
		scenario(7);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		assert_dsiz(2'b00);
		assert_dsigned(0);
		assert_dwe(0);

		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		iack_i <= 1;

		//	FENCE	10,5
		idat_i <= 32'b0000_1010_0101_00000_000_00000_0001111;
		tick(10);
		tick(11);
		tick(12);
		tick(13);
		tick(14);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF04);

		//	FENCE.I
		idat_i <= 32'b0000_0000_0000_00000_001_00000_0001111;
		tick(20);
		tick(21);
		tick(22);
		tick(23);
		tick(24);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF08);
	end
	endtask

	task test_e;
	begin
		scenario(8);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		assert_dsiz(2'b00);
		assert_dsigned(0);
		assert_dwe(0);

		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		assert_mie(0);
		assert_mpie(1);
		iack_i <= 1;

		//	ECALL
		idat_i <= 32'b000000000000_00000_000_00000_1110011;
		tick(10);		// Recognize the trap.
		assert_trap(1);
		assert_cause(11);
		tick(11);		// Internal cycle to set registers.
		assert_trap(0);	
		tick(12);		// Fetch first handler instruction.
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FE00);
		assert_mepc(64'hFFFF_FFFF_FFFF_FF00);
		assert_mie(0);
		assert_mpie(0);

		//	MRET
		idat_i <= 32'b0011_0000_0010_00000_000_00000_1110011;
		tick(30);
		tick(31);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_mie(0);
		assert_mpie(1);

		//	EBREAK
		idat_i <= 32'b000000000001_00000_000_00000_1110011;
		tick(20);
		assert_trap(1);
		assert_cause(3);
		tick(21);
		assert_trap(0);
		tick(22);
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FE00);
	end
	endtask

	task test_csrrw;
	begin
		scenario(9);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		assert_dsiz(2'b00);
		assert_dsigned(0);
		assert_dwe(0);

		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		assert_mie(0);
		assert_mpie(1);
		iack_i <= 1;

		// CSRRW X1, X2, $FFF	(guaranteed unsupported CSR)
		idat_i <= 32'b111111111111_00010_001_00001_1110011;
		tick(10);
		assert_cadr(12'hFFF);
		tick(11);
		assert_istb(0);
		assert_trap(1);
		assert_cause(2);
		tick(12);
		tick(13);
		assert_istb(1);
		assert_trap(0);

		// ADDI X1, X0, $AA
		idat_i <= 32'b000010101010_00000_000_00001_0011011;
		tick(20);
		tick(21);
		tick(22);
		tick(23);
		assert_istb(1);

		// CSRRW X0, X1, MSCRATCH
		idat_i <= 32'b001101000000_00001_001_00000_1110011;
		tick(30);
		tick(31);
		assert_coe(0);	// Rd = X0, so no CSR read!
		assert_cwe(1);
		assert_cdat(64'h0000_0000_0000_00aa);
		tick(32);

		// ADDI X1, X0, $55
		idat_i <= 32'b000001010101_00000_000_00001_0011011;
		tick(40);
		tick(41);
		tick(42);
		tick(43);
		assert_istb(1);

		// SB X1, 0(X1)
		idat_i <= 32'b0000000_00001_00001_000_00000_0100011;
		tick(45);
		tick(46);
		tick(47);
		assert_dsiz(2'b00);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dadr(64'h0000_0000_0000_0055);
		assert_ddat(64'h0000_0000_0000_0055);
		assert_dwe(1);
		tick(48);

		// CSRRW X1, X1, MSCRATCH
		idat_i <= 32'b001101000000_00001_001_00001_1110011;
		tick(50);
		tick(51);
		assert_coe(1);	// Rd = X1, so this time we read CSR
		assert_cwe(1);
		assert_cdat(64'h0000_0000_0000_0055);
		tick(52);

		// SB X1, 0(X1)
		idat_i <= 32'b0000000_00001_00001_000_00000_0100011;
		tick(60);
		tick(61);
		tick(62);
		assert_dsiz(2'b00);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dadr(64'h0000_0000_0000_00AA);
		assert_ddat(64'h0000_0000_0000_00AA);
		assert_dwe(1);
		tick(63);

		// CSRRW X1, X1, MSCRATCH
		idat_i <= 32'b001101000000_00001_001_00001_1110011;
		tick(70);
		tick(71);
		assert_coe(1);	// Rd = X1, so this time we read CSR
		assert_cwe(1);
		assert_cdat(64'h0000_0000_0000_00AA);
		tick(72);

		// SB X1, 0(X1)
		idat_i <= 32'b0000000_00001_00001_000_00000_0100011;
		tick(80);
		tick(81);
		tick(82);
		assert_dsiz(2'b00);
		assert_dcyc(1);
		assert_dstb(1);
		assert_dadr(64'h0000_0000_0000_0055);
		assert_ddat(64'h0000_0000_0000_0055);
		assert_dwe(1);
		tick(83);

		// CSRRWI X0, $1F, MSCRATCH
		idat_i <= 32'b001101000000_11111_101_00000_1110011;
		tick(90);
		tick(91);
		assert_coe(0);
		assert_cwe(1);
		assert_cdat(64'h0000_0000_0000_001F);
		tick(92);
	end
	endtask

	task test_csrrx;
	begin
		scenario(10);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		assert_dsiz(2'b00);
		assert_dsigned(0);
		assert_dwe(0);

		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		assert_mie(0);
		assert_mpie(1);
		iack_i <= 1;

		// ADDI X1, X0, 0
		idat_i <= 32'b000000000000_00000_000_00001_0011011;
		tick(10);
		tick(11);
		tick(12);
		tick(13);
		assert_istb(1);

		// CSRRW X1, X1, MSCRATCH
		idat_i <= 32'b001101000000_00001_001_00001_1110011;
		tick(20);
		tick(21);
		assert_cdat(64'h0);
		tick(22);
		assert_istb(1);

		// LD X1, 0(X1)		(load $AAAAAAAAAAAAAAAA)
		idat_i <= 32'b000000000000_00001_000_00001_0000011;
		tick(30);
		tick(31);
		tick(32);
		ddat_i <= 64'hAAAA_AAAA_AAAA_AAAA;
		dack_i <= 1;
		tick(33);
		assert_istb(1);

		// CSRRS X0, X1, MSCRATCH
		idat_i <= 32'b001101000000_00001_010_00000_1110011;
		tick(40);
		tick(41);
		tick(42);
		assert_cdat(64'hAAAA_AAAA_AAAA_AAAA);
		tick(43);
		assert_istb(1);

		// LD X1, 0(X1)		(load $5555555555555555)
		idat_i <= 32'b000000000000_00001_000_00001_0000011;
		tick(50);
		tick(51);
		tick(52);
		ddat_i <= 64'h5555_5555_5555_5555;
		dack_i <= 1;
		tick(53);
		assert_istb(1);

		// CSRRS X2, X1, MSCRATCH
		idat_i <= 32'b001101000000_00001_010_00010_1110011;
		tick(60);
		tick(61);
		tick(62);
		tick(63);
		assert_istb(1);

		// SD X2, 0(X2)		(check for AAAA...)
		idat_i <= 32'b0000000_00010_00010_011_00000_0100011;
		tick(70);
		tick(71);
		tick(72);
		assert_ddat(64'hAAAA_AAAA_AAAA_AAAA);
		tick(73);

		// CSRRW X2, X0, MSCRATCH
		idat_i <= 32'b001101000000_00000_001_00010_1110011;
		tick(80);
		tick(81);
		tick(82);

		// SD X2, 0(X2)		(check for FFFF...)
		idat_i <= 32'b0000000_00010_00010_011_00000_0100011;
		tick(90);
		tick(91);
		tick(92);
		assert_ddat(64'hFFFF_FFFF_FFFF_FFFF);
		tick(93);

		// CSRRCI X0, $1F, MSCRATCH
		idat_i <= 32'b001101000000_11111_111_00000_1110011;
		tick(100);
		tick(101);
		tick(102);
		tick(103);
		assert_istb(1);

		// CSRRW X1, X0, MSCRATCH
		idat_i <= 32'b001101000000_00000_001_00001_1110011;
		tick(110);
		tick(111);
		tick(112);

		// SD X1, 0(X1)
		idat_i <= 32'b0000000_00001_00001_011_00000_0100011;
		tick(120);
		tick(121);
		tick(122);
		assert_ddat(64'hFFFF_FFFF_FFFF_FFE0);
		tick(123);
	end
	endtask

	task test_irq;
	begin
		scenario(11);

		reset_i <= 1;
		tick(1);
		assert_istb(0);
		assert_dsiz(2'b00);
		assert_dsigned(0);
		assert_dwe(0);

		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_istb(1);
		assert_trap(0);
		assert_mie(0);
		assert_mpie(1);
		iack_i <= 1;

		// Interrupts are globally and locally disabled, so
		// we can twiddle the irq_i input with impunity.
		// That lets us verify signal routing.
		//	CSRRW	X1, X0, MIP
		idat_i <= 32'b0011_0100_0100_00000_001_00001_1110011;
		tick(1000);
		tick(1001);
		tick(1002);
		assert_istb(1);

		//	JALR	X0, 0(X1)	(address should be 0)
		idat_i <= 32'b000000000000_00001_000_00000_1100111;
		tick(1010);
		tick(1011);
		tick(1012);
		tick(1013);
		tick(1014);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0000);

		//	CSRRW	X1, X0, MIP
		irq_i <= 1;
		idat_i <= 32'b0011_0100_0100_00000_001_00001_1110011;
		tick(1000);
		tick(1001);
		tick(1002);
		assert_istb(1);

		//	JALR	X0, 0(X1)	(address should be $800)
		idat_i <= 32'b000000000000_00001_000_00000_1100111;
		tick(1010);
		tick(1011);
		tick(1012);
		tick(1013);
		tick(1014);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0800);

		// Test that the MIE bit in MSTATUS works as expected.
		// Make sure irq_i is negated so we don't accidentally trigger an IRQ.  :D
		//	CSRRW	X1, X0, MSTATUS
		irq_i <= 0;
		idat_i <= 32'b0011_0000_0000_00000_001_00001_1110011;
		tick(10);
		tick(11);
		tick(12);
		assert_istb(1);

		//	CSRRSI	X0, MSTATUS, 8		; Enable interrupts globally (MIE bit).
		idat_i <= 32'b0011_0000_0000_01000_110_00000_1110011;
		tick(20);
		tick(21);
		tick(22);
		tick(23);
		assert_istb(1);

		//	CSRRW	X2, X0, MSTATUS
		idat_i <= 32'b0011_0000_0000_00000_001_00010_1110011;
		tick(30);
		tick(31);
		tick(32);
		assert_istb(1);

		//	XOR	X1, X1, X2
		idat_i <= 32'b0000000_00010_00001_100_00001_0110011;
		tick(40);
		tick(41);
		tick(42);
		tick(43);
		tick(44);
		assert_istb(1);

		//	JALR	X0, 0(X1) ; should jump to address 8
		idat_i <= 32'b000000000000_00001_000_00000_1100111;
		tick(50);
		tick(51);
		tick(52);
		tick(53);
		tick(54);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0008);

		//	CSRRW	X1, X0, MIE	; Boot-time state of MIE should be 0.
		idat_i <= 32'b0011_0000_0100_00000_001_00001_1110011;
		tick(60);
		tick(61);
		tick(62);
		assert_istb(1);

		//	ADDI	X2, X0, $800	; don't care about high bits; they're ignored by MIE register.
		idat_i <= 32'b100000000000_00000_000_00010_0011011;
		tick(70);
		tick(71);
		tick(72);
		tick(73);
		assert_istb(1);

		//	CSRRW	X0, X2, MIE	; locally enable the external IRQ interrupt.
		idat_i <= 32'b0011_0000_0100_00010_001_00000_1110011;
		tick(80);
		tick(81);
		tick(82);
		assert_istb(1);

		//	CSRRW	X3, X0, MIE	; Double-check.
		idat_i <= 32'b0011_0000_0100_00000_001_00011_1110011;
		tick(90);
		tick(91);
		tick(92);
		assert_istb(1);

		//	XOR	X1, X1, X3
		idat_i <= 32'b0000000_00011_00001_100_00001_0110011;
		tick(100);
		tick(101);
		tick(102);
		tick(103);
		tick(104);
		assert_istb(1);

		//	JALR	X0, 0(X1)	; Should jump to address $800.
		idat_i <= 32'b000000000000_00001_000_00000_1100111;
		tick(110);
		tick(111);
		tick(112);
		tick(113);
		tick(114);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0800);

		// Now to test interrupt detection.
		irq_i <= 1;
		idat_i <= 32'b000000000001_00000_000_00000_1110011;
		tick(120);	// Take the IRQ here; priority over EBREAK.  Single cycle, baby!
		assert_istb(1);
		assert_iadr(64'hFFFF_FFFF_FFFF_FE00);
		//	CSRRW X1, X0, MCAUSE
		idat_i <= 32'b0011_0100_0010_00000_001_00001_1110011;
		tick(121);
		tick(122);
		tick(123);
		assert_istb(1);
		//	JALR X0, 0(X1)
		idat_i <= 32'b000000000000_00001_000_00000_1100111;
		tick(130);
		tick(131);
		tick(132);
		tick(133);
		tick(134);
		assert_istb(1);
		assert_iadr(64'h8000_0000_0000_000B);
		//	MRET
		irq_i <= 0;	// software does something to kill this signal earlier, somehow.
		idat_i <= 32'b0011_0000_0010_00000_000_00000_1110011;
		tick(140);
		tick(141);
		assert_istb(1);
		assert_iadr(64'h0000_0000_0000_0800);
	end
	endtask

	initial begin
		clk_i <= 0;
		reset_i <= 0;
		iack_i <= 0;
		dack_i <= 0;
		idat_i <= 32'h0000_0000;	// Guaranteed illegal instruction
		ddat_i <= 64'h0000_0000_0000_0000;
		cvalid_i <= 0;
		cdat_i <= 64'd0;
		irq_i <= 0;

		test_bootstrap();
		test_op_i();
		test_op_r();
		test_lui_auipc();
		test_ld_st();
		test_jal();
		test_b();
		test_fence();
		test_e();
		test_csrrw();
		test_csrrx();
		test_irq();
		$display("@I Done."); $stop;
	end
endmodule

