# Introduction

The KCP53000 core is
a 64-bit RISC-V instruction set compatible
processor.
It also is the first member
of the KCP53000 family of core designs.

It is designed for easy integration
into most projects which require
a powerful processor,
but which cannot justify the complexity
often found with such processors, such as
caches,
complex interconnects or buses,
deep interconnect or bus hierarchies requiring stacked bridges,
and last but not least,
large numbers of confusing processor-specific configuration registers.
The KCP53000 is ideal for projects
where you often long for the interconnect simplicity
of an 8-bit microprocessor,
but you want the expressive simplicity
that wider data paths can afford.

Although this processor does not expose a Wishbone-compatible bus,
the core is designed to interface with minimal effort to Wishbone interconnects.

## Features

* Flat 16 EiB instruction and data address spaces.
* Separate I-bus and D-bus ports supports Harvard architecture designs; or, with a suitable bus bridge, a Von Neumann architecture.
* Separate C-bus supports application-specific CSRs.
* 8, 16, 32, and 64-bit signed and unsigned memory accessors.
* 64-bit internal architecture.
* 31 general purpose registers (X1-X31).  X0 is hardwired to zero.
* 18 Core-Specific Registers (CSRs).
* Most instructions complete within 4 clock cycles.
* Machine-mode only design for minimum learning curve.
* External interrupt support.
* 25MHz clock supports between 4 and 6 MIPS throughput, depending on instruction mix.
* RV64IS compatible.
* Conforms to RISC-V User-Level ISA Specification v2.1.
* Conforms to RISC-V Draft Privilege ISA Specification v1.9.

## Applications

* Deep-embedded microprocessor for application-specific control functions.
* Applications involving large data transfers.
* "Neo-retro" home computer or game consoles.
* More capable replacement for Z-80, 6502, 6809, 68000/68010, or similar platforms.
