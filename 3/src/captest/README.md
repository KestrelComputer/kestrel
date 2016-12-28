Judging by the issues discussed in the RISC-V mailing lists
concerning config-string versus (possibly flattened) device tree,
I think it's reasonably well understood
that hardware auto-discovery
is a hard problem to solve.
It seems that device tree-like structures exist to
[communicate system configuration information which is not easily auto-detectable.](http://elinux.org/Device_Tree_What_It_Is)
This solution makes sense for legacy systems, such as Intel x86-based architectures or ARM.

When you have a fresh platform such as RISC-V,
you have a clean slate before you.
It ought to be possible to construct your hardware ecosystem
such that the need for a device tree is [obviated](https://duckduckgo.com/?q=define+obviated&t=canonical&ia=definition).
I claim that the very need for a device tree is itself a terribly pungent [design smell.](https://en.wikipedia.org/wiki/Design_smell)

The discovery of memory pools is one area
where device tree notations seems to find significant use.
Consider where,
in a previous article,
I detail the differences between the Digilent Nexys-2 and Altera/Terasic DE-1 configuration for the Kestrel-3 hardware.
The Nexys-2 consists of a single 16MB RAM resource, while
the DE-1 contains two RAMs of different technologies and capacities: a 512KB static RAM and a 64MB SDRAM.
How can system software adapt to these two configurations without the use of a device tree structure?

In this article,
I use pseudocode to describe the algorithm chosen to determine
the largest memory window supported by a particular Kestrel-3 configuration.
I link to the actual assembly source code that is known to run on `e`.

Broadly, the algorithm works by assuming only the smallest reasonable amount of installed RAM
(256 bytes in the current implementation),
and iteratively doubling its understanding of how much RAM is installed by looking for evidence of mirrors.
If the hardware supports it,
non-existent memory traps are turned off, and allowed to complete with garbage data.
Otherwise, this must be emulated in a trap handler.

The code has successfully determined that `e` supports only 16MB of RAM,
despite that the entire 2^56 byte region of memory
from $0000000000000000 to $00FFFFFFFFFFFFFF
mirrors the same 16MB image throughout the space.

It should be pointed out early that
this approach to memory discovery is not precise.
Assuming we map a 64MB SDRAM at address 0,
followed by a 512KB static RAM at address $4000000,
this algorithm will not report 64.5MB of memory installed.
However, it *will* tell you that the sum total of the memory found
will fit inside a 128MB window.
Knowing this upper-bound now lets you employ different discovery approaches
to find smaller sub-pools within this larger limit.
For instance,
you can apply this algorithm recursively to decompose RAM mappings
to discover specific pools, where they exist, and how big they are.
To keep matters simple, however,
this article focuses just on the basic algorithm.

## The Algorithm

I reproduce the core of the algorithm below.
We start out by making sure we have *any* amount of RAM accessible at all
by attempting to manipulate location 0.
If we fail to verify this works as intended,
then in the event no RAM exists at all,
we'll see a false report of maximum possible memory allotment.

Assuming we know we have RAM accessible to us,
and we know it is of a certain minimum size
(currently assumed to be 256 bytes),
then we attempt to iteratively locate where memory mirroring happens.

    Find the largest supported capacity:
      Store check value at location 0.
      IF location 0 does not match the check value THEN
        Assume no RAM exists.
      ELSE
        Assume a minimum of RAM capacity.
        WHILE we continue to find RAM(capacity) AND \
              we haven't exhausted maximum possible capacity(capacity)
        DO
          Double the known memory capacity.
        END
        IF we've exhausted the largest possible memory capacity, THEN
          Assume a full compliment of RAM.
        END
      END

This works because the Kestrel-3 only performs partial address decoding
for its memory resources.
If address bits 59:56 of an address are 0, then it activates the memory
subsystem.
Note that address bits 63:60 are currently ignored, while
address bits 55:0 are at the discretion of a particular Kestrel-3 implementation.
The Nexys-2 build of the computer will ignore bits 55:24,
while the DE-1 build will ignore bits 55:27.
This greatly economizes on the hardware resource consumption inside an FPGA.

The software, basically,
causes a write transaction to memory by raising successively larger address bits.
It starts with ADR\_O[8], then moves to ADR\_O[9], and so on
until the write affects the value of location 0.

    We continue to find RAM(capacity):
      Create a new value to store(check value).
      Store value at capacity limit.
      IF value at location 0 matches our new value THEN
        We reached RAM's end; FALSE.
      ELSE
        We have not reached capacity yet; TRUE.
      END

In the worst case scenario,
the algorithm will terminate after 48 iterations,
indicating that the maximum memory window of 2^56 bytes is supported.
However, more realistic implementations will terminate
in closer to 16 to 19 iterations.

    We haven't exhausted maximum possible capacity(capacity):
      IF capacity < 2^56 THEN
        TRUE.
      ELSE
        FALSE.
      END

Every time we write to memory,
we compute a new double-width word (64-bit integer for RISC-V processors) to store.
This combats accidentally stumbling upon a random bit pattern
in uninitialized RAM
that happens to match our current check value.
If accidental matches become a problem,
you can invoke this algorithm
an odd number of times, and rely on a voting
algorithm to determine the largest memory access window in a probabilistic manner.

    Create a new value to store(new value):
      LET new value be the previous value shifted left 8 places, ORed with \
          low byte of previous value plus 1.

Other than the storage requirements for such variables as
the storage capacity and current check value,
that's the crux of the algorithm.

    Global 64-bit Variables:
      Check value
      Known memory capacity

The output of the algorithm
as currently implemented
will be a byte address pointing at the first byte of any detected mirror.
Thus,
the address will consist of a single bit set,
indicating the first bit to be ignored by address decode logic.

## Demo Program

The following PDL lists the pseudo-code for a demo program designed to illustrate
how the software works. 
Its job is to calculate the largest addressable RAM location inside the memory window.
It relies on the algorithm described above,
then prints out a message to the MGIA frame buffer.
This allows the user to see the results without needing specialized terminals.

    Global 64-bit Variables:
      Check value
      Known memory capacity
      Frame buffer pointer

    Global 80-byte Structures:
      Line format buffer

    Global 2KB Structures (read-only):
      Font

    Create a new value to store(new value):
      LET new value be the previous value shifted left 8 places, ORed with low byte of previous value plus 1.

    We continue to find RAM(capacity):
      Create a new value to store(check value).
      Store value at capacity limit.
      IF value at location 0 matches our new value THEN
        We reached RAM's end; FALSE.
      ELSE
        We have not reached capacity yet; TRUE.
      END

    We haven't exhausted maximum possible capacity(capacity):
      IF capacity < 2^56 THEN
        TRUE.
      ELSE
        FALSE.
      END

    Find the largest supported capacity:
      Store check value at location 0.
      IF location 0 does not match the check value THEN
        Assume no RAM exists.
      ELSE
        Assume at least one dword of RAM capacity.
        WHILE we continue to find RAM(capacity) AND we haven't exhausted maximum possible capacity(capacity) DO
          Double the known memory capacity.
        END
        IF we've exhausted the largest possible memory capacity, THEN
          Assume a full compliment of RAM.
        END
      END

    Print the format buffer:
      Start with the top-most font raster.
      Start at the current frame buffer position.
      FOR all raster rows in font DO
        Start at beginning of format buffer.
        FOR all characters in the format buffer DO
          Map current character code to glyph byte.
          Store byte into corresponding frame buffer byte.
          Advance format buffer and frame buffer references.
        END
        Advance to the next raster.
      END

    Print the largest capacity supported:
      Prepare 80-column format buffer.
      Copy "Largest Detected Memory Capacity: $0000000000000000 to $" to buffer.
      Convert memory capacity (minus 1) into hexadecimal in the format buffer.
      Print the format buffer.

    Initialize:
      Clear the screen.
      Start at top-left corner of the screen.
      Initialize check value to '1111111111111111'X.

    Main Program:
      Initialize.
      Find the largest supported capacity.
      Print the largest capacity supported.
      Halt.

The assembly listing for this program can be found
[on Github.](https://github.com/sam-falvo/kestrel/blob/master/3/src/captest/captest.asm)

## Limitations

The results of this software
is being used to help implement the Kestrel-3's
first support for external RAM resources.
It can be used to ensure proper operation of the address decode logic,
as well as providing a very simple check that RAM is properly supporting reads and writes.

However, as indicated previously,
this approach is limited in that it cannot
discern tightly packed memory resources on its own.
For example, in the case of the DE-1 configuration,
RAM might appear as follows:

    0             64MB    65MB    66MB        128MB
    +---------------+---+---+---+---+---+...+---+
    |  64MB  SDRAM  | M | M | M | M | M |...| M |
    +---------------+---+---+---+---+---+...+---+

where each `M` refers to a mirror image of the 512MB static RAM chip.
From this algorithm's perspective, it'll happily see 128MB of memory.
To get a more precise understanding of the memory configuration,
you would first use this algorithm to get a big-picture overview of memory supported.
Then you would halve the search space, and repeat the use of the algorithm.
Adjusting the algorithm to search only between 0 and 64MB will yield a complete RAM allotment,
so we know it's accurate.
However, searching from 64MB to 128MB will reveal only 512KB installed.
We can repeat this again, finding that the 512KB is fully resolved only when it reports being completely implemented.
This mode of operation will require some changes to the basic algorithm detailed here.

Another limitation is that it cannot handle the case where
separate discontinuous memories exist.
Consider the example below:

    0             64MB    65MB    66MB
    +---------------+---+---+---+---+---+...
    |  64MB  SDRAM  | M |   | N |   | O |...
    +---------------+---+---+---+---+---+...

In this case, applying the algorithm globally will correctly identify 128MB address window.
However, applying recursively to the 64MB..128MB region will indicate a total presence of 64MB RAM present.
This is because no component memory exhibits wrap-around behavior.

In another case, we introduce mirrors, like so:

    0             64MB    65MB    66MB
    +---------------+---+---+---+---+---+...
    |  64MB  SDRAM  | M | M | N | N | O |...
    +---------------+---+---+---+---+---+...

In this case, the algorithm will only successfully detect the memory pool at M,
and not N, O, or subsequent pools.

I think it is important to consider that in both of the latter non-contiguous memory cases,
the systems engineer is easily in a position to fix this problem by just coalescing memory allotments.
Avoiding the need for device tree descriptions of memory is as simple as "don't do that."

## Conclusions

I've detailed an algorithm that,
in its most basic form,
can identify the size of the address decode window closest to the CPU.
I've discussed limitations with the algorithm,
and provided ideas on refining it to support drilling down into the memory hierarchy,
allowing it to refine increasingly finer memory windows.
I've provided example code which is proven to work in emulation,
and is actively being used to help implement an FPGA version of the computer.

With this technology,
I'm hoping to continue to build the Kestrel-3 in a way that avoids the need for device tree functionality.
I'll discuss more topics related to this as work continues on the computer.

