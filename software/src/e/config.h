#define MAX_DEVS	16

#define VERSION_MAJOR	0
#define VERSION_MINOR	3
#define VERSION_PATCH	0

#define MB		1048576L

#define DEV_MASK	0x0F00000000000000
#define CARD_MASK	0xF000000000000000

#define ROM_SIZE	(1*MB)
#define ROM_MASK	(ROM_SIZE-1)
#define PHYS_RAM_SIZE	(16*MB)
#define PHYS_RAM_MASK	(PHYS_RAM_SIZE-1)
#define PHYS_ADDR_SIZE	(32*MB)
#define SDB_SIZE	(512)
#define SDB_MASK	(SDB_SIZE-1)

#define r_MISA		0xF10
#define r_MVENDORID	0xF11
#define r_MARCHID	0xF12
#define r_MIMPID	0xF13
#define r_MHARTID	0xF14

#define r_MSTATUS	0x300
#define r_MEDELEG	0x302
#define r_MIDELEG	0x303
#define r_MIE		0x304
#define r_MTVEC		0x305

#define r_MSCRATCH	0x340
#define r_MEPC		0x341
#define r_MCAUSE	0x342
#define r_MBADADDR	0x343
#define r_MIP		0x344

#define r_MTOHOST	0x780
#define r_MFROMHOST	0x781


#define i_MISA		0
#define i_MVENDORID	1
#define i_MARCHID	2
#define i_MIMPID	3
#define i_MHARTID	4
#define i_MSTATUS	5
#define i_MEDELEG	6
#define i_MIDELEG	7
#define i_MIE		8
#define i_MTVEC		9
#define i_MSCRATCH	10
#define i_MEPC		11
#define i_MCAUSE	12
#define i_MBADADDR	13
#define i_MIP		14
#define i_MTOHOST	15
#define i_MFROMHOST	16
#define i_MAXCSR	17
