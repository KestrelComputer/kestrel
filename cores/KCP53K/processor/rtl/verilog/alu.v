`timescale 1ns / 1ps

// The Arithmetic/Logic Unit (ALU) is responsible for performing the arithmetic
// and bitwise logical operations the computer depends upon to calculate
// everything from effective addresses for looking stuff up in memory, all the
// way to medical imaging.  (OK, the latter might have some help from floating
// point units later on, but I digress.)

module alu(
	input	[63:0]	inA_i,
	input	[63:0]	inB_i,
	input		cflag_i,
	input		sum_en_i,
	input		and_en_i,
	input		xor_en_i,
	input		invB_en_i,
	input		lsh_en_i,
	input		rsh_en_i,
	input		ltu_en_i,	// See issue https://github.com/KestrelComputer/polaris/issues/18
	input		lts_en_i,	// See issue https://github.com/KestrelComputer/polaris/issues/18
	output	[63:0]	out_o,
	output		cflag_o,
	output		vflag_o,
	output		zflag_o
);
	wire [63:0] b = inB_i ^ ({64{invB_en_i}});

	wire [63:0] sumL = inA_i[62:0] + b[62:0] + {62'b0, cflag_i};
	wire c62 = sumL[63];
	wire [64:63] sumH = inA_i[63] + b[63] + c62;
	wire [63:0] rawSums = {sumH[63], sumL[62:0]};

	wire [63:0] sums = sum_en_i ? rawSums : 64'd0;
	assign zflag_o = ~(|out_o);
	assign vflag_o = sumH[64] ^ sumL[63];
	assign cflag_o = sumH[64];

	wire [63:0] ands = and_en_i ? (inA_i & b) : 64'd0;
	wire [63:0] xors = xor_en_i ? (inA_i ^ b) : 64'd0;

	wire [63:0] lsh32 = inB_i[5] ? {inA_i[31:0], 32'd0} : inA_i;
	wire [63:0] lsh16 = inB_i[4] ? {lsh32[47:0], 16'd0} : lsh32;
	wire [63:0] lsh8  = inB_i[3] ? {lsh16[55:0], 8'd0} : lsh16;
	wire [63:0] lsh4  = inB_i[2] ? {lsh8[59:0], 4'd0} : lsh8;
	wire [63:0] lsh2  = inB_i[1] ? {lsh4[61:0], 2'd0} : lsh4;
	wire [63:0] lsh1  = inB_i[0] ? {lsh2[62:0], 1'd0} : lsh2;
	wire [63:0] lshs = lsh_en_i ? lsh1 : 0;

	wire [63:32] sx5 = cflag_i ? {32{inA_i[63]}} : 0;
	wire [63:0] rsh32 = inB_i[5] ? {sx5, inA_i[63:32]} : inA_i;
	wire [63:48] sx4 = cflag_i ? {16{rsh32[63]}} : 0;
	wire [63:0] rsh16 = inB_i[4] ? {sx4, rsh32[63:16]} : rsh32;
	wire [63:56] sx3 = cflag_i ? {8{rsh16[63]}} : 0;
	wire [63:0] rsh8  = inB_i[3] ? {sx3, rsh16[63:8]} : rsh16;
	wire [63:60] sx2 = cflag_i ? {4{rsh8[63]}} : 0;
	wire [63:0] rsh4  = inB_i[2] ? {sx2, rsh8[63:4]} : rsh8;
	wire [63:62] sx1 = cflag_i ? {2{rsh4[63]}} : 0;
	wire [63:0] rsh2  = inB_i[1] ? {sx1, rsh4[63:2]} : rsh4;
	wire sx0 = cflag_i & rsh2[63];

	wire [63:0] rsh1  = inB_i[0] ? {sx0, rsh2[63:1]} : rsh2;
	wire [63:0] rshs = rsh_en_i ? rsh1 : 0;

	wire isLTS = lts_en_i ? {63'd0, rawSums[63] ^ vflag_o} : 0;
	wire isLTU = ltu_en_i ? {63'd0, ~cflag_o} : 0;

	assign out_o = sums | ands | xors | lshs | rshs | isLTS | isLTU;
endmodule
