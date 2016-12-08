---
layout: post
title:  "Modular Firmware"
date:   2016-12-06 16:00:00
---

## Abstract

What is the problem?
Why is it a problem?
What is my solution?
Why should you pay attention to my solution?

## Introduction

The Kestrel-3 requires, like any computer, some "initial program" in order to run.
Unlike the IBM System/360 and DEC PDP-11,
I cannot just place a deck of punch cards or a roll of paper tape in a reader to "IPL" the computer.
The initial program for the Kestrel-3 must be placed in ROM, or something approximating its behavior.
This should come as no surprise to anyone.

However, the Kestrel-3 computer design aims to target at least two different FPGA development boards:
the Digilent Nexys-2 (no longer manufactured), the Terasic DE-1, and if I can make it fit, the myStorm BlackIce module.
I also have an Avnet LX9 MicroBoard which, while not directly capable of hosting a full Kestrel user experience,
might still be usable as an intelligent network controller running Kestrel firmware.
Each of these modules offers *very* different capabilities, as the table below demonstrates:

|Feature|Nexys-2|DE-1|Black Ice|Avnet LX9|
|:------|:------|:---|:--------|:--------|
|Video Resolution|configurable up to 640x480 maximum|configurable *at least* up to 640x480, possibly capable of 800x600 or higher|Expansion required.|Expansion required.|
|Color Depth|2, 4, 16, or 256 colors out of a palette of 256|2, 4, 16, or 256 colors out of a palette of 4096|Expansion required.|Expansion required.|
|Audio|Expansion required.|24-bit codec standard.|Expansion required.|Expansion required.|
|Keyboard|PS/2|PS/2|Expansion required.|Expansion required.|
|Mouse|Expansion required.|Expansion required.|Expansion required.|Expansion required.|
|Mass Storage|Expansion required.|Built-in SD card.|Built-in SD card.|Expansion required.|
|Network|Expansion required.|Expansion required.|Expansion required.|10/100 Ethernet|
|General purpose I/O|Three 2x6 usable Pmods (out of four) + Hirose adapter exposing 43 I/Os|Two 40-pin IDC connectors exposing 36 I/Os each|Two 1x6 Pmods + Six 2x6 Pmods + ARM-based I/O (Arduino-compatible) + header pins|Two 2x6 Pmods|
|RS-232|DB-9|DB-9|Expansion required.|Expansion required.|
|ROM|Block RAM + 16MB Flash|Block RAM + 4MB Flash|Block RAM only|Block RAM + 16MB Flash|
|RAM|16MB Cellular RAM (in asynchronous mode, 70ns access)|512KB 10ns SRAM + 8MB SDRAM|512KB 10ns SRAM|64MB LPDDR SDRAM|

Even if we focus just on the Nexys-2 and DE-1 cross-compatibility concerns,
we find enough differences that a single binary image for the Kestrel's firmware will not suffice.
At some point, some build-time knowledge will be required to put the correct platform-specific modules together.

In higher-level operating system environments,
you can rely on a tool called a *linker* to get this job done.
You build all your components, and then you pass them to a linker to produce a final output binary.
This process depends upon the host and/or target environment having
what's called a *loader* to finally place and, if needed, relocate the binary image.
However, when working with bare metal, without the support infrastructure of an operating system,
writing a loader is a significant chunk of work.
It's complicated, it's error-prone, it can be quite large in size,
and it has no way of telling the user of any errors because
it cannot necessarily depend on character output drivers.

## Method

A smaller, simpler way that is easier to verify for correctness is needed.
I propose a method of systems-level integration
where the "linking" step is performed by a combination of the Unix commands `cat`, `dd`, and `truncate`,
and which requires no sophisticated loader to function.
Some discipline is required to successfully write firmware modules;
however, the extra burden on the developer is fairly small.
For such a system to work, the following must hold true:

* All software is written to be position-independent.
* Every module needs to start with a small header.
* The firmware contains procedures to dynamically discover and initialize modules as they're needed.
* The firmware also needs a way to initialize certain modules *before* they're actually needed.

With these requirements met,
it is possible for even web-based applications hosted on low-powered virtual machines
to offer customized firmware images for immediate download
without having dependencies on expensive build environments
or dependency graph information.
The images can be synthesized on-demand for the user's device(s) on an as-needed basis,
given only a selection of components appropriate for the user's needs.

I discuss each of these requirements in greater detail below.

### Requirements

**All software is written to be position-independent.**
A given set of modules should be able to be combined in any order and still be expected to work.
Software is written in a modular manner:
all modules are self-contained, statically linked,
and any linkage required between modules occurs dynamically at run-time
through jump-tables or data structures referenced by CPU registers.
This enables software components to be written with the most simplistic of development tools.

To acquire a reference to a module in the first place,
a well-known procedure is required to resolve the name to a module reference.
(This will be discussed in the third requirement description, below.)
The RISC-V instruction set is position-independent by default,
which makes satisfying both of these requirements unusually easy.

**Every module needs to start with a small header**
that identifies the module by name, and locates where to find subsequent modules.
As of this writing, the header looks like this:

    dword   MatchWord
    byte    "ModuleName      "
    hword   ModuleDataSize
    hword   ModuleFlags
    hword   DisplacementToJumpTable
    hword   DisplacementToNextModule	; 22 bytes

The `MatchWord` field **must** begin on an 8-byte boundary,
which must also be the very first 64-bit word of the module.
The value of `MatchWord` currently must equal $05ADC0DEFEEDC0DE.
This sequence of bytes is statistically improbable to appear in legitimate code *or* static data,
and therefore serves as a nice tag indicating the presence of a module.

The `ModuleName` field consists of up to 16 ASCII characters,
padded by spaces.
Some example module names are below:

    byte    "executive       "
    byte    "file system     "
    byte    "gpio            "
    byte    "IllegalInstHndlr"

The fixed-length text field was selected because
it requires only two `bne` or `beq` instructions to test for (in)equality,
saving the firmware implementor the burden of a general-purpose `strcmp()` function.
Additionally, the 16-byte field width
provides suitable descriptive power without worrying about name collisions in the general case.
If collisions becomes a problem,
the field is perfectly sized for transitioning to a UUID-based identifier
without breaking previously written software.

The `ModuleDataSize` field indicates to the firmware how much memory this module needs to maintain its state.
It will be described in greater detail later.

The `ModuleFlags` field only has one bit defined in this proposal:
bit 0 is the `PREOPEN` bit.
All other bits **must** be written as zero,
and ignored upon read, to ensure compatibility with future revisions of this protocol.
The meaning of the `PREOPEN` bit will be discussed later.

The `DisplacementToJumpTable` field contains a *byte displacement relative to the `MatchWord` field*.
This reference tells the firmware where to find this module's *jump table.*
Each module is required to implement a minimum of four jump table entry points:

    jal     x0, Init            ; The very first jump table entry
    jal     x0, Open
    jal     x0, Close
    jal     x0, Expunge
    ; Module-specific entry-points follow.

The `Init` procedure is responsible for performing the one-time, global initialization of the module.
The `Open` procedure is invoked whenever the module is opened by a client.
The `Close` procedure is invoked whenever the module is closed by a client.
The `Expunge` procedure is called when a module should perform global shut-down procedures.
Note that both `Close` and `Expunge` *cannot be allowed to fail*, while `Init` and `Open` can.
How these entry points and procedures are used
will be discussed later.

The `DisplacementToNextModule` field contains a *byte displacement relative to the `MatchWord` field*.
This allows the firmware looking for modules
to find the next module in the firmware image, assuming one exists.
**NOTE:** this field must never equal zero, or simplistic system firmware images *may* end up in an infinite loop.

**The firmware contains procedures to dynamically discover and initialize modules as they're needed.**
The most important procedure is `OpenModule`,
which is responsible for invoking the `Open` entry point of the named module.
(I'll discuss the protocol between `OpenModule` and the standard entry points listed above, later.)
A typical invokation looks like this:

                    align   8
    _execName:      byte    "executive       "      ; Remember, pad to 16 places
    _openExec:      addi    sp, sp, -8
                    sd      ra, 0(sp)

    _oeReference:   auipc   a1, 0                   ; A1 -> name of module to open
                    addi    a1, a1, _execName - _oeReference
                    ld      a0, ModulesBase(x0)     ; A0 -> module manager's data
                    ld      a2, 0(a0)               ; A2 -> jump table for module manager
                    jalr    ra, EP_OpenModule(a2)

                    ld      ra, 0(sp)
                    addi    sp, sp, 8
                    jalr    x0, 0(ra)

If the call succeeds, the `a0` register will point to the opened module's instance structure in memory,
which is completely opaque to the caller
*with the sole exception* that offset zero of that structure refers to the module's jump table.
This is why the example first loads `a0` with the contents of the pointer at `ModulesBase(x0)`,
and then obtains the modules facility's jump table by setting `a2` to the contents of `0(a0)`.
As can be seen, the API covering modules is itself a module.

If the named module failed to open for any reason, `a0` will equal zero.

**The firmware also needs a way to locate and initialize certain modules before they're actually needed**,
such as illegal instruction handlers intended to emulate support for missing RISC-V instructions.
Normally, `OpenModule` will only open the named module and,
indirectly via that module's initialization code,
all dependencies when it is required.
However, some modules may choose to implement features missing in the target processor.
For instance, the KCP53000 CPU lacks both floating point and multiply instruction set extensions.
Yet, it's exceptionally handy to have both of these sets of instructions.
One or more named modules could implement the trap handlers required to make this happen,
but they need to be initialized before anything else runs.
Such modules have their `PREOPEN` flag set,
and the firmware will open them upon discovery just after the cold-boot start-up code runs.

### Protocol

A module is a self-contained, statically linked binary blob with no outside dependencies requiring fixups to run.
However, it almost certainly will have outside dependencies to *function* at run-time.
How does a module reconcile these attributes?

We start with the basic operation of the `OpenModule` procedure,
and in particular, the case where a module has already been opened once before.
`OpenModule` starts by looking through a table of already-opened modules.
If the named module is found, then it invokes that module's `Open` procedure via its entry points.
This gives the opened module a chance to perform relevant book-keeping.
Note that the opened module receives a pointer to its global data structure via the `a0` register,
just like any other module entry point.
Through this register, the module may access global or local data structures.
**NOTE:** General purpose dynamic memory management services will not generally exist,
unless a separate module has implemented such a service.
Therefore, modules should generally work with fixed-sized data structures where possible.

What happens when the named module has not yet been opened before?
`OpenModule` will not find its name in the list of open modules,
and so falls back on performing a scan of the firmware image.
It starts at the beginning of the firmware at a well-known or calculated address,
and checks to see if the `MatchWord` field matches.
If so, it then compares the `ModuleName` field against that sought.
If there is a successful match,
`OpenModule` will take the following rough steps:

1.  Determine the module's data requirements by reading the ModuleDataSize field.
2.  Allocate 8 + ModuleDataSize bytes of memory from the Boot Data Area (BDA).  This will become the Module Data Area (MDA).
3.  Compute the absolute address of the module's jump table, and set offset 0 of the MDA to point to it.
4.  Invoke the `Init` procedure of the module, passing the MDA in register `a0`.  This procedure is intended to *initialize* the global state of the MDA as given.  Remember that this may involve recursively opening dependent libraries!
5.  If the procedure returned with a successful outcome, store the MDA in a list of open modules.
6.  Open the module per the procedure discussed above.

If the name does not match,
the address of the next module header is calculated by summing the current header's address
and its `DisplacementToNextModule` field.
This process repeats for as long as headers exist (as long as the `MatchWord` matches expectations).

<img src="{{site.url}}/images/modular-firmware-struct-layout.svg" alt="Figure 1: Relationships between modules, headers, jump tables, BDA, and MDAs." />

