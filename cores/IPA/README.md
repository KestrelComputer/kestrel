# IPA

When working with constrained environments,
you might not have enough resources to implement a self-contained System-on-Chip (SoC).
For instance,
a recent Kestrel Computer design synthesizes a 64-bit RISC-V ISA CPU onto an iCE40HX8K FPGA,
which does not leave sufficient look-up tables available to emulate even a small bootstrap ROM.
The **Initial Program Adapter** (IPA) provides a read-only ROM interface from the CPU's point of view,
while providing a serial receiver on the other side.
This allows another host to spoonfeed CPU instructions,
allowing the host to download arbitrary software into the SoC's RAM, and execute code from RAM instead.

A typical instruction stream sent to a host CPU might look like the following:

    addi    x1, x0, 0       ; start at address 0 in RAM
    addi    x2, x0, nn      ; Store byte 0 of bootstrap image
    sb      x2, 0(x1)
    addi    x2, x0, nn      ; Store byte 1 of bootstrap image
    sb      x2, 1(x1)
    ...
    addi    x2, x0, nn      ; Store byte 1023 of bootstrap image
    sb      x2, 1023(x1)
    addi    x1, x1, 1024    ; Move to next block of code
    addi    x2, x0, nn      ; Store byte 1024 of bootstrap image
    sb      x2, 0(x1)
    addi    x2, x0, nn      ; Store byte 1025 of bootstrap image
    sb      x2, 1(x1)
    ...
    addi    x2, x0, nn      ; Store byte 2047 of bootstrap image
    sb      x2, 1023(x1)
    jal     x0, 0(x0)       ; Showtime -- commence cold boot!

When the host CPU attempts to read a word from the IPA's address space,
it will block indefinitely, waiting for the IPA to acknowledge with data.
The IPA implementation works by withholding the Wishbone B.4's `ACK_O` signal
until a 16-bit word has been received over the serial interface.
Since opcodes on a RISC-V processor are typically 32-bits wide,
two such transactions may be required to execute a single CPU instruction.

This IPA core works with 16-bit words only;
it is **not** general purpose.
It exists solely to spoonfeed 32-bit instructions to a host RISC-V CPU over a 16-bit bus.

