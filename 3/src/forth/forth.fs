S" dictionary.fs" included
S" assembler.fs" included
S" compiler.fs" included

S" kernel.fs" included	\ eForth primitives
S" eforth.fs" included	\ eForth high-level words
S" sdcard.fs" included	\ SD card I/O driver
S" blockIO.fs" included	\ BLOCK, BUFFER, et. al.
S" vibe.fs" included	\ Screen editor

t: COLD		BEGIN U0 PRESET hi FORTH DEFINITIONS 0blocks 0editor MOUNT DROP QUIT AGAIN ;

\ __RESET__ is the RISC-V half of the cold bootstrap for
\ the Forth runtime environment.  It's responsible for
\ initializing the Forth virtual machine registers.  Once
\ initialized, it defers to __BOOT__ for higher-level
\ initialization tasks.
8 talign
tcode __RESET__
	0 x9 auipc,
	24 x9 ip ld,
	1024 x0 up addi,
	1024 up dsp addi,
	1024 dsp rsp addi,
	next,
	t' COLD t>h cell+ @ t,
tend-code

\ BYE terminates the current Forth session, and returns
\ the user to the host operating system.  However, since
\ we *are* the host operating system, BYE simply restarts
\ the environment as if the user had reset the computer.
t: BYE		__RESET__ ;

vectors
S" forth.rom" save
