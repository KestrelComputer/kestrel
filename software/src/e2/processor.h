#ifndef E_PROCESSOR_H
#define E_PROCESSOR_H

#include <stdint.h>


typedef struct Processor	Processor;

typedef enum {
	CSR_MVENDORID = 0xF11,
	CSR_MARCHID = 0xF12,
	CSR_MIMPID = 0xF13,
	CSR_MHARTID = 0xF14,

	CSR_MSTATUS = 0x300,
	CSR_MISA = 0x301,
	CSR_MEDELEG = 0x302,
	CSR_MIDELEG = 0x303,
	CSR_MIE = 0x304,
	CSR_MTVEC = 0x305,
	CSR_MCOUNTEREN = 0x306,

	CSR_MSCRATCH = 0x340,
	CSR_MEPC = 0x341,
	CSR_MCAUSE = 0x342,
	CSR_MTVAL = 0x343,
	CSR_MIP = 0x344,

	CSR_MCYCLE = 0xB00,
	CSR_MINSTRET = 0xB01,
} csr_t;

typedef enum {
	MSTATUSB_UIE = 0,
	MSTATUSB_SIE,
	MSTATUSB_HIE,		// reserved
	MSTATUSB_MIE,
	MSTATUSB_UPIE,
	MSTATUSB_SPIE,
	MSTATUSB_HPIE,		// reserved
	MSTATUSB_MPIE,
	MSTATUSB_SPP,
	MSTATUSB_MPP0 = 11,
	MSTATUSB_MPP1,

	MSTATUSB_FS0,
	MSTATUSB_FS1,
	MSTATUSB_XS0,
	MSTATUSB_XS1,

	MSTATUSB_MPRV,
	MSTATUSB_SUM,
	MSTATUSB_MXR,
	MSTATUSB_TVM,
	MSTATUSB_TW,
	MSTATUSB_TSR,
	MSTATUSB_UXL0 = 32,
	MSTATUSB_UXL1,
	MSTATUSB_SXL0,
	MSTATUSB_SXL1,
	MSTATUSB_SD = 63
} mstatus_bit_t;

#define MSTATUSF_UIE  (1ULL << MSTATUSB_UIE )
#define MSTATUSF_SIE  (1ULL << MSTATUSB_SIE )
#define MSTATUSF_HIE  (1ULL << MSTATUSB_HIE )
#define MSTATUSF_MIE  (1ULL << MSTATUSB_MIE )
#define MSTATUSF_UPIE (1ULL << MSTATUSB_UPIE)
#define MSTATUSF_SPIE (1ULL << MSTATUSB_SPIE)
#define MSTATUSF_HPIE (1ULL << MSTATUSB_HPIE)
#define MSTATUSF_MPIE (1ULL << MSTATUSB_MPIE)
#define MSTATUSF_SPP  (1ULL << MSTATUSB_SPP )
#define MSTATUSF_MPP0 (1ULL << MSTATUSB_MPP0)
#define MSTATUSF_MPP1 (1ULL << MSTATUSB_MPP1)
#define MSTATUSF_FS0  (1ULL << MSTATUSB_FS0 )
#define MSTATUSF_FS1  (1ULL << MSTATUSB_FS1 )
#define MSTATUSF_XS0  (1ULL << MSTATUSB_XS0 )
#define MSTATUSF_XS1  (1ULL << MSTATUSB_XS1 )
#define MSTATUSF_MPRV (1ULL << MSTATUSB_MPRV)
#define MSTATUSF_SUM  (1ULL << MSTATUSB_SUM )
#define MSTATUSF_MXR  (1ULL << MSTATUSB_MXR )
#define MSTATUSF_TVM  (1ULL << MSTATUSB_TVM )
#define MSTATUSF_TW   (1ULL << MSTATUSB_TW  )
#define MSTATUSF_TSR  (1ULL << MSTATUSB_TSR )
#define MSTATUSF_UXL0 (1ULL << MSTATUSB_UXL0)
#define MSTATUSF_UXL1 (1ULL << MSTATUSB_UXL1)
#define MSTATUSF_SXL0 (1ULL << MSTATUSB_SXL0)
#define MSTATUSF_SXL1 (1ULL << MSTATUSB_SXL1)
#define MSTATUSF_SD   (1ULL << MSTATUSB_SD  )


struct Processor {
	// VM state/pseudo-CSRs

	uint64_t	vmcause;

	// M-mode CSRs

	uint64_t	mvendorid;
	uint64_t	marchid;
	uint64_t	mimpid;
	uint64_t	mhartid;
	uint64_t	mstatus;
	uint64_t	misa;
	uint64_t	medeleg;
	uint64_t	mideleg;
	uint64_t	mie;
	uint64_t	mtvec;
	uint64_t	mcounteren;
	uint64_t	mscratch;
	uint64_t	mepc;
	uint64_t	mcause;
	uint64_t	mtval;
	uint64_t	mip;
	uint64_t	mcycle;
	uint64_t	minstret;

	// U-mode state

	uint64_t	x[32];
	uint64_t	pc;
};


#endif

