`timescale 1ns / 1ps

`define	OPC_NOP		4'b0000
`define	OPC_LI		4'b0001
`define	OPC_FWM		4'b0010
`define	OPC_SWM		4'b0011
`define	OPC_ADD		4'b0100
`define	OPC_AND		4'b0101
`define	OPC_XOR		4'b0110
`define	OPC_ZGO		4'b0111
`define	OPC_unk8		4'b1000
`define	OPC_unk9		4'b1001
`define	OPC_FBM		4'b1010
`define	OPC_SBM		4'b1011
`define	OPC_LCALL	4'b1100
`define	OPC_ICALL	4'b1101
`define	OPC_GO		4'b1110
`define	OPC_NZGO		4'b1111

module S16X4A(
	input					clk_i,
	input					res_i,
	output	[15:1]	adr_o,
	output				we_o,
	output				cyc_o,
	output				stb_o,
	output	[1:0]		sel_o,
	output				vda_o,
	output				vpa_o,
	output	[15:0]	dat_o,
	input					ack_i,
	input		[15:0]	dat_i
);

	reg	[15:1]	adr;
	reg				we;
	reg				cyc;
	reg	[1:0]		sel;
	reg				vda;
	reg				vpa;
	reg	[15:0]	dat;

	assign adr_o = adr;
	assign we_o  = we;
	assign cyc_o = cyc;
	assign stb_o = cyc;
	assign sel_o = sel;
	assign vda_o = vda;
	assign vpa_o = vpa;
	assign dat_o = dat;

	// STORY 0010
	wire				cycle_done = (cyc & ack_i) | ~cyc;

	reg	[4:0]		t;
	reg	[15:1]	p;
	reg	[15:0]	u, v, w, x, y, z, next_u, next_v, next_w, next_x, next_y, next_z;
	reg	[15:0]	ir;
	reg				res1, res2;
	
	wire				reset = (res1 | res2);
	wire				y_is_zero = y == 0;
	wire				t0 = t[0];
	wire				no_more_instructions = t0 ? (dat_i == 16'h0000) : (ir[11:0] == 12'h000);
	wire	[3:0]		current_opcode = ir[15:12];
	wire				increment_p = t0 | (current_opcode == `OPC_LI);
	wire				branch_taken = ((current_opcode == `OPC_ZGO) && y_is_zero) | ((current_opcode == `OPC_NZGO) && ~y_is_zero) | (current_opcode == `OPC_GO) | (current_opcode == `OPC_ICALL);
	wire				lcall_taken = current_opcode == `OPC_LCALL;
	wire	[15:1]	lcall_address = p + {ir[11], ir[11], ir[11], ir[11:0]};
	wire				goto_t0 = reset | no_more_instructions | branch_taken | lcall_taken;
	wire	[15:1]	next_p = reset ? 0 : (increment_p ? p+1 : (branch_taken ? z[15:1] : (lcall_taken ? lcall_address : p)));
	wire	[4:0]		next_t = goto_t0 ? 5'b00001 : (t << 1);
	wire	[15:0]	sum = y + z;
	wire	[15:0]	mask = y & z;
	wire	[15:0]	flips = y ^ z;

	always @(*) begin
		if(reset) begin
			adr <= 0;
			we <= 0;
			cyc <= 0;
			sel <= 2'b00;
			vda <= 0;
			vpa <= 0;
			dat <= 0;
			next_u <= u;
			next_v <= v;
			next_w <= w;
			next_x <= x;
			next_y <= y;
			next_z <= z;
		end
		else if(t0)	begin
			adr <= p;
			we <= 0;
			cyc <= 1;
			sel <= 2'b11;
			vda <= 0;
			vpa <= 1;
			dat <= 0;
			next_u <= u;
			next_v <= v;
			next_w <= w;
			next_x <= x;
			next_y <= y;
			next_z <= z;
		end
		else begin
			case(current_opcode)
			// // THE ORIGINAL STEAMER-16 INSTRUCTION SET (as defined by Myron Plichota)
			`OPC_NOP:	begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= v;
								next_w <= w;
								next_x <= x;
								next_y <= y;
								next_z <= z;
							end
							
			`OPC_LI:	begin
								we <= 0;
								cyc <= 1;
								sel <= 2'b11;
								vda <= 1;
								vpa <= 1;
								adr <= p;
								dat <= 0;
								next_u <= v;
								next_v <= w;
								next_w <= x;
								next_x <= y;
								next_y <= z;
								next_z <= dat_i;
							end
			`OPC_FWM:	begin
								we <= 0;
								cyc <= 1;
								sel <= 2'b11;
								vda <= 1;
								vpa <= 0;
								adr <= z[15:1];
								dat <= 0;
								next_u <= u;
								next_v <= v;
								next_w <= w;
								next_x <= x;
								next_y <= y;
								next_z <= dat_i;
							end
			`OPC_SWM:	begin
								we <= 1;
								cyc <= 1;
								sel <= 2'b11;
								vda <= 1;
								vpa <= 0;
								adr <= z[15:1];
								dat <= y;
								next_u <= u;
								next_v <= u;
								next_w <= u;
								next_x <= v;
								next_y <= w;
								next_z <= x;
							end
			`OPC_ADD:	begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= u;
								next_w <= v;
								next_x <= w;
								next_y <= x;
								next_z <= sum;
							end
			`OPC_AND:	begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= u;
								next_w <= v;
								next_x <= w;
								next_y <= x;
								next_z <= mask;
							end
			`OPC_XOR:	begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= u;
								next_w <= v;
								next_x <= w;
								next_y <= x;
								next_z <= flips;
							end
			`OPC_ZGO:	begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= u;
								next_w <= u;
								next_x <= v;
								next_y <= w;
								next_z <= x;
								// See also the branch_taken wire.
							end
			
			// STEAMER S16X4-1A EXTENDED INSTRUCTIONS HERE.

			`OPC_FBM:	begin
								we <= 0;
								cyc <= 1;
								sel <= {z[0], ~z[0]};
								vda <= 1;
								vpa <= 0;
								adr <= z[15:1];
								dat <= 0;
								next_u <= u;
								next_v <= v;
								next_w <= w;
								next_x <= x;
								next_y <= y;
								next_z <= z[0] ? {8'b00000000, dat_i[15:8]} : {8'b00000000, dat_i[7:0]};
							end
			`OPC_SBM:	begin
								we <= 1;
								cyc <= 1;
								sel <= {z[0], ~z[0]};
								vda <= 1;
								vpa <= 0;
								adr <= z[15:1];
								dat <= z[0] ? {y[7:0], 8'b00000000} : {8'b00000000, y[7:0]};
								next_u <= u;
								next_v <= u;
								next_w <= u;
								next_x <= v;
								next_y <= w;
								next_z <= x;
							end
			`OPC_LCALL: begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= v;
								next_v <= w;
								next_w <= x;
								next_x <= y;
								next_y <= z;
								next_z <= {p, 1'b0};
								// See also the lcall_taken wire.
							end
			`OPC_ICALL:	begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= v;
								next_w <= w;
								next_x <= x;
								next_y <= y;
								next_z <= {p, 1'b0};
								// See also the branch_taken wire.
							end
			`OPC_GO:		begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= u;
								next_w <= v;
								next_x <= w;
								next_y <= x;
								next_z <= y;
								// See also the branch_taken wire.
							end
			`OPC_NZGO:	begin
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								adr <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= u;
								next_w <= u;
								next_x <= v;
								next_y <= w;
								next_z <= x;
								// See also the branch_taken wire.
							end

			// To make Verilog compiler happy only.  It can be proven that this
			// condition never actually occurs in practice.
			default:		begin
								adr <= 0;
								we <= 0;
								cyc <= 0;
								sel <= 2'b00;
								vda <= 0;
								vpa <= 0;
								dat <= 0;
								next_u <= u;
								next_v <= v;
								next_w <= w;
								next_x <= x;
								next_y <= y;
								next_z <= z;
							end
			endcase
		end
	end

	always @(posedge clk_i) begin
		res2 <= res1;
		res1 <= res_i;

		if(reset || cycle_done) begin
			t <= next_t;
			p <= next_p;
		end
		if(cycle_done) begin
			if(t0)		ir <= dat_i;
			else			ir <= {ir[11:0], 4'b0000};
			u <= next_u;
			v <= next_v;
			w <= next_w;
			x <= next_x;
			y <= next_y;
			z <= next_z;
		end
	end
	
	// Some random initial values, potentially in an inconsistent state until the processor is reset.
	initial begin
		ir <= 16'hFFFF;
		we <= 0;
		cyc <= 1;
		sel <= 2'b00;
		vda <= 1;
		vpa <= 0;
		dat <= 16'hBEEF;
		u <= 16'hC000;
		v <= 16'hC001;
		w <= 16'hC002;
		x <= 16'hCC00;
		y <= 16'hCC11;
		z <= 16'hCC22;
	end
endmodule
