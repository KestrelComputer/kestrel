#define MAX_DEVS	16

#define VERSION_MAJOR	0
#define VERSION_MINOR	2
#define VERSION_PATCH	2

#define MB		1048576L

#define DEV_MASK	0x0F00000000000000
#define CARD_MASK	0xF000000000000000

#define ROM_SIZE	(1*MB)
#define ROM_MASK	(ROM_SIZE-1)
#define PHYS_RAM_SIZE	(16*MB)
#define PHYS_RAM_MASK	(PHYS_RAM_SIZE-1)
#define PHYS_ADDR_SIZE	(32*MB)

#define r_MCPUID	0xF00
#define r_MIMPID	0xF01
#define r_MHARTID	0xF10
#define r_MSTATUS	0x300
#define r_MTVEC		0x301
#define r_MDELEG	0x302
#define r_MEPC		0x341
#define r_MBADADDR	0x343
#define r_MCAUSE	0x342
#define r_MTOHOST	0x780
#define r_MFROMHOST	0x781


#define i_MCPUID	0
#define i_MIMPID	1
#define i_MHARTID	2
#define i_MSTATUS	3
#define i_MTVEC		4
#define i_MDELEG	5
#define i_MEPC		6
#define i_MBADADDR	7
#define i_MCAUSE	8
#define i_MTOHOST	9
#define i_MFROMHOST	10
#define i_MAXCSR	11
