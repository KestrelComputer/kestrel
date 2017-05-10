# STS Application Binary Interface

This document attempts to establish the operating environment
used by a program running under the STS operating system.

* Status: **DRAFT**
* Date: Fri Nov 20 17:40:11 PST 2015

## Program Format

An executable file consists of an 8-byte header,
followed by the actual software.

                dword   $0000000000008067
        start:  ; code follows.

An assembler which produces only raw binary output
is sufficient to generate the header, as above,
or, it may generate it through the following sequence:

                jalr    x0, 0(x1)
                word    0
        start:  ; code follows

## Code, Data, and BSS Segments

This executable format
does not provide
for initialized or uninitialized
data segments as distinct entities.
The entire contents of the file,
including the header,
is treated as a single, opaque block of code.

Initialized data typically appears
colocated with executable code
in the file.
While not an optimal solution,
particularly for systems employing memory management hardware,
it significantly simplies the implementation
of STS itself.

Uninitialized data
must be explicitly allocated
by the program itself.

This implies that,
except under highly specialized situations,
STS' executables are not re-entrant:
the code images cannot be shared
across different processes
without employing some form of copy-on-write solution.

This also implies
that the code image in memory
MUST
be writable,
so that the application may save critical state,
such as the base address to its self-allocated, uninitialized data segment.

STS executables can be loaded at any dword-aligned location in memory.
RISC-V instructions are position-independent by intention,
so no need exists to relocate the loaded image.

## Initial Conditions

When a program is launched under STS, the registers are set
as follows, according to the ABI established by the current
BSPL compiler.

        PC              Base address of the header, plus 8.
        X1              Return Address to whatever launched your program
        X2              Data Stack Pointer
        X3              Return Stack Pointer
        X4              Global Variables Pointer
        X5..X15         Undefined; best not to use them without saving first.
        X16..X31        Undefined; these needn't be saved.

### PC

Execution of an STS binary commences
exactly 8 bytes following the `JALR` header.
Given that the header is kept as part of the loaded image,
and if we see a module is loaded at address `$123400`,
then the initial PC register will be `$123408`.

### Return Address (X1)

Per current BSPL compiler implementation details,
the X1 register conventionally holds the return address of a subroutine.
Since the caller invokes a binary as a subroutine,
this implies that X1 contains the return address.
The caller may or may not be STS itself.

The contents of this register MUST be saved
prior to use by the application.

### Data Stack Pointer (X2)

The X2 register will point
to the top of the caller's data stack.
The caller is typically, but need not be, STS V1.5 itself.

The stack will contain a parameter block,
providing the called program with enough information
to productively use the STS operating system services.

Note that the size of the caller's data stack isn't known
by the called program.
The caller MUST arrange at least 64 bytes for the called program's use.
If more than 64 bytes will be needed,
it's in the program's best interest
to allocate its own data stack.

Before returning to the binary's caller,
X2 will need to be restored with this initial value.


### Data Stack Contents

The calling program MUST place some parameters on the data stack.
This information provides the called application
with the system-level linkage it needs to
follow the user's specific instructions through command parameterization,
and to actually invoke STS system calls.

The linkage structure MUST be laid out as follows on caller's data stack:

        DSP+0           Pointer to STS system call jump table.
        DSP+8           Return code (defaults to 0).
        DSP+16          Undefined; reserved for the caller's use.
        DSP+24          Length of the command name.
        DSP+32          Address of the command name.
        DSP+40          Length of the command tail.
        DSP+48          Address of the command tail.

#### STS System Call Jump Table

This field points to a simple array of `JAL` instructions,
each corresponding to a STS system call entrypoint.
These entry points will be described in a separate document.

The calling program MAY provide its own implementation
of the STS system calls.
The called program never knows the official STS jump table location,
so can never truly know if it's directly using STS facilities or not.
This allows some programs to encapsulate STS features for other programs.

For example, a trace utility can launch another STS program,
providing its own system call table to capture and log system calls,
as `strace' does for Linux applications.
Yet another program may provide cooperative multitasking,
by switching tasks on all potentially long-running I/O operations.
Still others may provide sandboxing rules for untrusted programs,
limiting access to filesystem resources
or imposing quotas on memory consumption.
The STS kernel itself need not explicitly support these features.

#### Return Code

If your program wishes
to return a result code
to the calling program,
such as a command shell,
you'll need
to update the value
at DSP+8 with
the appropriate value
prior to returning.
This value will be interpreted by the calling program.
It defaults to zero,
usually taken to mean "success",
so programs don't need to explicitly change it
unless it wants to communicate a failure.

#### Command Name and Tail

The command name address and length fields
lets the command discover the filename used to invoke the program.
This typically has two uses:

1.  If you use symbolic links to create a number of aliases for a single binary, the program may select what function to perform based on how it was invoked.
2.  If the program generates an error, this information is used to provide a customized usage report.

The command tail address and length fields
provides user-supplied arguments to the command.
Neither STS nor its shells interpret the command tail.

For instance, let's suppose you write the following command on the shell:

        copy from /rom/* to /ramdisk all

The program, when run, will have the command name of `"copy"` (sans quotes)
and the tail set to `" from /rom/* to /ramdisk all"`.
Observe the leading whitespace on the tail.
Printing the command name and tail, in that order,
with no intervening prints, will print the command exactly as typed.

Although STS does not interpret command names, tails, or results,
standards surrounding their use is encouraged.
If any such standards exist, they will be documented in separately.

### Return Stack Pointer (X3)
The X3 register will point
to the top of the caller's return stack.
The caller is typically, but need not be, STS V1.5 itself.

Note that the size of the caller's return stack isn't known
by the called program.
The caller MUST arrange at least 64 bytes for the called program's use.
If more than 64 bytes will be needed,
it's in the program's best interest
to allocate its own return stack.

Before returning to the binary's caller,
X3 will need to be restored with this initial value.

### Global Variables Pointer (X4)
The `JALR`-header executable file format described here
provides no support for BSS or uninitialized data segments.
However, such segments are desirable for proper operation.

X4 typically points inside a 4KiB block of memory reserved
for global variables.
BSPL global variables are allocated from this block of memory.
Allocations start at offset -2048 and continue upwards in memory.
The RISC-V indexed addressing mode only supports 12 bits of displacement,
hence the 4KiB limitation.
X4 points in the middle because RISC-V sign-extends all displacements.

It is the responsibility of the called program to create its own
uninitialized data segment.
This implies that this register MUST be saved during program start-up.

This pointer MUST be restored prior to returning to the caller.

### Reserved Registers (X5..X15)

These registers are currently not allocated by the BSPL runtime
or compiler.  They may therefore be used by the application as it sees fit.
However, be aware that sub-programs may also use them.
This includes STS itself.

Therefore, if these registers are going to be used by your application,
make sure you save and restore them appropriately.

### Evaluation Registers (X16..X31)

These registers are used by BSPL to simulate a data stack for expression evaluation purposes.
Therefore, these registers may be used for any purpose by the application.
Unlike X5 through X15, though,
convention dictates that any control flow
invalidates the contents of these registers
(unless you or your compiler can statically determine their stability).

