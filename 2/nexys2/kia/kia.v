`timescale 1ns / 1ps

module KIA_M(
	input CLK_I,
	input RES_I,
	input [0:0] ADR_I,
	input WE_I,
	input CYC_I,
	input STB_I,
	output ACK_O,
	output [7:0] DAT_O,
	
	input D_I,
	input C_I
);

// STORY 0000
// We want the KIA to respond to bus transactions as close to a single cycle as
// possible.  Since we're using fully synchronous bus logic, that actually means
// _two_ cycle turn-around.  The CPU sets up the bus during cycle N, and we assert
// ACK_O during cycle N+1.  The CPU would then commence the next cycle at N+2.

	reg ack;
	assign ACK_O = ack;

	always @(posedge CLK_I) begin
		if(~RES_I) begin
			ack <= CYC_I & STB_I;
		end
	end

// STORY 0000,0010,0020
// When reading the status register, we want to put the contents of the queue
// status register on the data bus.
//
// When reading the head of the queue, we want a copy of the current data byte,
// if any.

	reg [7:0] dat;
	assign DAT_O = dat;

	reg byte_received;

	always @(posedge CLK_I) begin
		if(~RES_I) begin
			case(ADR_I)
				1'h0: dat <= {7'b0000000, ~byte_received};
				1'h1: dat <= sr[8:1];
			endcase
		end
	end

// STORY 0010
// When receiving a character code from the PS/2 port, we want to shift it into
// a shift register for later processing.  We know that the character code is
// fully received when we've received 11 bits, including a start and stop bit.
// We ignore parity bit.
//
// We synchronize the PS/2 clock against the system clock with cur_C.  Without this
// synchrony, we end up missing clocking events, thus dropping bits from the port,
// thus creating a framing error.  prev_C is used to detect negative edges on the
// PS/2 clock signal.

	reg [10:0] sr;
	reg cur_C;
	reg prev_C;
	reg [3:0] bits_received;
	wire ps2clk_edge = ~cur_C && prev_C;
	wire waiting_for_start_bit = bits_received == 0;
	wire waiting_for_stop_bit = bits_received == 10;
	wire is_start_bit = D_I == 0;
	wire is_stop_bit = D_I == 1;

	always @(posedge CLK_I) begin
		if(~RES_I) begin
			cur_C <= C_I;
			if(ps2clk_edge && waiting_for_start_bit && is_start_bit) begin
				sr <= {D_I, sr[10:1]};
				bits_received <= bits_received+1;
			end
			if(ps2clk_edge && ~waiting_for_stop_bit && ~waiting_for_start_bit) begin
				sr <= {D_I, sr[10:1]};
				bits_received <= bits_received+1;
			end
			if(ps2clk_edge && waiting_for_stop_bit && is_stop_bit) begin
				sr <= {D_I, sr[10:1]};
				byte_received <= 1;
				bits_received <= 0;
			end
			prev_C <= cur_C;
		end
	end

	always @(posedge CLK_I) begin
		if(RES_I) begin
			ack <= 0;
			dat <= 8'h00;
			sr <= 11'h7FF;
			prev_C <= 1;
			cur_C <= 1;
			byte_received <= 0;
			bits_received <= 0;
		end
	end
endmodule
