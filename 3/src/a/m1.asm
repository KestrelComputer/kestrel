	auipc	31,0
B:	ld	31,31,iuart-B
	addi	30,0,65
loop:	sb	30,31,0
	jal	0,loop
iuart:	dword	$0F00000000000000

