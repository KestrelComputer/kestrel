S" dictionary.fs" included
S" assembler.fs" included
S" compiler.fs" included

tcode halt
	0 0 jal,
tend-code

tcode !
	0 dsp x9 ld,
	8 dsp x10 ld,
	0 x9 x10 sd,
	16 dsp dsp addi,
	next,
tend-code

t: testIt $AAAAAAAA55555555 $FF0010 ! halt ;

8 talign
tcode __RESET__
	0 x9 auipc,
	24 x9 ip ld,
	0 x0 up addi,
	1024 up dsp addi,
	1024 up rsp addi,
	next,
	t' testIt t>h cell+ @ t,
tend-code

vectors

S" test.rom" save

