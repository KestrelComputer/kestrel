# Instruction Set

The complete RISC-V instruction set
is available at the [RISC-V Foundation](https://www.riscv.org) website:

* [User-Level ISA Specification v2.1](https://www.riscv.org/specifications/)
* [Draft Privileged ISA Specification v1.9](https://www.riscv.org/specifications/privileged-isa/)

The following information provides a summary
of the instructions supported by the KCP53000,
providing specific implementation details where necessary.

## Notation

### Braces ({ and })

Braces are used to denote the bitwise concatenation.
This is used to construct a larger number from smaller sub-fields.
You'll often see this used in conjunction with displacements,
for example,
since RISC-V displacements are not contiguously stored in the instruction word.

For example, `{1, 0, 1, 1}` evaluates to the binary `1011` (decimal 11) number.

### Registers

General purpose registers are denoted **Xn**, where n is some expression.
For example, `X30`, or `Xrd`, where *rd* is a field provided in an instruction.

**PC** refers to the *program counter*, and points to the next instruction to be fetched.
It *does not* refer to the currently executing instruction.
The **IA** register points to the currently executing instruction (*instruction address*).

### `sx`, `zx`

These two functions sign- and zero-extend their operands to the full register width, respectively.
As used in this section,
these functions are polymorphic:
they work with inputs of any bit-width.
This hides the implementation detail of how the underlying hardware actually works.

## AUIPC

|31:12|11:7|6:0|
|:---:|:--:|:-:|
|*disp[31:12]*|*rd*|0010111|

    displacement = sx({disp[31:12], 0000_0000_0000});
    if(rd != 0)
        Xrd = IA + displacement;

Assigns the sum of the instruction address and the provided displacement to the specified register.
The displacement is first sign-extended to the full register width.
Bits 11:0 of the displacement are assumed 0.

## BRANCH

|31 |30:25|24:20|19:15|14:12|11:8|7|6:0|
|:-:|:---:|:---:|:---:|:---:|:-:|:--:|:-:|
|*disp[12]*|*disp[10:5]*|*rs2*|*rs1*|*fn3*|*disp[4:1]*|*disp[11]*|1100011|

    displacement = sx({disp[12], disp[11], disp[10:5], disp[4:1], 0});
    if(truth(rs1, rs2, fn3))
        PC = IA + displacement
    else
        PC = IA + 4

This instruction compares `Xrs1` against `Xrs2`, according to the following table:

|fn3|`truth` function|Mnemonic|
|:-:|:-:|:-:|
|000|rs1 == rs2|BEQ|
|001|rs1 != rs2|BNE|
|010|*undefined behavior*||
|011|*undefined behavior*||
|100|rs1 < rs2|BLT|
|101|rs1 >= rs2|BGE|
|110|rs1 < rs2 (unsigned)|BLTU|
|111|rs1 >= rs2 (unsigned)|BGEU|

If the specified condition is found to be true,
the next instruction to be fetched is determined by the sum of the displacement and the branch instruction's address.
Otherwise, execution resumes with the following instruction.

## JAL

| 31 |30:21| 20 |19:12|11:7|6:0|
|:--:|:---:|:--:|:---:|:--:|:-:|
|*disp[20]*|*disp[10:1]*|*disp[11]*|*disp[19:12]*|*rd*|1101111|

    displacement = sx({disp[20], disp[19:12], disp[11], disp[10:1], 0});
    if(rd != 0)
        Xrd = IA + 4;
    PC = IA + displacement;

The JAL instruction is used to *jump and link*.

The destination register receives a *return address*.
This address points to the next instruction immediately after the JAL instruction,
allowing a subroutine to return to the calling procedure without any undue difficulty.

The program counter is pointed at an instruction
located relative to the JAL instruction itself.

Be careful; executing JAL with a zero displacement will result in an infinite loop.
If interrupts are disabled, this will make the processor unresponsive until the next reset.

## JALR

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|*imm[11:0]*|*rs1*|*fn3*|*rd*|1100111|

    displacement = sx(imm[11:0]);
    if(rd != 0)
        Xrd = IA + 4;
    PC = Xrs1 + displacement;

The JALR instruction is used to *jump and link* using a register instead of a hard-coded displacement.
It's assumed the register `Xrs1` already points somewhere into executable code.

The destination register receives a *return address*.
This address points to the next instruction immediately after the JAL instruction,
allowing a subroutine to return to the calling procedure without any undue difficulty.

The program counter is pointed at an instruction
located relative to the address in `Xrs1`.

## LOAD

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|*imm[11:0]*|*rs1*|*fn3*|*rd*|0000011|

    displacement = sx(imm[11:0]);
    address = Xrs1 + displacement;
    if(rd != 0) {
        if(fn3[2] == 0)
            Xrd = sx(MEMORY[address]);
        else
            Xrd = zx(MEMORY[address]);
    }

This instruction is used to load bytes, half-words, words, or double-words into the specified register.
Since bytes, half-words, and words are narrower than the CPU's native register width,
forms exist to control zero- or sign-extension, per the following table:

|fn3|size|signed?|mnemonic|
|:-:|:-:|:-:|:-:|
|000|Byte|Yes|LB|
|001|Half-word|Yes|LH|
|010|Word|Yes|LW|
|011|Double-word|Yes|LD|
|100|Byte|No|LBU|
|101|Half-word|No|LHU|
|110|Word|No|LWU|
|111|Double-word|No|LDU|

Note that LD and LDU both fetch words that match the CPU's native register width.
They are semantically equivalent on this CPU.
However, if a future CPU widens the registers, this behavior will change.
**DO NOT** depend on the similar behaviors of LD and LDU.
Your software **will** break on an RV128-compatible processor if you do.

Note that this CPU does *not* support misaligned memory transfers on its own without external hardware support.
When equipped with a simple memory bridge,
attempting to load a half-word from an odd address, or a word from an address not divisible by 4,
or a double-word from an address not divisible by 8
*may* result in a load address alignment exception.
Bridges which do not detect misalignments may take one of two other behaviors;
either they'll simply *ignore* the least significant bits of the effective address,
or they'll properly support misaligned accesses at the expense of a slight runtime performance degradation.
If the former case,
then the effective address is essentially bitwise-ANDed with -2, -4, or -8 prior to transferring data.

## LUI

|31:12|11:7|6:0|
|:---:|:--:|:-:|
|*imm[31:12]*|*rd*|0110111|

    value = sx({imm[31:12], 0000_0000_0000});
    Xrd = value;

This instruction is used to set the upper 20 bits of a 32-bit wide register.
On a 64-bit machine like the KCP53000,
this instruction further sign-extends the result to the full register width.
Bits 11:0 of the destination register are forced to zero.

## MISC

### FENCE

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|0000_pppp_ssss|00000|000|00000|0001111|

No operation.  The `pppp` and `ssss` fields are ignored, and may take on any value.

**NOTE** that this instruction has well-defined meaning on processors that support looser memory models than the KCP53000.
**DO NOT** use this instruction as a surrogate NOP instruction.
Refer to the User-Level ISA Specification V2.1 for a better description of the intent of this instruction.

### FENCE.I

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|0000_0000_0000|00000|001|00000|0001111|

No operation.

**NOTE** that this instruction has well-defined meaning on processors that support looser memory models than the KCP53000.
**DO NOT** use this instruction as a surrogate NOP instruction.
Refer to the User-Level ISA Specification V2.1 for a better description of the intent of this instruction.

## OP

|31|30|29:25|24:20|19:15|14:12|11:7|6:0|
|:-:|:-:|:-:|:---:|:---:|:---:|:--:|:-:|
|0|*fn4[3]*|00000|*rs2*|*rs1*|*fn4[2:0]*|*rd*|011w011|

    if(rd != 0)
        Xrd = Operation(Xrs1, Xrs2, fn4);
    if(w)
        Xrd = sx(Xrd[31:0]);

This instruction performs an arithmetic or logical operation,
according to the setting of the `fn4` field in the instruction.
The table below illustrates the selection of operations you can perform.
The operands of the operation come from the specified registers.

|fn4 |Operation              |Mnemonic|Description                                                            |
|:--:|:---------------------:|:------:|:----------------------------------------------------------------------|
|0000|Xrs1 + Xrs2            |ADD     |Arithmetic sum.                                                        |
|0001|Xrs1 << Xrs2           |SLL     |Bitwise shift of bits to the left, shifting in 0 bits from the right.  |
|0010|Xrs1 < Xrs2 (signed)   |SLT     |Sets the destination register to 1 if Xrs1 < Xrs2; 0 otherwise.        |
|0011|Xrs1 < Xrs2 (unsigned) |SLTU    |Sets the destination register to 1 if Xrs1 < Xrs2; 0 otherwise.        |
|0100|Xrs1 ^ Xrs2            |XOR     |Performs the bitwise XOR function for each bit in the source registers.|
|0101|Xrs1 >> Xrs2 (unsigned)|SRL     |Bitwise shift of bits to the right, shifting in 0 bits from the left.  |
|0110|Xrs1 \/ Xrs2           |OR      |Performs the bitwise OR function for each bit in the source registers. |
|0111|Xrs1 /\ Xrs2           |AND     |Performs the bitwise AND function for each bit in the source registers.|
|1000|Xrs1 - Xrs2            |SUB     |Arithmetic difference.                                                 |
|1001|undefined              |        |                                                                       |
|1010|undefined              |        |                                                                       |
|1011|undefined              |        |                                                                       |
|1100|undefined              |        |                                                                       |
|1101|Xrs1 >> Xrs2 (signed)  |SRA     |Bitwise shift of bits to the right, retaining the current sign bit.    |
|1110|undefined              |        |                                                                       |
|1111|undefined              |        |                                                                       |

If the `w` bit is set in the opcode field,
the result is *always* sign-extended as if it were a 32-bit value loaded into a 64-bit register.
Thus, bits 63:32 will always equal bit 31 of the result.

## OP-IMM

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|*imm[11:0]*|*rs1*|*fn3*|*rd*|001w011|

    value = sx(imm[11:0]);
    fn4 = {imm[10], fn3};
    if(rd != 0)
        Xrd = Operation(Xrs1, value, fn4);
    if(w)
        Xrd = sx(Xrd[31:0]);

This instruction performs an arithmetic or logical operation,
according to the setting of the `fn4` field in the instruction.
The left-hand side of the operation comes from the specified register,
while the right-hand side is provided as a numeric constant.
The constant is always sign-extended.
The table below illustrates the selection of non-shift operations you can perform.

|fn3|Operation             |Mnemonic|Description                                                            |
|:-:|:--------------------:|:------:|:----------------------------------------------------------------------|
|000|Xrs1 + Xrs2           |ADDI    |Arithmetic sum.                                                        |
|010|Xrs1 < Xrs2 (signed)  |SLTI    |Sets the destination register to 1 if Xrs1 < Xrs2; 0 otherwise.        |
|011|Xrs1 < Xrs2 (unsigned)|SLTIU   |Sets the destination register to 1 if Xrs1 < Xrs2; 0 otherwise.        |
|100|Xrs1 ^ Xrs2           |XORI    |Performs the bitwise XOR function for each bit in the source registers.|
|110|Xrs1 \/ Xrs2          |ORI     |Performs the bitwise OR function for each bit in the source registers. |
|111|Xrs1 /\ Xrs2          |ANDI    |Performs the bitwise AND function for each bit in the source registers.|

Shift operations do not rely on the full 12-bit immediate constant.
Since it does not make sense to shift a register by 2048 bits,
RISC-V reserves only 6 bits for shift displacement (imm[5:0]).
This leaves the remainder of the immediate bits unused, and must be zero for future compatibility.
The exception is imm[10], which can be used to select between logical and arithmetic shifts.

|fn4 |Operation              |Mnemonic|Description                                                          |
|:--:|:---------------------:|:------:|:--------------------------------------------------------------------|
|0001|Xrs1 << Xrs2           |SLLI    |Bitwise shift of bits to the left, shifting in 0 bits from the right.|
|0101|Xrs1 >> Xrs2 (unsigned)|SRLI    |Bitwise shift of bits to the right, shifting in 0 bits from the left.|
|1101|Xrs1 >> Xrs2 (signed)  |SRAI    |Bitwise shift of bits to the right, retaining the current sign bit.  |

If the `w` bit is set in the opcode field,
the result is *always* sign-extended as if it were a 32-bit value loaded into a 64-bit register.
Thus, bits 63:32 will always equal bit 31 of the result.

## STORE

|31:25|24:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:---:|:--:|:-:|
|*disp[11:5]*|*rs2*|*rs1*|*fn3*|*disp[4:0]*|0100011|

    displacement = sx({disp[11:5], disp[4:0]});
    address = Xrs1 + displacement;
    MEMORY[address] = Xrs2;

This instruction is used to store bytes, half-words, words, or double-words into memory,
according to the following table:

|fn3|size|mnemonic|
|:-:|:-:|:-:|
|000|Byte|SB|
|001|Half-word|SH|
|010|Word|SW|
|011|Double-word|SD|
|100|undefined||
|101|undefined||
|110|undefined||
|111|undefined||

Note that this CPU does *not* support misaligned memory transfers on its own without external hardware support.
When equipped with a simple memory bridge,
attempting to store a half-word from an odd address,
or a word from an address not divisible by 4,
or a double-word from an address not divisible by 8
*may* result in a store/AMO address alignment exception.
Bridges which do not detect misalignments may take one of two other behaviors;
either they'll simply *ignore* the least significant bits of the effective address,
or they'll properly support misaligned accesses at the expense of a slight runtime performance degradation.
If the former case,
then the effective address is essentially bitwise-ANDed with -2, -4, or -8 prior to transferring data.

Observe that no distinction is made between signed and unsigned quantities,
as only the appropriate number of bits of memory are affected by the store.

## SYSTEM

### CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|*csr[11:0]*|*rs1*|*fn3*|*rd*|1110011|

    if(fn3[2] == 0)
        src = Xrs1
    else
        src = zx(rs1)
    old = CSR[csr[11:0]];
    if(rd != 0) {
        Xrd = old;
        trigger_read_actions;
    }
    switch(fn3[1:0]) {
        case 1: new = src;
        case 2: new = old | src;
        case 3: new = old & ~src;
    }
    if(rs1 != 0) {
        CSR[csr[11:0]] = new;
        trigger_write_actions;
    }

These instructions allow access to special registers unique to the model of processor your software is running on.
The CSR acronym variously can take on several expansions:
Chip Specific Register, Core Specific Register, or Configuration Specific Register,
depending on the documentation source.
The KCP53000 documentation prefers Core Specific Register,
since KCP53000 family devices need not take on a physical chip form.

CSRs are identified by a 12-bit number.
The RISC-V instruction set does not interpret this field;
all 12 bits are opaque as far as these instructions are concerned.
However, when defining new CSRs, conventions on how the bits are used do exist.
The following table briefly summarizes the established conventions:

|Bit(s)|Purpose|
|:----:|:------|
|11:10 |Register family.  Up to four families may exist, with family 3 conventionally reserved for read-only registers.  Family 0, 1, and 2 may conventionally offer read-write access to registers.|
|9:8   |Required minimum privilege level, with 3 being machine-mode, and 0 being user-mode.  Note that KCP53000 only implements machine-mode, and so has unabated access to all CSRs.|
|7:0   |Unique address.|

CSRs may sometimes also be used as a distinct I/O register space as well.
The KCP53000 supports this mode of use through its C port.
Note that, where possible, memory-mapped I/O (MMIO) is generally preferred.

Please refer to the
[Draft Privileged ISA Specification v1.9](https://www.riscv.org/specifications/privileged-isa/)
for more details.

**NOTE** Access to CSRs which are not supported causes an illegal instruction trap.
This gives machine-mode software an opportunity to emulate the presence of the addressed CSR if required.

Bit 2 of the `fn3` field determines whether or not the source operand is the contents of a register (0),
or a 5-bit, *zero*-extended immediate value (1).

Bits 1:0 of the `fn3` field determines the kind of manipulation to perform on the CSR:

|fn3[1:0]|Purpose|Mnemonics|
|:-:|:------|:-------:|
|00|Unused|This combination encodes other instructions, such as ECALL.|
|01|Overwrite|CSRRW, CSRRWI|
|10|Bit Set|CSRRS, CSRRSI|
|11|Bit Clear|CSRRC, CSRRCI|

Since CSRs may be tied to I/O devices,
reading and writing may cause transport-triggered effects.
To avoid effects caused by *reading* a register,
you should specify `X0` as your destination register.
Since `X0` will always contain the value 0,
this register is a hint to the instruction that you don't care about the CSR's current value.
To avoid effects caused by *writing* a register,
you should specify `X0` as your source register Xrs1, or specify 0 as your immediate constant.

**NOTE:** This does not mean that the *value* of zero is interpreted to mean no-read or no-write.
To use a *value* of 0 in an operation (say, you want to write 0 into `mscratch`),
you would need to load it into a register first, like so:

    addi  t0, x0, 0          ; Load T0 with the value of 0.
    csrrw x0, t0, mscratch   ; Writes 0 into mscratch.

Attempting to do this the obvious way:

    csrrw x0, x0, mscratch   ; whoops!

will not work, because `X0`, being the source register specified, will prevent mscratch from being written to.

### EBREAK

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|0000_0000_0001|00000|000|00000|1110011|

    mstatus.mpie = mstatus.mie
    mstatus.mie = 0
    mepc = IA
    mcause.cause = 3
    mcause.irq = 0
    PC = mtvec

This instruction forces a breakpoint trap.
The semantics of what this means is dependent on the system firmware installed on your computer.

### ECALL

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|0000_0000_0000|00000|000|00000|1110011|

    mstatus.mpie = mstatus.mie
    mstatus.mie = 0
    mepc = IA
    mcause.cause = 2
    mcause.irq = 0
    PC = mtvec

This instruction invokes a system call.
The semantics of what this means is dependent on the system firmware installed on your computer.

### MRET

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|0011_0000_0010|00000|000|00000|1110011|

    mstatus.mie = mstatus.mpie
    mstatus.mpie = 1
    PC = mepc

This instruction returns from a system call, breakpoint, illegal instruction, or other form of trap.
This can also be used to return from hardware interrupts as well.

### WFI

|31:20|19:15|14:12|11:7|6:0|
|:---:|:---:|:---:|:--:|:-:|
|0001_0000_0101|00000|000|00000|1110011|

    while(mip == 0)
        /* do nothing. */ ;

The purpose of this instruction is to *wait* for an interrupt to occur.
If interrupts are enabled,
the CPU will process the interrupt trap as you'd expect when not executing this instruction.
Execution resumes with the next instruction after an interrupt occurs and after any traps have been processed.

**NOTE:** Disabling interrupts via `mstatus.mie` bit and/or by clearing all bits in `mie`
is not sufficient to deadlock the processor.
This instruction waits for `mip` to become non-zero.
However, if you have *external* interrupt enables which are turned off,
the processor will never know of these interrupt sources.
Thus, when using this instruction, make sure *at least* external interrupt enables are properly configured.
Otherwise, you run the risk of deadlocking the processor.

This instruction currently does nothing on the KCP53000 core (e.g., it treats `mip` as though it were non-zero all the time).
However, do not mistake this for a no-operation instruction.
Future processor revisions will implement intended behavior.

