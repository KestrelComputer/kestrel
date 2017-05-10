`timescale 1ns / 1ps

module output_csr(
        input   [11:0]  cadr_i,
        output          cvalid_o,
        output  [63:0]  cdat_o,
        input   [63:0]  cdat_i,
        input           coe_i,
        input           cwe_i,

        input           clk_i
);
        // Decode our CSR address, and report back to the CPU
        // whether or not we're selected.  This *MUST* happen
        // during the *first* clock cycle of any CSR-instruction.
        // For this reason, we make sure to do this asynchronously.
        wire csrv_output = (cadr_i == 12'h0FF);
        assign cvalid_o = csrv_output;

        // When reading, all bits are 0 except for STOP bit.
        // Note that we must do this regardless of the state of
        // the coe_i input.  coe_i *only* controls whether or not
        // read-triggered side-effects happen.
        wire [63:0] csrd_output = {64'h0000_0000_0000_0004};
        assign cdat_o = (csrv_output ? csrd_output : 0);

        // Discover whether or not write-effects are to happen.
        wire write = csrv_output & cwe_i;

        // Assuming they are, let's discover the inputs to the
        // register so we can act upon them.
        //
        // Historically, these signals are suffixed with _mux
        // because they are intended to be multiplexors into
        // stateful registers.  Since we don't have state,
        // it's a bit redundant in this example.
        wire startBit_mux = write ? cdat_i[11] : 1'b0;
        wire [7:0] charByte_mux = write ? cdat_i[10:3] : 8'b0000_0000;
        wire stopBit_mux = write ? cdat_i[2] : 1'b0;
        wire exitBit_mux = write ? cdat_i[1] : 1'b0;
        wire failBit_mux = write ? cdat_i[0] : 1'b0;

        // IF you had state, you'd maintain it like so:
        //
        // always @(posedge clk_i) begin
        //      startBit <= startBit_mux;
        //      charByte <= charByte_mux;
        //      stopBit <= stopBit_mux;
        //      exitBit <= exitBit_mux;
        //      failBit <= failBit_mux;
        // end

        // Recognize, and act upon, the desired write effects
        // when they happen.
        always @(negedge clk_i) begin
                if((startBit_mux === 1) && (stopBit_mux === 0)) begin
                        $display("%c", charByte_mux);
                end

                if(exitBit_mux === 1) begin
                        if(failBit_mux === 1) begin
                                $display("@ FAIL");
                        end
                        $stop;
                end
        end
endmodule

