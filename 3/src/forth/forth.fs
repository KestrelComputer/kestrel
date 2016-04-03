S" dictionary.fs" included
S" assembler.fs" included

tcode (next)
	0 ip w ld,
	8 ip ip addi,
	0 w x9 ld,
	0 x9 x0 jalr,
tend-code

: next,		S" (next)" tfind drop @ there - x0 jal, ;

8 talign
tcode pushFF0000
	0 x9 auipc,
	24 x9 x8 ld,
	-8 dsp dsp addi,
	0 dsp x8 sd,
	next,
	0 0 0 addi,
	$FF0000 t,
tend-code

tcode pushAA55
	-8 dsp dsp addi,
	$AA x0 x9 addi,
	8 x9 x9 slli,
	$55 x9 x9 ori,
	0 dsp x9 sd,
	next,
tend-code

tcode halt
	0 0 jal,
tend-code

tcode sto
	0 dsp x9 ld,
	8 dsp x10 ld,
	0 x9 x10 sd,
	16 dsp dsp addi,
	next,
tend-code

8 talign
tcode testIt
	t' pushAA55 t,
	t' pushFF0000 t,
	t' sto t,
	t' halt t,
tend-code

8 talign
tcode __RESET__
	0 x9 auipc,
	24 x9 ip ld,
	0 x0 up addi,
	1024 up dsp addi,
	1024 up rsp addi,
	next,
	t' testIt t>h @ t,
tend-code

vectors

S" test.rom" save

