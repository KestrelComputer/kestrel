\ Kestrel Forth V1.0
\ Copyright 2016 Samuel A. Falvo II
\ 
\ This Source Code Form is subject to the terms of the
\ Mozilla Public License, v. 2.0.  If a copy of the MPL
\ was not distributed with this file, You can obtain one
\ at https://mozilla.org/MPL/2.0/.
\ 
\ This file contains the eForth high-level words as
\ documented by Dr. C. H. Ting and Juergen Pintaske,
\ as of 2013-Apr-20. See
\ http://www.exemark.com/FORTH/eForthOverviewv5.pdf
\ 
\ NOTE: Some words are still implemented as assembly
\ language primitives, only because we have no choice
\ but to lay them down in memory *after* the their
\ high-level dependencies.  These exceptions are typically
\ related to IRQ and reset entry points.

t: ?DUP		DUP IF DUP THEN ;
t: ROT		>R SWAP R> SWAP ;
t: 2DROP	DROP DROP ;
t: 2DUP		OVER OVER ;
t: +		UM+ DROP ;
t: NOT		-1 XOR ;
t: INVERT	-1 XOR ;
t: NEGATE	-1 XOR 1 + ;
t: DNEGATE	NOT >R NOT 1 UM+ R> + ;
t: D+		>R SWAP >R UM+ R> R> + + ;
t: -		NEGATE + ;
t: ABS		DUP 0< IF NEGATE THEN ;

\ !io is responsible for initializing all the I/O devices
\ for Forth to run.  This includes clearing the keyboard
\ queue, initializing the video display hardware, etc.
t: !io		;

\ __BOOT__ is the Forth half of the cold bootstrap for the
\ Forth runtime environment.  The __RESET__ word handles
\ setting up the basic Forth virtual machine registers;
\ __BOOT__ handles everything else.
t: __BOOT__	!io PANIC ;

\ __RESET__ is the RISC-V half of the cold bootstrap for
\ the Forth runtime environment.  It's responsible for
\ initializing the Forth virtual machine registers.  Once
\ initialized, it defers to __BOOT__ for higher-level
\ initialization tasks.
8 talign
tcode __RESET__
	0 x9 auipc,
	24 x9 ip ld,
	0 x0 up addi,
	1024 up dsp addi,
	1024 dsp rsp addi,
	next,
	t' __BOOT__ t>h cell+ @ t,
tend-code

\ BYE terminates the current Forth session, and returns
\ the user to the host operating system.  However, since
\ we *are* the host operating system, BYE simply restarts
\ the environment as if the user had reset the computer.
t: BYE		__RESET__ ;

