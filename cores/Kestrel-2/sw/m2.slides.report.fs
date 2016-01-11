program progmem.ram10
start slide

24 left !  5 top !   S" Report on the RISC-V Workshop #3" text

21 left !  2 top +!  S" --------------------------------------" text

31 left !  2 top +!  S" Samuel A. Falvo II" text
32 left !  1 top +!  S" kc5tja@arrl.net" text

32 left !  2 top +!  S" 2016 January 5" text



slide S" What RISC-V is NOT..." title

slide S" THIS is RISC-V" title

S" _strlen:	addi	t0, a0, 0	; Save our original address" text  1 top +!
S" _sl2:	lb	t1, 0(a0)	; Find NUL byte in string" text  1 top +!
S"		beq	t1, x0, _sl1" text  1 top +!
S"		addi	a0, a0, 1" text  1 top +!
S"		jal	x0, _sl2" text  1 top +!
S" _sl1:	sub	a0, a0, t0	; Calculate length" text  1 top +!
S"		jalr	x0, 0(ra)	; Return to C program" text  1 top +!
1 top +!
S" http://www.riscv.org" bullet


slide S" About the Workshop" title

S" First workshop put on by the newly founded RISC-V Foundation." bullet
S" RISC-V Background" bullet
S" RISC-V Foundation Overview" bullet
S" Foundation Structure" bullet
S" Networking-focused Workshop" bullet


slide S" Agenda Walkthrough - Day 1" title

S" RISC-V Updates" bullet
S" External Debugger Support" bullet
S" AXIOM: First Silicon in Open Source 4K Film-making Camera" bullet
S" Emulating Future HPC SoC Architectures using RISC-V" bullet
S" GRVI-Phalanx: Massively Parallel RISC-V FPGA Accelerator Accelerator" bullet
S" Coreboot on RISC-V" bullet
S" RISC-V and UEFI" bullet
S" FreeBSD and RISC-V" bullet
S" Building RISC-V Software Ecosystem" bullet
S" Breakout Sessions" bullet
S" Poster Sessions" bullet


slide S" Agenda Walkthrough - Day 2" title

S" ROA Logic Parallel FPGA, ASIC Development" bullet
S" Plans for RISC-V in 2016: LowRISC Update" bullet
S" 32-bit, 100MHz, RISC-V uC w/ 10-bit SAR ADC in 130nm CMOS process" bullet
S" SoC w/ Satellite Navigation Unit based on Rocket Chip" bullet
S" RISC-V Chip w/ Photonic I/O" bullet
S" Untethering the RISC-V Rocket Chip" bullet
S" MIT's Riscy Expedition" bullet
S" Pydgin: RPython-based Instruction Set Simulation" bullet
S" ORCA: FPGA-Optimized RISC-V Soft Processors" bullet
S" PULPino: Computing for the Internet of Things" bullet
S" BOOM!  The Berkeley Out-of-Order Machine" bullet
S" Bluespec's RISC-V Factory" bullet



slide S" RISC-V Background" title

S" 2010: MIPS, SPARC, x86 were limiting for future EECS research." bullet
S" 2014: UCB froze user level instruction set for RISC-V." bullet
S" Name, RISC-V, alludes to 5th generation RISC R&D from Berkeley" bullet
S" RISC-I (1981), RISC-II, SOAR, SPUR, RISC-V (2014)." bullet
S" UCB doesn't want to be in CPU business, so they made a foundation" bullet
S" Intended to be a simple, 'three month project'" bullet


slide S" Foundation Function" title

S" Source of truth for RISC-V specs and related materials" bullet
S" Compatibility test suites will also be open" bullet
S" Test suites and membership decide whether you can use logo" bullet
S" Stewards of the trademarks, licensing model used by RISC-V" bullet
S" Maintains a directory of PD ISA and micro-arch techniques" bullet
S" Produces and sells RISC-V promotional material" bullet


slide S" RISC-V UPDATES" title

S" Compressed Instruction Set Extension v1.9 -> v2.0" bullet
S" Privileged Architecture Still in Flux" bullet
S" Privileged Architecture designed to be plug-and-play" bullet
S" Vector Extensions still being designed" bullet
S" Virtual Local Store: use cache as scratchpad RAM" bullet
S" binutils, glibc, gcc, Linux, LLVM to be upstreamed" bullet
S" SiFive Inc.: bringing agile hardware design to Semiconductor industry" bullet
S" Pressing issues: Holes and ambiguities in specification(s)" bullet
  S" FPU NaNs -- resolved -- same as Java"
  S" CSR Read/Write semantics"
  S" Comparable memory model to competition, but NOT resolved."
  S" No Hypervisor layer proposal yet."
  S" Others..."
S" Formal spec of whole ISA + memory model would be an industry first!" bullet


slide S" RISC-V Desiderata" title

S" Reference Memory Map" bullet
S" Standard Interrupt Controller" bullet
S" Power Management" bullet

S" Microcontroller Domain" bullet
S" Apps Processor/Accelerator" bullet
S" Rack-scale Machine" bullet
S" To what extent can reference implementations be shared?" bullet


slide S" AXIOM Gamma: RISC-V in a 4K Camera" title

S" Open-Source Film Camera" bullet
S" Many Partners: Antmicro, Ltd. writing software" bullet
S" Many Partners: https://www.apertus.org/en/node/152" bullet
S" And more." bullet
S" Mission: Create a platform for open source cinematography" bullet
S" Built around a backplane" bullet
S" RISC-V facilitates communication between FPGA pre-processing board and FPGA SoC main board w/ a duial-core Cortex A9 CPU" bullet


slide S" Emulating Future HPC SoC Architectures with RISC-V" title

S" Work performed by US DOE" bullet
S" HPC limited by power/watt (same limitation as deep embedded)" bullet
S" Seismic imaging application" bullet
S" Custom SoCs 400% more energy efficient than Nehalem and nVidia Fermi GPU" bullet
S" OpenSoC Fabric (open source HPC fabric)" bullet
S" Configurable for Torus, Flattened Butterfly, mesh, etc." bullet
S" 24 cards, 4 FPGAs each, 4 cores each FPGA" bullet
S" 96 cores total in use" bullet
S" Shared memory!" bullet
S" Compared with x86 dual-core, COTS server" bullet
S" RISC-V snowed x86 in interthread latency for both local and remote exchanges" bullet
S" Remote : around 90 cycles RISC-V versus over 550 for Intel" bullet
S" Local : around 10 cycles RISC-V versus over 150 for Intel" bullet
S" This despite having more chips across 24 boards" bullet
S" http://www.codexhpc.org" bullet
S" http://crd.lbl.gov/assets/pubs_presos/opensocnocarc.pdf" bullet


slide S" GRVI Phalanx" title

S" Intel buys out Altera, OpenPOWER + Xilinx, IBM z13 Mainframe uses Xilinx, etc." bullet
S" FPGA acceleration a big thing." bullet
S" Massively parallel.  Specialized.  Connected.  High throughput.  Low latency.  Low energy." bullet
S" How to convert your C++ code and compile it for FPGA?" bullet
S" If workload expressible from OpenCL, then good probability it's applicable to FPGA" bullet
S" Project: Phalanx: An Accelerator ... Accelerator" bullet
S" Run app on an FPGA" bullet
S" Connect everything together" bullet
S" Acceleration requires an efficient CPU core with OSS infrastructure." bullet
S" Austere RV32I Datapath around 250 LUTs.  Smaller than my S16X4A!" bullet
S" Expected 375MHz, about 1.5 CPI, 320 LUTs, for 1 MIPS per LUT." bullet
S" 50 clusters on contemporary FPGA, times 8 CPUs per cluster, or 200 CPUs on a single FPGA" bullet
S" (Remember each CPU runs around 375MHz)" bullet
S" Routers: 256 bit @ 400MHz = 100Gbps per link, < 5% area" bullet
S" Around 30mW per core.  Total power: 11W for approx 350 cores." bullet



slide S" Plans for RISC-V in 2016: LowRISC Update" title

S" http://lowrisc.org" bullet
S" Looking forward to Kestrel-3's GPIA-III interrupt controller!" bullet
S" 2016 Test chip" bullet
S" Tape out by end of 2016" bullet
S" 3mm * 3mm die, 28nm process, 4 cores, 32KB I$, D$" bullet



slide S" 32-bit, 100MHz, RISC-V uC w/ 10-bit SAR ADC in 130nm CMOS process" title

S" Team cracks specs to RTL and to transistor level" bullet
S" Goal: replace ARM core in high-speed, on-chip test platform" bullet
S" Low-footprint RISC-V uC similar to EFM32, with USB PHY on-chip" bullet
S" RV32IM (core integer plus mul/div instructions)" bullet
S" 3-stage pipeline, single issue, in-order" bullet
S" AHB/AXI buses for ARM interoperability" bullet
S" IRQ handling borrowed from picorv32 open-source RISC-V project" bullet



slide S" SoC w/ Satellite Navigation Unit based on Rocket Chip" title

S" https://github.com/sergeykhbr/riscv_vhdl.git" bullet
S" http://www.gnss-sensor.com" bullet
S" 1mm^2, 180nm CMOS" bullet
S" 4KB RAM, 128KB ROM" bullet
S" SPARC V8, no FPU" bullet
S" Next steps: 90nm process, RISC-V, w/ FPU" bullet
S" Based on open-source Rocket Chip design" bullet




slide S" RISC-V Chip w/ Photonic I/O" title

S" 4-way SIMD 64-tile (64-256 cores) needs 5-10 Tb/s of I/O" bullet
S" 10 Tb/s @ 10 pJ/bit is 100W (!!)" bullet
S" Also requires 2000 pins" bullet
S" Photonics overcomes these limitations" bullet
S" 1 x 20Gb/s per copper wire;  16 x 10Gbps per optical fiber DWDM" bullet
S" Goals" bullet
2 left +!
  S" photonic path to memory" bullet
  S" do this without a custom foundry" bullet
  S" Optics and electronics on the same chip" bullet
  S" Photonic interconnects chip to chip" bullet
-2 left +!
S" RISC-V is THE FIRST ISA to exploit photonics to memory" bullet
S" 1.65GHz Rocket Chip core" bullet
S" 70 million transistors, 850 photonic devices" bullet
S" 1MB RAM" bullet
S" 3mm x 6mm die" bullet
S" 14 Gb/s data rate @ 30fJ/bit" bullet
S" Thermally sensitive; requires precise heat-sinking" bullet
S" OTOH, temperature can be used to fine-tune optical frequencies!" bullet




slide S" MIT's Riscy Expedition" bullet

S" RV64IMAFD instruction set" bullet
S" Boots Linux" bullet
S" 6 aspects" bullet
2 left +!
  S" Formal specification" bullet
  S" Verified processors" bullet
  S" Memory Consistency Models" bullet
  S" Accelerators" bullet
  S" Microarchitecture exploration" bullet
  S" VLSI ASIC implementations w/ push-button synthesis" bullet
-2 left +!
S" Philosophy: (same as Kestrel's) Get it working, then make it faster/better." bullet
S" There is no separation of design and verification --- there's just verified design" bullet
S" Tandem Verification gives weak sense of correctness" bullet
S" Prefer formal verification" bullet
S" Example: are reference bits in page table entries to be set for speculative execution?" bullet
S" Example: A single instruction can result in up to 13 hits to memory.  How do they interact?" bullet
S" ARM, POWER-architecture has very weak memory models; you can't assume anything" bullet
S" WMM: A new weak consistency model" bullet


slide S" Pydgin: RPython-based Instruction Set Simulation" bullet
S" Interpretive Performance: 1-10MIPS (1-10 days)" bullet
S" Typical DBT: 100s of MIPS (1-3 hours)" bullet
S" QEMU DBT: 1000 MIPS (0.5 hours)" bullet
S" Instruction sets of new CPUs identical to interpeting Javascript, et. al." bullet
S" Use PyPy's RPython" bullet
S" Develop and debug in Python" bullet
S" Use RPython to build C executable equivalent" bullet
S" 0.1MIPS -> 10 MIPS (approximately)" bullet
S" Adding RPython JIT hints, 10 MIPS -> 100+ MIPS" bullet



slide S" ORCA: FPGA-Optimized RISC-V Soft Processors" bullet

S" Targets iCE40s: 3500 LUT4s, 4 16-bit multipliers, < $5.00 in Qty 1" bullet
S" RV32IM takes < 2000 LUTs, 22MHz" bullet
S" On Cyclone IV: 109MHz, 79 MIPS" bullet
S" On Stratix V: 244MHz, 212 MIPS" bullet
S" Configurable width: 32-bit, 64-bit, 128-bit" bullet
S" FPGA designs migrate to ASIC, but not usually the other way around" bullet



slide S" PULPino: Computing for the Internet of Things" title

S" Parallel Ultra-Low Power Processor" bullet
S" Multiple small clusters" bullet
S" Shared memory within a single cluster" bullet
S" Multiple clusters per chip" bullet
S" Custom ISA extensions" bullet
S" Why RISC-V over OpenRISC?" bullet
S" No flags." bullet
S" No delay slot." bullet
S" Compressed instructions now more or less standardized" bullet
S" Example custom ISA Extention" bullet
S"              lp.setupi       100, Lend" text 1 top +!
S"              ...                             \" text 1 top +!
S"              ...                             |-- executed 100 times." text 1 top +!
S"      Lend:   final_instr_here                /" text 1 top +!
S" 32 interrupt inputs" bullet



slide S" BOOM!  The Berkeley Out-of-Order Machine" title

S" Superscalar, out of order core" bullet
S" Synthesizable; Silicon-proven" bullet
S" And now, it's open source!  It's up on Github (somewhere)" bullet
S" Serve as baseline for academia, industry, etc." bullet
S" RISC-V can be fully implemented for R&D; ARM, x86 only subsets" bullet
S" Runs at 1.6GHz on 45nm process" bullet
S" BOOM extends Rocket, so as PRs land with Rocket Chip," bullet
S"   BOOM gets better automatically" text 1 top +!
S" 50MHz on FPGA, 1.6GHz on ASIC" bullet
S" BUT, design is optimized for ASIC, not FPGAs." bullet
S" Loads execute out of order from stores; however, stores forward to earlier pipeline stages" bullet
S" BOOM is about 2.5 times more power efficient than ARM." bullet
S"                 Pipeline" text 1 top +!
S"                 Depth       Issue       CoreMark/MHz    Power    Area" text 1 top +!
S" ARM V7            8          3+1           3.59          1.9W    2.5mm^2" text 1 top +!
S" RV64 BOOM         5           2            3.91          0.5W    1.0mm^2" text 1 top +!
1 top +!
S" https://github.com/ucb-bar/riscv-boom" bullet
S" https://github.com/ucb-bar/riscv-rocket" bullet



slide S" Fin." title

S" Thank you for listening to this report!" bullet

1 top +!
S" Remember, you can always contact me at:" bullet
2 left +!  1 top +!
  S" E-mail: kc5tja@arrl.net" text   1 top +!
  S"    Web: https://kestrelproject.github.io/kestrel" text

end done

out" slides.bin"
\ To make the final binary, do the following script:
\ 
\ $ gforth asm.fs sdimage.fs				( compile Milestone 2 executable )
\ $ gforth slide-asm.fs slides.fs			( compile slides )
\ $ dd if=slides.bin of=sd.bin bs=1024 count=4 seek=8	( embed slide data into binary image )
\ $ sudo cp sd.bin /dev/sdi				( write blocks to SD card )
\ $ sync						( verify Linux flushes buffers )
\ 
\ The iamge should then boot on any Kestrel with the Milestone-3 bootstrap image.

