#ifndef E_ADDRESS_SPACE_H
#define E_ADDRESS_SPACE_H


#include <stdint.h>


typedef struct AddressSpace	AddressSpace;
typedef struct IAddressSpace	IAddressSpace;


struct AddressSpace {
	IAddressSpace *i;
	// Append specializations here.
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


#endif

