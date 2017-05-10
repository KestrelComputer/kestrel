# Programming Model

![Programming model](prg-model.svg)

## General Purpose Registers

X0 is hardwired to the value of zero,
allowing a simplification of the processor instruction set.
X1 through X31 may be used for any purpose,
either holding data
or referring to other data as a pointer.

The processor does not support a hardware-managed stack.
Typically,
one of the general purpose registers
is reserved for this purpose and the stack itself emulated in software.
It is beyond the scope of this text to indicate the preferred register for this task;
consult an appropriate Application Binary Interface specification for more details.

## Core Specific Registers

Eighteen CSRs contain status or configuration information for the processor.
Most of the contents of the CSRs are read-only,
as the KCP53000 does not offer the complete runtime environment of a multi-mode RISC-V processor.

Notice that the KCP53000 only offers machine mode;
thus, only M-mode CSRs are supported.

Each CSR is described in terms of the bits it offers.
A reset-time default value for the bits is provided in the description.
For read/write bits or fields, values *may* differ from those documented.
These fields *will* reset to the documented values when `reset_i` is asserted, however.

### misa ($F10)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:62|R/O|2|This field indicates the base instruction set supported by the processor.  The values are 0, 1, 2, or 3 for unknown, RV32, RV64, or RV128, respectively.|
|60:26|R/O|0|Reserved for future use.|
|25:0|R/O|S=1; I=1; all others 0|This field is a 26-bit long bitset indicating which instruction set extensions this processor supports.  **A** corresponds to bit 0, while **Z** corresponds to bit 25.|

This register indicates the base instruction set supported by the processor,
along with a list of supported extensions.

### mvendorid ($F11)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/O|0|Vendor ID.|

This register identifies the manufacturer of the processor.  Since the KCP53000 has no particular manufacturer (it's an open-source core specified in Verilog), this register is zero.

### marchid ($F12)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/O|0|Base microarchitecture ID|

This register identifies the microarchitecture of the processor.  The value in this register is scoped by the value in `mvendorid`, such that both registers should be sufficient to identify the precise processor implementation.  Since the KCP53000 has no vendor, this register is superfluous, and so is hardwired zero.

### mimpid ($F13)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:48|R/O|$2016|Major version, represented in BCD.  This value is the year that the design was synthesized, tested, and released to the public repository.|
|47:40|R/O|$10|Minor version.  This value is the month that the design was synthesized, tested, and released to the public repository.|
|39:32|R/O|$16|Minor version.  This value is the day that the design was synthesized, tested, and released to the public repository.|
|31:28|R/O|$01|Patch version.|
|27:0|R/O|0|Reserved for future definition.|

This register identifies the version of the processor design.
This can be used to,
for example,
detect processor cores which are known to exhibit or to have fixed certain bugs.

### mhartid ($F14)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/O|0|Hardware Thread ID.|

This register is used to disambiguate "hardware threads" in a multi-processor system.
A hardware thread, or *hart* for short,
can correspond to a real
or simulated (as in the case of a hyperthreading processor)
core.

The KCP53000 only provides a single execution engine,
capable of interpreting only a single stream of instructions.
Thus, this register is hard-wired zero.

### mstatus ($300)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|64:13|R/O|0|Reserved.|
|12:8|R/O|$1D|Reserved.  In a more capable, multi-mode processor, this field provides space to record the interrupted program's privilege level.  Since the KCP53000 only supports M-mode, these fields are hard-wired and serve no useful purpose.  The values can be interrupted as follows: machine-mode thinks the interrupted program was running in machine-mode, hypervisor-mode, and supervisor-mode respectively.  In other words, regardless of mode, the previous privilege level refers to the maximum possible privilege level for that mode.|
|7|R/W|0|**MPIE**.  Machine-mode Previous Interrupt Enable.  If the processor traps for any reason, a handler can look at `MPIE` to see if the interrupted program had interrupts enabled or not.  When an interrupt is honored, `MIE` is cleared automatically, to prevent infinite looping on the state of the interrupt.  `MPIE` allows `MIE` to be restored when an MRET instruction is executed.|
|6:4|R/O|0|Unused.|
|3|R/W|0|**MIE**.  Machine-mode Interrupt Enable.  If set, interrupts are recognized and honored.  If clear, interrupts are ignored.|
|2:0|R/O|0|Unused.|

### medeleg ($302)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/O|0|Bitmap indicating which exceptions (traps) are to be delegated to the next lower privilege level.  Bit 0 corresponds to `mcause` value of 0, bit 1 to cause 1, etc.  See the documentation for the `mcause` register for more details.|

The KCP53000 only supports machine-mode, so this register is superfluous.  It is hardwired to zero, indicating machine-mode is the correct privilege level to handle the event.

### mideleg ($303)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/O|0|Bitmap indicating which interrupts are to be delegated to the next lower privilege mode.  Bit 0 corresponds with interrupt source 0, bit 1 to interrupt source 1, etc.|

The KCP53000 only supports machine-mode, so this register is superfluous.  It is hardwired to zero, indicating machine-mode is the correct privilege level to handle the event.

### mie ($304)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:12|R/O|0|Reserved for future use.|
|11   |R/W|0|External interrupt enable.|
|10:0 |R/O|0|Reserved for future use.|

The KCP53000 only supports machine-mode;
thus, only a single interrupt enable flag is available through this register.

### mtvec ($305)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/W|$FFFFFFFFFFFFFE00|Pointer to trap handler.|

This register points to the procedure responsible for handling both traps and interrupts.  This procedure **must** return with the MRET instruction at some point.  Bits 1:0 should be held zero, to ensure the procedure is properly aligned.

### mscratch ($340)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/W|0|Scratch value.|

This register is a temporary register to allow trap handlers to save context without destroying any values in the general purpose register set.  The CPU neither interprets nor cares what you use it for.

Some operating systems use this register to point to a thread's context area.  Then, when a trap is invoked, the handler saves the interrupted program state in that context like so:

        csrrw   x31, x31, mscratch      ; Exchange X31 and MSCRATCH
                                        ; X31 now points to context area,
                                        ; while MSCRATCH preserves X31.
        sd      x1, r_X1(x31)           ; Now we save our GPRs...
        sd      x2, r_X2(x31)
        ; ...
        sd      x29, r_X29(x31)
        sd      x30, r_X30(x31)
        csrrw   x1, x0, mscratch        ; X1 = interrupted X31
        sd      x1, r_X31(x31)          ; can use any register, actually.

        ; At this point, X1 is now free for use per normal ABI.
        ; X31 still refers to the interrupted thread's state.
        ; A scheduler can point X31 to any other thread at this time.
        ; Restoring the register set happens as above,
        ; but in reverse.

        ld      x1, r_X31(x31)
        csrrw   x0, x1, mscratch
        ld      x30, r_X30(x31)
        ld      x29, r_X29(x31)
        ; ...
        ld      x2, r_X2(x31)
        ld      x1, r_X1(x31)
        csrrw   x31, x31, mscratch      ; MSCRATCH points to (new) thread state
        mret

### mepc ($341)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/W|0|Interrupted task's PC.|

In the event the CPU takes a trap, this register holds the address *of the instruction that trapped*.
Unlike other CPU instruction set architectures,
it does not matter what the nature of the trap actually is.
For example,
with the Intel x86 ISA,
executing `INT 3` in ring-0 will cause a breakpoint interrupt.
The stacked PC refers to the byte *following* this instruction.
However, if a program attempts to invoke this interrupt in ring-3 (user mode),
and if the program lacks permissions for this,
a general protection fault occurs, and the stacked PC points *at* this instruction.
Knowledge of where the PC points must be baked into the respective handlers.

A similar experiment can be tried with the RISC-V instruction set,
using the `CSRRSI` instruction to access the `mip` CSR.
If you invoke `CSRRSI X0, 16, mip` in machine-mode on a processor supporting inter-hart software interrupts,
you'll generate an interrupt.
The trap handler will find the address of the `CSRRSI` instruction in `mepc`.
However, if you attempt the same in user-mode, you'll generate an illegal instruction trap.
Again, the `mepc` register will point at the `CSRRSI` instruction.

If the CPU is honoring a hardware interrupt,
the contents of this register
points at the instruction that *would have* been executed next
if the interrupt hadn't occurred.

### mcause ($342)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63|R/W|0|Interrupt flag.|
|62:4|R/O|0|Reserved.|
|3:0|R/W|0|Trap cause.|

This register provides the reason why the trap handler was invoked.
Bit 63 is set if it's due to an external interrupt source, and
clear if the trap was caused by an internal exception.
The high bit is used because it facilitates dispatching with a single `BLT` instruction.

Bits 3:0 contain the source of the trap (whether external or internal).
The following values are supported:

|Interrupt|Cause|Origin|
|:-------:|:---:|:-----|
|0|2|Illegal instruction|
|0|3|Breakpoint (`EBREAK`)|
|0|11|`ECALL` from machine-mode|

Note that external interrupts are not yet supported as of this publication.
(They're coming!)

### mbadaddr ($343)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/W|0|Address which caused the fault.|

The processor does not support an MMU and cannot generate access faults.
This register is therefore not currently used by the processor,
and may be used as a scratch register.

**NOTE:** Future processor revisions *may* implement protection features.
For example, alignment traps will set `mbadaddr` to the faulty address when taken.
Therefore, for future compatibility,
*do not* depend on this register's contents across traps.

### mip ($344)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:12|R/O|0|Reserved for future use.|
|11   |R/O|0|External interrupt pending.|
|10:0 |R/O|0|Reserved for future use.|

The KCP53000 provides a single external interrupt pin;
the state of this pin is visible through this register.

Note that this pin is not registered.
If `irq_i` is brought low,
then bit 11 of this register will return to 0.

### mcycle ($F00)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/O|0|Clock cycle counter.|

This is an up-counter which increments by one for every rising edge of the processor's `clk_i` signal.

### mtime ($F01)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/O|0|Wall-clock counter.|

This is an up-counter which increments at a rate determined by an external timebase.  The KCP53000 does not support an external timebase as of this publication.  Therefore, this register is hardwired zero.

### minstret ($F02)

|Bits|R/W|Value|Description|
|:--:|:-:|:---:|:----------|
|63:0|R/O|0|Instruction execution counter.|

This is an up-counter that increments every time the CPU fetches an instruction.


## Program Counter

The program counter points to the instruction to be fetched next.
Although all 64-bits of the program counter are implemented,
it should always be loaded so that bits 0 and 1 are clear
(e.g., it always refers to an aligned 32-bit word in memory).
If this is not the case,
it is up to an external I-port bus bridge to determine the semantics.
Typically, this is an error condition,
and will raise a fault.
However, it's possible an external bridge can support unaligned memory accesses
and allow instructions to appear on non-aligned boundaries.

When `reset_i` is asserted, this register is set to $FFFFFFFFFFFFFF00.

