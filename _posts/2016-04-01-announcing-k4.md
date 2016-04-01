---
layout: post
title:  "Announcing Kestrel-4"
date:   2016-04-01 18:22:00
---

Based on the recent and wild success of the Kestrel-3 home-brew computer project,
I am happy to announce my next project for the open computing masses.
Say hello to the <b>Kestrel-4</b>.

# Specifications

The Kestrel-4 will only slightly be more involved as home-brew projects are concerned.
In particular, it will require completely custom FPGA-based circuit boards
built around both Lattice iCE40K and Xilinx hardware.  But it won't stop there.

## I/O Capacity

* Support for 65536 I/O channels, *each* capable of over 1 Tbps throughput.
* Individual I/O channels can be bonded together to support higher throughputs.
* All I/O channels are backed by lowRISC cores, each with several minion cores dedicated to driving I/O.
* Intelligent routing of traffic works around bottlenecks without programmer or user intervention.
* Base unit will ship with 512 channels installed.

For those who desire the nostalgia of glass teletype screens,
3270-compatible block-mode terminals will be supported through a forth-coming control interface.

## Memory Capacity

* ccNUMA architecture with up to 128 independent banks of DDR4 SDRAM memory.
* RapidIO interconnects between all banks and processing elements.
* Each memory bank supports a 66-bit address space; maximum capacity 9.44 ZB of memory!

## Processing Capacity

* One PE card Pre-installed with 1024 RISC-V RV128-compatible processors.
* Support for up to 16 PE cards, allowing up to 65536 CPUs.
* All four modes supported: machine, hypervisor, supervisor, user.
* 16-cores per processor die, each sporting 8-way superscalar technology.
* 4GHz per processor for breakneck computational performance.
* 128K of L1 cache per core, 1MB of L2 cache, and 16MB of L3 Cache.

## Operating Systems

* Kestrel Forth V4.0 will introduce support for virtual partitions (VPARs), running Linux applications as Forth words.
* Licenses for 1-10 users, 10-100 users, 100+ users.
* Run trusted applications in a single address space for best performance, or in separate address spaces for maximum security.
* Now includes graphical configuration interface.
* Supports interactive and batch jobs.

# Intended Application Portfolio

The Kestrel-4 will target
financial, insurance, medical, nuclear reclaimation, weather prediction, enterprise file serving, enterprise web cache,
and Crysis applications.

