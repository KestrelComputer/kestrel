`timescale 1ns / 1ps

module bottleneck(
	input	[63:0]	m_adr_i,
	input		m_cyc_i,
	input	[63:0]	m_dat_i,
	input		m_signed_i,
	input	[1:0]	m_siz_i,
	input		m_stb_i,
	input		m_we_i,
	output		m_ack_o,
	output	[63:0]	m_dat_o,
	output		m_err_align_o,

	output	[63:0]	s_adr_o,
	output		s_cyc_o,
	output		s_signed_o,
	output		s_siz_o,
	output		s_stb_o,
	output		s_we_o,
	output	[15:0]	s_dat_o,
	input		s_ack_i,
	input	[15:0]	s_dat_i,

	input		clk_i,
	input		reset_i
);
	reg		ack1, ack2, ack3;
	wire		ack1_o, ack2_o, ack3_o;
	wire		SWeO_MWeI;
	wire		SStbO_MStbI;
	wire		SStbO_1;
	wire		SSizO_MSizI0;
	wire		SSizO_1;
	wire		SSignedO_MSignedI;
	wire		SDatO_MDatI63_48;
	wire		SDatO_MDatI47_32;
	wire		SDatO_MDatI31_16;
	wire		SDatO_MDatI15_0;
	wire		plus6;
	wire		plus4;
	wire		plus2;
	wire		SAdrO_MAdrI;
	wire		MErrAlignO_1;
	wire		MDatO_SDatI;
	wire		MAckO_SAckI;
	wire		MAckO_1;
	wire		Hold3_SDatI;
	wire		Hold2_SDatI;
	wire		Hold1_SDatI;

	wire reqByte = m_siz_i == 2'b00;
	wire reqHWord = m_siz_i == 2'b01;
	wire reqWord = m_siz_i == 2'b10;
	wire reqDWord = m_siz_i == 2'b11;

	assign s_cyc_o = m_cyc_i & ~MErrAlignO_1;
	assign s_we_o = (SWeO_MWeI ? m_we_i : 0);
	assign s_stb_o = (SStbO_MStbI ? m_stb_i : 0) | (SStbO_1 ? 1 : 0);
	assign s_siz_o = (SSizO_MSizI0 ? m_siz_i[0] : 0) | (SSizO_1 ? 1 : 0);
	assign s_signed_o = (SSignedO_MSignedI ? m_signed_i : 0);
	assign s_dat_o =
		((SDatO_MDatI63_48 ? m_dat_i[63:48] : 0) |
		(SDatO_MDatI47_32 ? m_dat_i[47:32] : 0) |
		(SDatO_MDatI31_16 ? m_dat_i[31:16] : 0) |
		(SDatO_MDatI15_0  ? m_dat_i[15:0]  : 0)) & (s_siz_o ? 16'hFFFF : 16'h00FF);
	assign s_adr_o = (SAdrO_MAdrI ?
				m_adr_i | ((plus2 ? 2 : 0) | (plus4 ? 4 : 0) | (plus6 ? 6 : 0))
				: 0);
	assign m_err_align_o = MErrAlignO_1;

	reg	[15:0]	hold1, hold2, hold3;

	wire [63:0] s_dat_8s = {{56{s_dat_i[7]}}, s_dat_i[7:0]};
	wire [63:0] s_dat_8u = {56'd0, s_dat_i[7:0]};
	wire [63:0] s_dat_16s = {{48{s_dat_i[15]}}, s_dat_i};
	wire [63:0] s_dat_16u = {48'd0, s_dat_i};
	wire [63:0] s_dat_32s = {{32{hold1[15]}}, hold1, s_dat_i};
	wire [63:0] s_dat_32u = {32'd0, hold1, s_dat_i};
	wire [63:0] s_dat_64 = {hold3, hold2, hold1, s_dat_i};

	assign m_dat_o =
		((MDatO_SDatI & m_signed_i & reqByte) ? s_dat_8s : 0) |
		((MDatO_SDatI & ~m_signed_i & reqByte) ? s_dat_8u : 0) |
		((MDatO_SDatI & m_signed_i & reqHWord) ? s_dat_16s : 0) |
		((MDatO_SDatI & ~m_signed_i & reqHWord) ? s_dat_16u : 0) |
		((MDatO_SDatI & m_signed_i & reqWord) ? s_dat_32s : 0) |
		((MDatO_SDatI & ~m_signed_i & reqWord) ? s_dat_32u : 0) |
		((MDatO_SDatI & reqDWord) ? s_dat_64 : 0);

	assign m_ack_o = (MAckO_SAckI ? s_ack_i : 0) | (MAckO_1 ? 1 : 0);

	BottleneckSequencer bs(
		.SAckI(s_ack_i),
		.ack3(ack3),
		.ack2(ack2),
		.ack1(ack1),
		.MAdrI2(m_adr_i[2]),
		.MAdrI1(m_adr_i[1]),
		.MAdrI0(m_adr_i[0]),
		.MSiz0(m_siz_i[0]),
		.MSiz1(m_siz_i[1]),
		.MStbI(m_stb_i),
		.MCycI(m_cyc_i),
		.ResetI(reset_i),
		.SWeO_MWeI(SWeO_MWeI),
		.SStbO_MStbI(SStbO_MStbI),
		.SStbO_1(SStbO_1),
		.SSizO_MSizI0(SSizO_MSizI0),
		.SSizO_1(SSizO_1),
		.SSignedO_MSignedI(SSignedO_MSignedI),
		.SDatO_MDatI63_48(SDatO_MDatI63_48),
		.SDatO_MDatI47_32(SDatO_MDatI47_32),
		.SDatO_MDatI31_16(SDatO_MDatI31_16),
		.SDatO_MDatI(SDatO_MDatI15_0),
		.plus6(plus6),
		.plus4(plus4),
		.plus2(plus2),
		.SAdrO_MAdrI(SAdrO_MAdrI),
		.MErrAlignO_1(MErrAlignO_1),
		.MDatO_SDatI(MDatO_SDatI),
		.MAckO_SAckI(MAckO_SAckI),
		.MAckO_1(MAckO_1),
		.Hold3_SDatI(Hold3_SDatI),
		.Hold2_SDatI(Hold2_SDatI),
		.Hold1_SDatI(Hold1_SDatI),
		.ack3_o(ack3_o),
		.ack2_o(ack2_o),
		.ack1_o(ack1_o)
	);

	always @(posedge clk_i) begin
		ack1 <= ack1_o;
		ack2 <= ack2_o;
		ack3 <= ack3_o;

		if(Hold1_SDatI) hold1 <= s_dat_i;
		if(Hold2_SDatI) hold2 <= s_dat_i;
		if(Hold3_SDatI) hold3 <= s_dat_i;
	end
endmodule

