#ifndef MAX_DEVS
#error "MAX_DEVS must be defined for this header; include config.h ahead of me."
#endif

#ifndef E_ADDRESS_SPACE_H
#define E_ADDRESS_SPACE_H

#include "sdcard.h"


typedef struct AddressSpace	AddressSpace;

typedef void (*WRFUNC)(AddressSpace *, UDWORD, UDWORD, int);
typedef UDWORD (*RDFUNC)(AddressSpace *, UDWORD, int);

struct AddressSpace {
	UBYTE	*rom;
	UBYTE	*ram;
	WRFUNC	writers[MAX_DEVS];
	RDFUNC	readers[MAX_DEVS];

	UDWORD	gpia_out;
	UDWORD	gpia_in;

	int	spi_prev_clk;
	int	spi_bit_ctr;
	SDCard *sdc;
	BYTE	spi_miso;
	BYTE	spi_mosi;
};


struct interface_AddressSpace {
	AddressSpace *(*make)(Options *opts);

	void (*store_byte)(AddressSpace *as, DWORD address, BYTE datum);
	void (*store_hword)(AddressSpace *as, DWORD address, UHWORD datum);
	void (*store_word)(AddressSpace *as, DWORD address, UWORD datum);
	void (*store_dword)(AddressSpace *as, DWORD address, UDWORD datum);
	UBYTE (*fetch_byte)(AddressSpace *as, DWORD address);
	UHWORD (*fetch_hword)(AddressSpace *as, DWORD address);
	UWORD (*fetch_word)(AddressSpace *as, DWORD address);
	UDWORD (*fetch_dword)(AddressSpace *as, DWORD address);
};

extern const struct interface_AddressSpace module_AddressSpace;

#endif

