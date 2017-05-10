`timescale 1ns / 1ps

module test_bottleneck();
	reg clk_i, reset_i;
	reg [15:0] story_i;

	reg	[63:0]	m_adr_i;
	reg		m_cyc_i;
	reg	[63:0]	m_dat_i;
	reg		m_signed_i;
	reg	[1:0]	m_siz_i;
	reg		m_stb_i;
	reg		m_we_i;
	wire		m_ack_o;
	wire	[63:0]	m_dat_o;
	wire		m_err_align_o;

	wire	[63:0]	s_adr_o;
	wire		s_cyc_o;
	wire	[15:0]	s_dat_o;
	wire		s_signed_o;
	wire		s_siz_o;
	wire		s_stb_o;
	wire		s_we_o;
	reg		s_ack_i;
	reg	[15:0]	s_dat_i;

	bottleneck b(
		.m_adr_i(m_adr_i),
		.m_cyc_i(m_cyc_i),
		.m_dat_i(m_dat_i),
		.m_signed_i(m_signed_i),
		.m_siz_i(m_siz_i),
		.m_stb_i(m_stb_i),
		.m_we_i(m_we_i),
		.m_ack_o(m_ack_o),
		.m_dat_o(m_dat_o),
		.m_err_align_o(m_err_align_o),
		.s_adr_o(s_adr_o),
		.s_cyc_o(s_cyc_o),
		.s_signed_o(s_signed_o),
		.s_siz_o(s_siz_o),
		.s_stb_o(s_stb_o),
		.s_we_o(s_we_o),
		.s_ack_i(s_ack_i),
		.s_dat_i(s_dat_i),
		.s_dat_o(s_dat_o),
		.clk_i(clk_i),
		.reset_i(reset_i)
	);

	always begin
		#20 clk_i <= ~clk_i;
	end

	task tick;
	input [7:0] substory;
	begin
		story_i <= {story_i[15:8], substory};
		wait(clk_i);
		wait(~clk_i);
		#5;
	end
	endtask

	task scenario;
	input [7:0] story;
	begin
		story_i <= {story, 8'h00};
		tick(8'h00);
		$display("@S SCENARIO %0d (8'h%02X)", story, story);
	end
	endtask

	task assert_s_adr_o;
	input [63:0] expected;
	begin
		if(s_adr_o !== expected) begin
			$display("@E %04X S_ADR_O Expected $%016X Got $%016X", story_i, expected, s_adr_o);
			$stop;
		end
	end
	endtask

	task assert_s_cyc_o;
	input expected;
	begin
		if(s_cyc_o !== expected) begin
			$display("@E %04X S_CYC_O Expected %d Got %d", story_i, expected, s_cyc_o);
			$stop;
		end
	end
	endtask

	task assert_s_signed_o;
	input expected;
	begin
		if(s_signed_o !== expected) begin
			$display("@E %04X S_SIGNED_O Expected %d Got %d", story_i, expected, s_signed_o);
			$stop;
		end
	end
	endtask

	task assert_s_siz_o;
	input expected;
	begin
		if(s_siz_o !== expected) begin
			$display("@E %04X S_SIZ_O Expected %d Got %d", story_i, expected, s_siz_o);
			$stop;
		end
	end
	endtask

	task assert_s_stb_o;
	input expected;
	begin
		if(s_stb_o !== expected) begin
			$display("@E %04X S_STB_O Expected %d Got %d", story_i, expected, s_stb_o);
			$stop;
		end
	end
	endtask

	task assert_s_we_o;
	input expected;
	begin
		if(s_we_o !== expected) begin
			$display("@E %04X S_WE_O Expected %d Got %d", story_i, expected, s_we_o);
			$stop;
		end
	end
	endtask

	task assert_s_dat_o;
	input [15:0] expected;
	begin
		if(s_dat_o !== expected) begin
			$display("@E %04X S_DAT_O Expected %04X Got %04X", story_i, expected, s_dat_o);
			$stop;
		end
	end
	endtask

	task assert_m_ack_o;
	input expected;
	begin
		if(m_ack_o !== expected) begin
			$display("@E %04X M_ACK_O Expected %d Got %d", story_i, expected, m_ack_o);
			$stop;
		end
	end
	endtask

	task assert_m_dat_o;
	input [63:0] expected;
	begin
		if(m_dat_o !== expected) begin
			$display("@E %04X M_DAT_O Expected %016X Got %016X", story_i, expected, m_dat_o);
			$stop;
		end
	end
	endtask

	task assert_m_err_align_o;
	input expected;
	begin
		if(m_err_align_o !== expected) begin
			$display("@E %04X M_ERR_ALIGN_O Expected %d Got %d", story_i, expected, m_err_align_o);
			$stop;
		end
	end
	endtask

	task test_byte_rd;
	begin
		scenario(1);

		m_adr_i <= 64'h4444_3333_2222_1111;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b00;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h01);
		assert_m_err_align_o(0);
		assert_s_adr_o(64'h4444_3333_2222_1111);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(2'b00);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_ack_i <= 0;
		s_dat_i <= 16'h00AA;
		tick(8'h02);
		assert_m_ack_o(0);

		s_ack_i <= 1;
		tick(8'h03);
		assert_m_ack_o(1);
		assert_m_dat_o(64'hFFFF_FFFF_FFFF_FFAA);

		m_signed_i <= 0;
		tick(8'h04);
		assert_m_dat_o(64'h0000_0000_0000_00AA);
	end
	endtask

	task test_byte_wr;
	begin
		scenario(2);

		m_adr_i <= 64'h4444_3333_2222_1111;
		m_cyc_i <= 1;
		m_dat_i <= 64'hAAAA_BBBB_CCCC_DDDD;
		m_signed_i <= 1;
		m_siz_i <= 2'b00;
		m_stb_i <= 1;
		m_we_i  <= 1;
		tick(8'h01);
		assert_m_err_align_o(0);
		assert_s_adr_o(64'h4444_3333_2222_1111);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(0);
		assert_s_stb_o(1);
		assert_s_we_o(1);
		assert_s_dat_o(16'h00DD);

		s_ack_i <= 0;
		tick(8'h02);
		assert_m_ack_o(0);

		s_ack_i <= 1;
		tick(8'h03);
		assert_m_ack_o(1);
	end
	endtask

	task test_hword_rd;
	begin
		scenario(3);

		s_ack_i <= 0;
		m_adr_i <= 64'h4444_3333_2222_1111;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b01;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h01);
		assert_m_err_align_o(1);
		assert_m_ack_o(0);
		assert_s_stb_o(0);
		assert_s_cyc_o(0);

		s_ack_i <= 1;
		tick(8'h02);
		assert_m_err_align_o(1);
		assert_m_ack_o(0);
		assert_s_stb_o(0);
		assert_s_cyc_o(0);
		
		m_adr_i <= 64'h4444_3333_2222_1112;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b01;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h03);
		assert_m_err_align_o(0);
		assert_s_adr_o(64'h4444_3333_2222_1112);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_ack_i <= 0;
		s_dat_i <= 16'hAA55;
		tick(8'h04);
		assert_m_ack_o(0);

		s_ack_i <= 1;
		tick(8'h05);
		assert_m_ack_o(1);
		assert_m_dat_o(64'hFFFF_FFFF_FFFF_AA55);

		m_signed_i <= 0;
		tick(8'h06);
		assert_m_dat_o(64'h0000_0000_0000_AA55);
	end
	endtask

	task test_hword_wr;
	begin
		scenario(4);

		s_ack_i <= 1;
		m_adr_i <= 64'h4444_3333_2222_1111;
		m_cyc_i <= 1;
		m_dat_i <= 64'hAAAA_BBBB_CCCC_DDDD;
		m_signed_i <= 1;
		m_siz_i <= 2'b01;
		m_stb_i <= 1;
		m_we_i  <= 1;
		tick(8'h01);
		assert_m_err_align_o(1);
		assert_m_ack_o(0);
		assert_s_stb_o(0);
		assert_s_cyc_o(0);

		s_ack_i <= 0;
		tick(8'h02);
		assert_m_err_align_o(1);
		assert_m_ack_o(0);
		assert_s_stb_o(0);
		assert_s_cyc_o(0);

		m_adr_i <= 64'h4444_3333_2222_1112;
		m_cyc_i <= 1;
		m_dat_i <= 64'hAAAA_BBBB_CCCC_DDDD;
		m_signed_i <= 1;
		m_siz_i <= 2'b01;
		m_stb_i <= 1;
		m_we_i  <= 1;
		tick(8'h03);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_s_adr_o(64'h4444_3333_2222_1112);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(1);
		assert_s_dat_o(16'hDDDD);

		s_ack_i <= 1;
		tick(8'h04);
		assert_m_err_align_o(0);
		assert_m_ack_o(1);
	end
	endtask

	task test_word_rd;
	begin
		scenario(5);

		s_ack_i <= 0;
		m_adr_i <= 64'h4444_3333_2222_1111;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b10;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h01);
		assert_m_err_align_o(1);
		assert_m_ack_o(0);
		assert_s_stb_o(0);
		assert_s_cyc_o(0);

		s_ack_i <= 0;
		m_adr_i <= 64'h4444_3333_2222_1112;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b10;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h02);
		assert_m_err_align_o(1);
		assert_m_ack_o(0);
		assert_s_stb_o(0);
		assert_s_cyc_o(0);

		s_ack_i <= 0;
		m_adr_i <= 64'h4444_3333_2222_1113;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b10;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h03);
		assert_m_err_align_o(1);
		assert_m_ack_o(0);
		assert_s_stb_o(0);
		assert_s_cyc_o(0);

		s_ack_i <= 0;
		m_adr_i <= 64'h4444_3333_2222_1114;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b10;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h04);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_s_adr_o(64'h4444_3333_2222_1116);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_ack_i <= 1;
		s_dat_i <= 16'hDEAD;
		tick(8'h05);
		assert_m_err_align_o(0);
		// NOTE: m_ack_o is asserted ONLY because we've just entered into
		// the 2nd cycle of a two-cycle transaction.  This means that whatever
		// appears on s_ack_i will be channeled to m_ack_o.  We clear s_ack_i
		// below.
		assert_m_ack_o(1);
		assert_m_dat_o(64'hFFFF_FFFF_DEAD_DEAD);
		assert_s_adr_o(64'h4444_3333_2222_1114);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_ack_i <= 0;
		s_dat_i <= 16'hBEEF;
		tick(8'h06);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_m_dat_o(64'hFFFF_FFFF_DEAD_BEEF);

		// Transient response testing.

		s_ack_i <= 1;
		#5;
		assert_m_ack_o(1);
		tick(8'h07);
		#60;
		assert_m_ack_o(0);

		m_siz_i <= 2'b01;
		#5;
		assert_m_ack_o(1);
	end
	endtask

	task test_word_wr;
	begin
		scenario(6);

		s_ack_i <= 0;
		m_adr_i <= 64'h4444_3333_2222_1114;
		m_cyc_i <= 1;
		m_dat_i <= 64'h1111_2222_3333_4444;
		m_signed_i <= 1;
		m_siz_i <= 2'b10;
		m_stb_i <= 1;
		m_we_i  <= 1;
		tick(8'h01);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_s_adr_o(64'h4444_3333_2222_1116);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(1);
		assert_s_dat_o(16'h3333);

		s_ack_i <= 1;
		tick(8'h05);
		assert_m_err_align_o(0);
		// NOTE: m_ack_o is asserted ONLY because we've just entered into
		// the 2nd cycle of a two-cycle transaction.  This means that whatever
		// appears on s_ack_i will be channeled to m_ack_o.  We clear s_ack_i
		// below.
		assert_m_ack_o(1);
		assert_s_adr_o(64'h4444_3333_2222_1114);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(1);
		assert_s_dat_o(16'h4444);

		s_ack_i <= 0;
		tick(8'h06);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);

		s_ack_i <= 1;
		// NOTE: m_ack_o is asserted after the above statement becomes true.
		// However, at the next clock tick, m_ack_o will drop back to 0, since
		// the bridge will try to start another 32-bit write cycle again.
		tick(8'h07);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
	end
	endtask

	task test_dword_rd;
	begin
		scenario(7);

		// In this test, we just drive our bus at maximum speed.

		s_ack_i <= 1;
		m_adr_i <= 64'h4444_3333_2222_1114;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b11;
		m_stb_i <= 1;
		m_we_i  <= 0;
		tick(8'h01);
		assert_m_err_align_o(1);
		assert_m_ack_o(0);
		assert_s_stb_o(0);
		assert_s_cyc_o(0);

		m_adr_i <= 64'h4444_3333_2222_1118;
		m_cyc_i <= 1;
		m_dat_i <= 64'h0000_0000_0000_0000;
		m_signed_i <= 1;
		m_siz_i <= 2'b11;
		m_stb_i <= 1;
		m_we_i  <= 0;
		s_ack_i <= 0;
		tick(8'h02);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_s_adr_o(64'h4444_3333_2222_111E);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_ack_i <= 1;
		s_dat_i <= 16'hDEAD;
		tick(8'h05);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_m_dat_o(64'd0);
		assert_s_adr_o(64'h4444_3333_2222_111C);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_dat_i <= 16'hBEEF;
		tick(8'h06);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_m_dat_o(64'd0);
		assert_s_adr_o(64'h4444_3333_2222_111A);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_dat_i <= 16'hFEED;
		tick(8'h07);
		assert_m_err_align_o(0);
		assert_m_ack_o(1);
		assert_s_adr_o(64'h4444_3333_2222_1118);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(0);

		s_dat_i <= 16'hFACE;
		#2;
		assert_m_dat_o(64'hDEAD_BEEF_FEED_FACE);

		tick(8'h08);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
	end
	endtask

	task test_dword_wr;
	begin
		scenario(8);
		m_cyc_i <= 0;	// Reset the state of the bridge

		wait(clk_i);
		story_i <= 16'h0801;
		s_ack_i <= 1;
		m_adr_i <= 64'h4444_3333_2222_1118;
		m_cyc_i <= 1;
		m_dat_i <= 64'h1111_2222_3333_4444;
		m_signed_i <= 1;
		m_siz_i <= 2'b11;
		m_stb_i <= 1;
		m_we_i  <= 1;
		wait(~clk_i);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_s_adr_o(64'h4444_3333_2222_111E);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(1);
		assert_s_dat_o(16'h1111);

		wait(clk_i);
		story_i <= 16'h0802;
		s_ack_i <= 1;
		m_adr_i <= 64'h4444_3333_2222_1118;
		m_cyc_i <= 1;
		m_dat_i <= 64'h1111_2222_3333_4444;
		m_signed_i <= 1;
		m_siz_i <= 2'b11;
		m_stb_i <= 1;
		m_we_i  <= 1;
		wait(~clk_i);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_s_adr_o(64'h4444_3333_2222_111C);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(1);
		assert_s_dat_o(16'h2222);

		wait(clk_i);
		story_i <= 16'h0803;
		s_ack_i <= 1;
		m_adr_i <= 64'h4444_3333_2222_1118;
		m_cyc_i <= 1;
		m_dat_i <= 64'h1111_2222_3333_4444;
		m_signed_i <= 1;
		m_siz_i <= 2'b11;
		m_stb_i <= 1;
		m_we_i  <= 1;
		wait(~clk_i);
		assert_m_err_align_o(0);
		assert_m_ack_o(0);
		assert_s_adr_o(64'h4444_3333_2222_111A);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(1);
		assert_s_dat_o(16'h3333);

		wait(clk_i);
		story_i <= 16'h0804;
		s_ack_i <= 1;
		m_adr_i <= 64'h4444_3333_2222_1118;
		m_cyc_i <= 1;
		m_dat_i <= 64'h1111_2222_3333_4444;
		m_signed_i <= 1;
		m_siz_i <= 2'b11;
		m_stb_i <= 1;
		m_we_i  <= 1;
		wait(~clk_i);
		assert_m_err_align_o(0);
		assert_m_ack_o(1);
		assert_s_adr_o(64'h4444_3333_2222_1118);
		assert_s_cyc_o(1);
		assert_s_signed_o(1);
		assert_s_siz_o(1);
		assert_s_stb_o(1);
		assert_s_we_o(1);
		assert_s_dat_o(16'h4444);

		wait(clk_i);
	end
	endtask

	initial begin
//		$dumpfile("wtf.vcd");
//		$dumpvars;

		clk_i <= 0;
		reset_i <= 0;
		story_i <= 0;

		tick(8'h00);

		test_byte_rd();
		test_byte_wr();
		test_hword_rd();
		test_hword_wr();
		test_word_rd();
		test_word_wr();
		test_dword_rd();
		test_dword_wr();

		$display("@I Done.");
		$stop;
	end
endmodule

