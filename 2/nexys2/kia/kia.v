`timescale 1ns / 1ps

//
// KIA registers
//

`define KQSTAT		0
`define KQDATA		1

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

// STORY 0000,0010,0020,0050
// When reading the status register, we want to put the contents of the queue
// status register on the data bus.  The queue status register has the following
// bit-level mapping:
//		Bit 0		0=queue is not empty; at least one byte is waiting to be read.
//					1=queue is empty.
//
//		Bit 1		0=queue is not (yet) full; room for at least one byte remains.
//					1=queue is full.  Any additional data coming from the peripheral
//					  will be dropped.
//
// When reading the head of the queue, we want a copy of the current data byte,
// if any.
//
// STORY 0030, 0050
// When the CPU writes to the keyboard queue head register, it pops the queue.  We ignore the value
// actually written.  If the queue is already empty, take no action.
	

	reg [7:0] dat;
	assign DAT_O = dat;

	reg byte_received;

	always @(posedge CLK_I) begin
		if(~RES_I) begin
			if(~WE_I) begin
				case(ADR_I)
					`KQSTAT: dat <= {7'b000000, queue_full, queue_empty};
					`KQDATA: dat <= queue[rp];
				endcase
			end else begin
				case(ADR_I)
					`KQDATA: rp <= (queue_empty)? rp : rp+1;
				endcase
			end
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
			if(ps2clk_edge && waiting_for_stop_bit && is_stop_bit && ~queue_full) begin
				queue[wp] <= sr[9:2];
				wp <= next_wp;
				bits_received <= 0;
			end
			if(ps2clk_edge && waiting_for_stop_bit && is_stop_bit && queue_full) begin
				bits_received <= 0;
			end
			prev_C <= cur_C;
		end
	end

	// STORY 0030,0040,0050
	// We need a queue of bytes received to hold unread data.  The queue is 16-elements deep.  Thus,
	// we need 4-bit addresses into the queue memory.
	//
	// The queue is considered full when writing a new byte threatens to overwrite the byte addressed
	// by the read pointer.
	//
	// Likewise, the queue is considered empty when the read pointer matches the write pointer.

	reg [7:0] queue[0:15];
	reg [3:0] rp;
	reg [3:0] wp;
	wire [3:0] next_wp = wp+1;
	wire queue_full = (next_wp == rp);
	wire queue_empty = (rp == wp);

	always @(posedge CLK_I) begin
		if(RES_I) begin
			ack <= 0;
			dat <= 8'h00;
			sr <= 11'h7FF;
			prev_C <= 1;
			cur_C <= 1;
			byte_received <= 0;
			bits_received <= 0;
			queue[0] <= 8'hC0;			// This is entirely for debugging purposes.
			queue[1] <= 8'hC1;			// After active development, we can remove these.
			queue[2] <= 8'hC2;			// Even the unit tests won't depend on these values.
			queue[3] <= 8'hC3;
			queue[4] <= 8'hC4;
			queue[5] <= 8'hC5;
			queue[6] <= 8'hC6;
			queue[7] <= 8'hC7;
			queue[8] <= 8'hC8;
			queue[9] <= 8'hC9;
			queue[10] <= 8'hCA;
			queue[11] <= 8'hCB;
			queue[12] <= 8'hCC;
			queue[13] <= 8'hCD;
			queue[14] <= 8'hCE;
			queue[15] <= 8'hCF;
			wp <= 0;
			rp <= 0;
		end
	end
endmodule
