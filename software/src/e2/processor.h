#ifndef E_PROCESSOR_H
#define E_PROCESSOR_H

#include <stdint.h>


/*
 * The Main Interface.
 *
 * To emulate a system built around a KCP53000-compatible processor, you must
 * have one processor and one address space in which it runs.  
 */

typedef struct Processor	Processor;
typedef struct AddressSpace	AddressSpace;
typedef struct IAddressSpace	IAddressSpace;

struct Processor {
	// VM state/pseudo-CSRs

	uint64_t	vmcause;
	uint64_t	ia;
	AddressSpace *	as;

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


struct AddressSpace {
	IAddressSpace *i;
	/* Append virtual resources here */
};


struct IAddressSpace {
	void (*store_byte)(AddressSpace *as, uint64_t address, uint8_t datum);
	void (*store_hword)(AddressSpace *as, uint64_t address, uint16_t datum);
	void (*store_word)(AddressSpace *as, uint64_t address, uint32_t datum);
	void (*store_dword)(AddressSpace *as, uint64_t address, uint64_t datum);
	uint8_t (*fetch_byte)(AddressSpace *as, uint64_t address);
	uint16_t (*fetch_hword)(AddressSpace *as, uint64_t address);
	uint32_t (*fetch_word)(AddressSpace *as, uint64_t address);
	uint64_t (*fetch_dword)(AddressSpace *as, uint64_t address);
};


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
	MSTATUSB_HIE,		/* reserved */
	MSTATUSB_MIE,
	MSTATUSB_UPIE,
	MSTATUSB_SPIE,
	MSTATUSB_HPIE,		/* reserved */
	MSTATUSB_MPIE,
	MSTATUSB_SPP,
	MSTATUSB_HPP0,		/* reserved */
	MSTATUSB_HPP1,		/* reserved */
	MSTATUSB_MPP0,
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
#define MSTATUSF_HPP0 (1ULL << MSTATUSB_HPP0)
#define MSTATUSF_HPP1 (1ULL << MSTATUSB_HPP1)
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

#define MCAUSEF_IRQ	(0x8000000000000000ULL)

typedef enum {
	MIEB_USIE = 0,
	MIEB_SSIE,
	MIEB_HSIE,
	MIEB_MSIE,
	MIEB_UTIE,
	MIEB_STIE,
	MIEB_HTIE,
	MIEB_MTIE,
	MIEB_UEIE,
	MIEB_SEIE,
	MIEB_HEIE,
	MIEB_MEIE,
} mie_bit_t;

#define MIEF_USIE	(1ULL << MIEB_USIE)
#define MIEF_SSIE	(1ULL << MIEB_SSIE)
#define MIEF_HSIE	(1ULL << MIEB_HSIE)
#define MIEF_MSIE	(1ULL << MIEB_MSIE)
#define MIEF_UTIE	(1ULL << MIEB_UTIE)
#define MIEF_STIE	(1ULL << MIEB_STIE)
#define MIEF_HTIE	(1ULL << MIEB_HTIE)
#define MIEF_MTIE	(1ULL << MIEB_MTIE)
#define MIEF_UEIE	(1ULL << MIEB_UEIE)
#define MIEF_SEIE	(1ULL << MIEB_SEIE)
#define MIEF_HEIE	(1ULL << MIEB_HEIE)
#define MIEF_MEIE	(1ULL << MIEB_MEIE)

typedef enum {
	EXCB_MISALIGNED_INST_ADDR = 0,
	EXCB_INST_ACCESS_FAULT,
	EXCB_ILLEGAL_INST,
	EXCB_BREAKPOINT,
	EXCB_MISALIGNED_LOAD_ADDR,
	EXCB_LOAD_ACCESS_FAULT,
	EXCB_MISALIGNED_STORE_ADDR,
	EXCB_STORE_ACCESS_FAULT,
	EXCB_ECALL_FROM_UMODE,
	EXCB_ECALL_FROM_SMODE,
	EXCB_reserved1,
	EXCB_ECALL_FROM_MMODE,
	EXCB_INST_PAGE_FAULT,
	EXCB_LOAD_PAGE_FAULT,
	EXCB_reserved2,
	EXCB_STORE_PAGE_FAULT,
} exception_bit_t;

#define EXCB_MISALIGNED_AMO_ADDR	(EXCB_MISALIGNED_STORE_ADDR)
#define	EXCB_AMO_PAGE_FAULT		(EXCB_STORE_PAGE_FAULT)

#define EXCF_MISALIGNED_INST_ADDR   	(1ULL << EXCB_MISALIGNED_INST_ADDR)
#define EXCF_INST_ACCESS_FAULT      	(1ULL << EXCB_INST_ACCESS_FAULT)
#define EXCF_ILLEGAL_INST           	(1ULL << EXCB_ILLEGAL_INST)
#define EXCF_BREAKPOINT             	(1ULL << EXCB_BREAKPOINT)
#define EXCF_MISALIGNED_LOAD_ADDR   	(1ULL << EXCB_MISALIGNED_LOAD_ADDR)
#define EXCF_LOAD_ACCESS_FAULT      	(1ULL << EXCB_LOAD_ACCESS_FAULT)
#define EXCF_MISALIGNED_STORE_ADDR  	(1ULL << EXCB_MISALIGNED_STORE_ADDR)
#define EXCF_STORE_ACCESS_FAULT     	(1ULL << EXCB_STORE_ACCESS_FAULT)
#define EXCF_ECALL_FROM_UMODE       	(1ULL << EXCB_ECALL_FROM_UMODE)
#define EXCF_ECALL_FROM_SMODE       	(1ULL << EXCB_ECALL_FROM_SMODE)
#define EXCF_reserved1              	(1ULL << EXCB_reserved1)
#define EXCF_ECALL_FROM_MMODE       	(1ULL << EXCB_ECALL_FROM_MMODE)
#define EXCF_INST_PAGE_FAULT        	(1ULL << EXCB_INST_PAGE_FAULT)
#define EXCF_LOAD_PAGE_FAULT        	(1ULL << EXCB_LOAD_PAGE_FAULT)
#define EXCF_reserved2              	(1ULL << EXCB_reserved2)
#define EXCF_STORE_PAGE_FAULT		(1ULL << EXCB_STORE_PAGE_FAULT)


Processor *new_processor(AddressSpace *);
void step(Processor *);

#endif

