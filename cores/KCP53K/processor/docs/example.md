# Example Application

This chapter includes a functioning Verilog example
of a working (simulated!) computer using the KCP53000 processor core.
The purpose of this example is not to illustrate
a complete design;
rather, it aims to show one method you can use to integrate the KCP53000 into your own designs.

By the end of this chapter,
you will have a computer:

* with a bank of ROM 256 bytes in size, arranged as 64 words by 32 bits,
* with a memory bridge that supports byte, half-word, word, and double-word transfers, and,
* with a custom I/O register implemented as a custom CSR.

This computer is aware that it's running inside a Verilog simulation,
and thus provides a means to terminate the simulation via its custom I/O register.

## Requirements

The computer needs to provide the following output facilities.
We arbitrarily decide on CSR address 255 ($0FF) for the output register.

### OUTPUT CSR ($0FF)

|63:nn|11   |10:3|2   |1   |0   |
|:---:|:-:  |:--:|:-: |:-: |:-: |
|  0  |START|CHAR|STOP|EXIT|FAIL|

#### Displaying Text

Software can write characters to the Verilog console
by sending 8-bit characters in `CHAR`.
To do this, `START` *must* be 1, and `STOP` *must* be 0.
For example, to display the letter A to the console:

    addi t0, x0, $141           ; ASCII code for A, with start bit prefixed
    slli t0, t0, 3              ; Shift into position
    csrrw x0, t0, output        ; Send/display the character.
    
Our example computer is aware it's running in Verilog, and so
we don't bother implementing a proper UART.
However, for completeness, we will emulate an instantaneous baud rate,
so that *reads* from the `OUTPUT` CSR will report a fully transmitted byte:
`START` and `CHAR` will read as 0, while
`STOP` is 1.

#### Terminating the Simulation

When the program completes, we would like the simulation to finish with a success or failure indication.
This facilitates using this logic in automated testing environments, such as [Travis CI](https://travis-ci.org/).

Software can accomplish this by setting the `EXIT` bit in `OUTPUT`.
Note that this *terminates* the simulation completely;
*no* instructions thereafter will execute.

The `FAIL` bit makes sense only when exiting.
If set, it means that some test has failed, and Verilog will produce a failure message.
This message can be sought using "grep" and, if found, cause a CI/CD pipeline to fail.
If clear, no such output is generated, and thus a successful outcome is assumed.

    csrrwi x0, 3, output        ; Something went wrong; fail immediately.
    csrrwi x0, 2, output        ; Everything went swimmingly; success!

Note that writing the `OUTPUT` register this way sets `START` to 0;
thus, no spurious nul-character will be produced.

To minimize example complexity,
both `EXIT` and `FAIL` will read back as 0.

### Architecture

The following diagram illustrates how the computer is constructed.
This particular computer is free of RAM,
since registers provide sufficient storage for our needs.
The CPU's I and D ports are connected to a common Furcula bus (the X-bus) via an *arbiter*.
The arbiter's job is to prioritize which port has control over the X-bus
in the event that both want to transfer data at the same time.
The Wishbone bridge adapts Furcula to a Wishbone B3-compatible bus,
allowing compatibility with devices on that bus.

![Example Computer Diagram](example/block-diagram.svg)

Note that this example is, in part, more complicated than it needs to be.
There is no need for a Wishbone bus bridge, as we don't use Wishbone's features in this example.
Similarly, the arbiter isn't *strictly* necessary,
since the KCP53000 will never concurrently generate an access on the I and D ports.
However, we include it here in anticipation of a future generation of the processor architecture which can.

## Sample Software

We need a demonstration program to run on this computer, to illustrate that it works.
We'll use the traditional "Hello world" program.
It's requirements are trivial:
print a greeting, then terminate simulation with a successful result.

    ; The following program was built and converted into Verilog hex-dump
    ; format with the following commands.  Your assembler may use slightly
    ; different syntax or command-line options.
    ;
    ; Note that the call to xxd and awk must sit on one line or it won't work.
    ;
    ; a from example.asm to example.bin
    ; xxd -g 8 -c 8 example.bin |                                    \
    ;   awk -e '{print substr($2,15,2)substr($2,13,2)substr($2,11,2) \
    ;   substr($2,9,2)substr($2,7,2)substr($2,5,2)substr($2,3,2)     \
    ;   substr($2,1,2);}' >example.hex
    ;

                    adv     $F00, $CC
                    jal     1, main         ; Call our main program, setting
                                            ; X1 to point at our string.

                    byte    "Hello world!",13,10,0
                    align   4

    main:           jal     2, writeStr     ; Write the string the console.
                    csrrwi  0, 2, $0FF      ; End the simulation successfully.

    writeStr:       lb      3, 0(1)         ; Get next byte to transmit
                    beq     3, 0, done      ; If we're done, return.
                    ori     3, 3, $100      ; Set start bit.
                    slli    3, 3, 3         ; Send it via OUTPUT.
                    csrrw   0, 3, $0FF
                    addi    1, 1, 1         ; Advance to the next byte.
                    jal     0, writeStr     ; Repeat as often as necessary.
    done:           jalr    0, 0(2)

                    adv     $1000, 0

To assemble the software and convert it to a hex-dump file suitable for use in Verilog,
we use the `a` assembler (part of the Kestrel-3 software development toolchain),
`xxd` command to produce a listing of 64-bit words, and `awk` to extract those words and
perform the little-endian byte-swap we need for Verilog to load memory correctly:

    a from example.asm to example.bin

    xxd -g 8 -c 8 example.bin |                                    \
      awk -e '{print substr($2,15,2)substr($2,13,2)substr($2,11,2) \
      substr($2,9,2)substr($2,7,2)substr($2,5,2)substr($2,3,2)     \
      substr($2,1,2);}' >example.hex

Make sure the `xxd` command exists on one line.  It's probably best to put the above
code into a shell script file.

The result is a file, `example.hex`, which contains a hex dump of the 4KB ROM image.

**NOTE.** Some versions of `xxd` support a `-e` option to perform endian conversion.
If yours supports this flag, you can replace that `substr`-mishmash above with a
simple reference `$2`, like so:

    a from example.asm to example.bin

    xxd -e -g 8 -c 8 example.bin | awk -e '{print $2;}' >example.hex

### Modeling the ROM

Once we have our example program, we need to place it in memory.
So, we create a Verilog file named "rom.v" to hold our ROM model.
Note that we don't care about address bits 2:0,
since those correspond to individual byte lanes on the 64-bit
output.  The Wishbone bus bridge, illustrated below,
will provide lane selection logic for the CPU.

    `timescale 1ns / 1ps

    module rom(
            input   [11:3]  A,      // Address
            output  [63:0]  Q,      // Data output
            input   STB             // True if ROM is being accessed.
    );
            reg [63:0] contents[0:511];
            wire [63:0] results = contents[A];
            assign Q = STB ? results : 0;

            initial begin
                    $readmemh("example.hex", contents);
            end
    endmodule


### Modeling the OUTPUT CSR

The following model implements the desired Verilog-related behavior while the program is running.

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
            wire charByte_mux = write ? cdat_i[10:3] : 8'b0000_0000;
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
            always @(posedge clk_i) begin
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

### Address Decode Logic

All computers need some flavor of address decoding.

    `timescale 1ns / 1ps

    module address_decode(
        // Processor-side control
        input   iadr_i,
        input   istb_i,
        output  iack_o,

        // ROM-side control
        output  STB_o
    );

        // For our example, we're just going to decode address bit A12.
        // If it's high, then we assume we're accessing ROM.
        // The ROM is asynchronous, so we just tie iack_o directly to the
        // the strobe pin.
        assign STB_o = iadr_i & istb_i;
        assign iack_o = STB_o;

        // We don't have any RAM resources to access, but if we did,
        // we would decode them here as well.
    endmodule

### The Arbiter and Bus Bridge

The KCP53000 is equipped to work with Harvard-architecture machines out of the box.
However, with a Furcula bus arbiter, you can merge the I- and D-ports of the processor into a single Furcula bus.

    `timescale 1ns / 1ps

    module arbiter(
            // I-Port
            input       [63:0]  idat_i,
            input       [63:0]  iadr_i,
            input               iwe_i,
            input               icyc_i,
            input               istb_i,
            input       [1:0]   isiz_i,
            input               isigned_i,
            output              iack_o,
            output      [63:0]  idat_o,

            // D-Port
            input       [63:0]  ddat_i,
            input       [63:0]  dadr_i,
            input               dwe_i,
            input               dcyc_i,
            input               dstb_i,
            input       [1:0]   dsiz_i,
            input               dsigned_i,
            output              dack_o,
            output      [63:0]  ddat_o,

            // X-Port
            output      [63:0]  xdat_o,
            output      [63:0]  xadr_o,
            output              xwe_o,
            output              xcyc_o,
            output              xstb_o,
            output      [1:0]   xsiz_o,
            output              xsigned_o,
            input               xack_i,
            input       [63:0]  xdat_i,

            // Miscellaneous
            input               clk_i,
            input               reset_i
    );
            reg reserve_i, reserve_d;

            wire en_i = (~reset_i & icyc_i & ~dcyc_i) |
                        (~reset_i & icyc_i & dcyc_i & reserve_i & ~reserve_d);

            wire en_d = (~reset_i & ~icyc_i & dcyc_i) |
                        (~reset_i & icyc_i & dcyc_i & ~reserve_i) |
                        (~reset_i & icyc_i & dcyc_i & reserve_i & reserve_d);

            assign xdat_o = (en_i ? idat_i : 64'd0) | (en_d ? ddat_i : 64'd0);
            assign xadr_o = (en_i ? iadr_i : 64'd0) | (en_d ? dadr_i : 64'd0);
            assign xwe_o = (en_i & iwe_i) | (en_d & dwe_i);
            assign xcyc_o = (en_i & icyc_i) | (en_d & dcyc_i);
            assign xstb_o = (en_i & istb_i) | (en_d & dstb_i);
            assign xsiz_o = (en_i ? isiz_i : 2'd0) | (en_d ? dsiz_i : 2'd0);
            assign xsigned_o = (en_i & isigned_i) | (en_d & dsigned_i);

            assign iack_o = (en_i & xack_i);
            assign dack_o = (en_d & xack_i);

            assign idat_o = (en_i ? xdat_i : 64'd0);
            assign ddat_o = (en_d ? xdat_i : 64'd0);

            always @(posedge clk_i) begin
                    reserve_i <= en_i;
                    reserve_d <= en_d;
            end
    endmodule

Once we have only a single bus to work with,
we can use the Furcula-to-Wishbone bus bridge
to couple a ROM or peripheral designed for that bus to the processor.

**NOTE.**  Since Furcula is so closely related with the Wishbone bus,
not a lot of logic is required to adapt the former to the latter,
this module does not need to implement the full interfaces for either
Furcula or Wishbone.

    `timescale 1ns / 1ps

    module bridge(
            // FURCULA BUS
            input               f_signed_i,
            input       [1:0]   f_siz_i,
            input       [2:0]   f_adr_i,
            input       [63:0]  f_dat_i,
            output      [63:0]  f_dat_o,

            // WISHBONE BUS
            output      [7:0]   wb_sel_o,
            output      [63:0]  wb_dat_o,
            input       [63:0]  wb_dat_i
    );
            // Wishbone SEL_O signal generation.

            wire size_byte = (f_siz_i == 2'b00);
            wire size_hword = (f_siz_i == 2'b01);
            wire size_word = (f_siz_i == 2'b10);
            wire size_dword = (f_siz_i == 2'b11);

            wire ab7 = f_adr_i[2:0] == 3'b111;
            wire ab6 = f_adr_i[2:0] == 3'b110;
            wire ab5 = f_adr_i[2:0] == 3'b101;
            wire ab4 = f_adr_i[2:0] == 3'b100;
            wire ab3 = f_adr_i[2:0] == 3'b011;
            wire ab2 = f_adr_i[2:0] == 3'b010;
            wire ab1 = f_adr_i[2:0] == 3'b001;
            wire ab0 = f_adr_i[2:0] == 3'b000;

            wire ah3 = f_adr_i[2:1] == 2'b11;
            wire ah2 = f_adr_i[2:1] == 2'b10;
            wire ah1 = f_adr_i[2:1] == 2'b01;
            wire ah0 = f_adr_i[2:1] == 2'b00;

            wire aw1 = f_adr_i[2] == 1'b1;
            wire aw0 = f_adr_i[2] == 1'b0;

            wire den = size_dword;
            wire wen1 = size_word & aw1;
            wire wen0 = size_word & aw0;
            wire hen3 = size_hword & ah3;
            wire hen2 = size_hword & ah2;
            wire hen1 = size_hword & ah1;
            wire hen0 = size_hword & ah0;
            wire ben7 = size_byte & ab7;
            wire ben6 = size_byte & ab6;
            wire ben5 = size_byte & ab5;
            wire ben4 = size_byte & ab4;
            wire ben3 = size_byte & ab3;
            wire ben2 = size_byte & ab2;
            wire ben1 = size_byte & ab1;
            wire ben0 = size_byte & ab0;

            wire sel7 = den | wen1 | hen3 | ben7;
            wire sel6 = den | wen1 | hen3 | ben6;
            wire sel5 = den | wen1 | hen2 | ben5;
            wire sel4 = den | wen1 | hen2 | ben4;
            wire sel3 = den | wen0 | hen1 | ben3;
            wire sel2 = den | wen0 | hen1 | ben2;
            wire sel1 = den | wen0 | hen0 | ben1;
            wire sel0 = den | wen0 | hen0 | ben0;

            assign wb_sel_o = {sel7, sel6, sel5, sel4, sel3, sel2, sel1, sel0};

            // Furcula-to-Wishbone Data Routing

            wire [7:0] od7 =
                    (size_byte ? f_dat_i[7:0] : 0) |
                    (size_hword ? f_dat_i[15:8] : 0) |
                    (size_word ? f_dat_i[31:24] : 0) |
                    (size_dword ? f_dat_i[63:56] : 0);

            wire [7:0] od6 =
                    (size_byte ? f_dat_i[7:0] : 0) |
                    (size_hword ? f_dat_i[7:0] : 0) |
                    (size_word ? f_dat_i[23:16] : 0) |
                    (size_dword ? f_dat_i[55:48] : 0);

            wire [7:0] od5 =
                    (size_byte ? f_dat_i[7:0] : 0) |
                    (size_hword ? f_dat_i[15:8] : 0) |
                    (size_word ? f_dat_i[15:8] : 0) |
                    (size_dword ? f_dat_i[47:40] : 0);

            wire [7:0] od4 =
                    (size_byte ? f_dat_i[7:0] : 0) |
                    (size_hword ? f_dat_i[7:0] : 0) |
                    (size_word ? f_dat_i[7:0] : 0) |
                    (size_dword ? f_dat_i[39:32] : 0);

            wire [7:0] od3 =
                    (size_byte ? f_dat_i[7:0] : 0) |
                    (size_hword ? f_dat_i[15:8] : 0) |
                    (size_word ? f_dat_i[31:24] : 0) |
                    (size_dword ? f_dat_i[31:24] : 0);

            wire [7:0] od2 =
                    (size_byte ? f_dat_i[7:0] : 0) |
                    (size_hword ? f_dat_i[7:0] : 0) |
                    (size_word ? f_dat_i[23:16] : 0) |
                    (size_dword ? f_dat_i[23:16] : 0);

            wire [7:0] od1 =
                    (size_byte ? f_dat_i[7:0] : 0) |
                    (size_hword ? f_dat_i[15:8] : 0) |
                    (size_word ? f_dat_i[15:8] : 0) |
                    (size_dword ? f_dat_i[15:8] : 0);

            wire [7:0] od0 = f_dat_i[7:0];

            assign wb_dat_o = {od7, od6, od5, od4, od3, od2, od1, od0};

            // Wishbone to Furcula Data Routing

            wire [31:0] id2 =
                            (wen1 ? wb_dat_i[63:32] : 0) |
                            (wen0 ? wb_dat_i[31:0] : 0);
            wire [15:0] id1 =
                            (hen3 ? wb_dat_i[63:48] : 0) |
                            (hen2 ? wb_dat_i[47:32] : 0) |
                            (hen1 ? wb_dat_i[31:16] : 0) |
                            (hen0 ? wb_dat_i[15:0] : 0);
            wire [7:0] id0 =
                            (ben7 ? wb_dat_i[63:56] : 0) |
                            (ben6 ? wb_dat_i[55:48] : 0) |
                            (ben5 ? wb_dat_i[47:40] : 0) |
                            (ben4 ? wb_dat_i[39:32] : 0) |
                            (ben3 ? wb_dat_i[31:24] : 0) |
                            (ben2 ? wb_dat_i[23:16] : 0) |
                            (ben1 ? wb_dat_i[15:8] : 0) |
                            (ben0 ? wb_dat_i[7:0] : 0);
            wire [63:32] id2s = (f_signed_i ? {32{id2[31]}} : 32'd0);
            wire [63:16] id1s = (f_signed_i ? {48{id1[15]}} : 48'd0);
            wire [63:8] id0s = (f_signed_i ? {56{id0[7]}} : 56'd0);

            assign f_dat_o =
                    (size_dword ? wb_dat_i : 0) |
                    (size_word ? {id2s, id2} : 0) |
                    (size_hword ? {id1s, id1} : 0) |
                    (size_byte ? {id0s, id0} : 0);
    endmodule

### The Computer Top-Level

The computer module wraps everything together into a single circuit.

    `timescale 1ns / 1ps

    module computer();
            wire iack;
            wire [63:0] iadr;
            wire istb;
            wire [31:0] idatiL;
            wire [63:32] idatiH;    // unused; just to make iverilog happy.

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
                    .idat_i(64'd0), // CPU cannot write via I-port.
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



### Simulating the Computer

To simulate the computer,
I use Icarus Verilog to compile everything:

    iverilog computer.v address_decode.v output.v rom.v \
             ../../rtl/verilog/polaris.v ../../rtl/verilog/xrs.v \
             ../../rtl/verilog/seq.v ../../rtl/verilog/alu.v
    vvp -n a.out

You should see the computer print `Hello world!` to the console,
and then the simulation should quit back to shell prompt.

