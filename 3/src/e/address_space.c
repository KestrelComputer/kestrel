#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <unistd.h>

#include "types.h"
#include "config.h"
#include "options.h"
#include "sdcard.h"
#include "gpia.h"
#include "address_space.h"


static void
no_writer(AddressSpace *as, UDWORD addr, UDWORD b, int sz) {
	fprintf(stderr, "Error: Writing $%016llX to address $%016llX\n", b, addr);
}


static UDWORD
no_reader(AddressSpace *as, UDWORD addr, int sz) {
	fprintf(stderr, "Error: Reading from address $%016llX; returning $CC\n", addr);
	return 0xCCCCCCCCCCCCCCCC;
}


static void
do_spi_interface(AddressSpace *as) {
	int spi_next_clk = as->gpia_out & GPIA_OUT_SD_CLK;

	sdcard_select(as->sdc);
	if(as->spi_bit_ctr == 0) as->spi_miso = sdcard_peek_byte(as->sdc);
	as->gpia_in = (as->gpia_in & ~GPIA_IN_SD_MISO) | ((as->spi_miso >> 5) & GPIA_IN_SD_MISO);

	if(!as->spi_prev_clk && spi_next_clk) {	/* Rising edge of clock */
		as->spi_mosi = (as->spi_mosi << 1) | ((as->gpia_out & GPIA_OUT_SD_MOSI) >> 2);
	}
	if(as->spi_prev_clk && !spi_next_clk) {	/* Falling edge of clock */
		as->spi_miso <<= 1;
		as->spi_bit_ctr = (as->spi_bit_ctr + 1) & 7;
		if(!as->spi_bit_ctr) {
			as->spi_miso = sdcard_byte(as->sdc, as->spi_mosi);
		}
	}
	as->spi_prev_clk = spi_next_clk;
}

static void
reset_spi_interface(AddressSpace *as) {
	as->spi_prev_clk = 0;
	as->spi_bit_ctr = 0;
	sdcard_deselect(as->sdc);
}


static void
do_gpia_out(AddressSpace *as) {
	int sdcard_selected = !(as->gpia_out & GPIA_OUT_SD_SS);

	if(sdcard_selected) do_spi_interface(as);
	else reset_spi_interface(as);
}

static UDWORD byteMasks[] = {
	0xFF,
	0xFFFF,
	0xFFFFFFFF,
	0xFFFFFFFFFFFFFFFF,
};

static void
gpia_writer(AddressSpace *as, UDWORD addr, UDWORD ud, int sz) {
	UDWORD byteMask;
	int shiftAmount = 8 * (addr & 7);

	/* Only GPIA Register 1 is an output register. */
	if((addr & 0x8) != 0x8) {
		return;
	}

	byteMask = byteMasks[sz] << shiftAmount;
	as->gpia_out = (as->gpia_out & ~byteMask) | ((ud << shiftAmount) & byteMask);
	do_gpia_out(as);
}

static UDWORD
gpia_reader(AddressSpace *as, UDWORD addr, int sz) {
	int shiftAmount = 8 * (addr & 7);
	UDWORD sources[9] = {
		as->gpia_in, 0, 0, 0,
		0, 0, 0, 0,
		as->gpia_out
	};

	return (sources[addr & 8] >> shiftAmount) & byteMasks[sz];
}


static void
uart_writer(AddressSpace *as, UDWORD addr, UDWORD b, int sz) {
	addr &= ~(DEV_MASK | CARD_MASK);
	switch(addr & 1) {
	case 0:		printf("%c", (BYTE)b); fflush(stdout); break;
	default:	break;
	}
}


static int
debug_port_has_data() {
	fd_set fds;
	struct timeval tv = {0,};
	FD_ZERO(&fds);
	FD_SET(0, &fds);
	select(1, &fds, NULL, NULL, &tv);
	return FD_ISSET(0, &fds) != 0;
}

static UDWORD
uart_reader(AddressSpace *as, UDWORD addr, int sz) {
	int n;
	BYTE c;

	addr &= ~(DEV_MASK | CARD_MASK);
	switch(addr & 1) {
	case 0:		return debug_port_has_data();
	case 1:
		for(n = 0; !n; n = read(1, &c, 1));
		return c;
	}
	return 0;
}


#define ROMF(a) (UDWORD)(as->rom[(a) & ROM_MASK])
static UDWORD
rom_reader(AddressSpace *as, UDWORD addr, int sz) {
	addr |= DEV_MASK | CARD_MASK;
	if((addr | ROM_MASK) != -1) {
		fprintf(stderr, "Warning: reading mirrored ROM at $%016llX\n", addr);
	}
	switch(sz) {
	case 0:
		return ROMF(addr);

	case 1:
		return (ROMF(addr)
			| (ROMF(addr+1) << 8));

	case 2:
		return (ROMF(addr)
			| (ROMF(addr+1) << 8)
			| (ROMF(addr+2) << 16)
			| (ROMF(addr+3) << 24));

	case 3:
		return (ROMF(addr)
			| (ROMF(addr+1) << 8)
			| (ROMF(addr+2) << 16)
			| (ROMF(addr+3) << 24)
			| (ROMF(addr+4) << 32)
			| (ROMF(addr+5) << 40)
			| (ROMF(addr+6) << 48)
			| (ROMF(addr+7) << 56));
	}
	fprintf(stderr, "Read of unknown size at address $%016llX\n", addr);
	return 0xDDDDDDDD;
}

static void
ram_writer(AddressSpace *as, UDWORD addr, UDWORD b, int sz) {
	addr &= ~(DEV_MASK | CARD_MASK);
	if(addr > PHYS_RAM_MASK) {
		fprintf(stderr, "Warning: writing $%016llX to mirrored RAM at $%016llX, size code %d\n", b, addr, sz);
	}
	switch(sz) {
	case 0:
		as->ram[addr & PHYS_RAM_MASK] = b;
		break;

	case 1:
		as->ram[addr & PHYS_RAM_MASK] = b;
		as->ram[(addr+1) & PHYS_RAM_MASK] = b >> 8;
		break;

	case 2:
		as->ram[addr & PHYS_RAM_MASK] = b;
		as->ram[(addr+1) & PHYS_RAM_MASK] = b >> 8;
		as->ram[(addr+2) & PHYS_RAM_MASK] = b >> 16;
		as->ram[(addr+3) & PHYS_RAM_MASK] = b >> 24;
		break;

	case 3:
		as->ram[addr & PHYS_RAM_MASK] = b;
		as->ram[(addr+1) & PHYS_RAM_MASK] = b >> 8;
		as->ram[(addr+2) & PHYS_RAM_MASK] = b >> 16;
		as->ram[(addr+3) & PHYS_RAM_MASK] = b >> 24;
		as->ram[(addr+4) & PHYS_RAM_MASK] = b >> 32;
		as->ram[(addr+5) & PHYS_RAM_MASK] = b >> 40;
		as->ram[(addr+6) & PHYS_RAM_MASK] = b >> 48;
		as->ram[(addr+7) & PHYS_RAM_MASK] = b >> 56;
		break;
	}
}


#define RAMF(a) (UDWORD)(as->ram[(a) & PHYS_RAM_MASK])
static UDWORD
ram_reader(AddressSpace *as, UDWORD addr, int sz) {
	addr &= ~(DEV_MASK | CARD_MASK);
	if(addr > PHYS_RAM_MASK) {
		fprintf(stderr, "Warning: reading mirrored RAM at $%016llX\n", addr);
	}
	switch(sz) {
	case 0:
		return RAMF(addr);

	case 1:
		return (RAMF(addr)
			| (RAMF(addr+1) << 8));

	case 2:
		return (RAMF(addr)
			| (RAMF(addr+1) << 8)
			| (RAMF(addr+2) << 16)
			| (RAMF(addr+3) << 24));

	case 3:
		return (RAMF(addr)
			| (RAMF(addr+1) << 8)
			| (RAMF(addr+2) << 16)
			| (RAMF(addr+3) << 24)
			| (RAMF(addr+4) << 32)
			| (RAMF(addr+5) << 40)
			| (RAMF(addr+6) << 48)
			| (RAMF(addr+7) << 56));
	}
	fprintf(stderr, "Read of unknown size at address $%016llX\n", addr);
	return 0xDDDDDDDD;
}


static
AddressSpace *
_new(void) {
	AddressSpace *as = (AddressSpace*)malloc(sizeof(AddressSpace));
	if(as) {
		memset(as, 0, sizeof(AddressSpace));
	}
	return as;
}


static
AddressSpace *
make(Options *opts) {
	AddressSpace *as = _new();
	FILE *romFile;
	int n, overflow;

	assert(opts);
	assert(opts->romFilename);

	as->rom = (UBYTE *)malloc(ROM_SIZE);
	memset(as->rom, 0, ROM_SIZE);
	romFile = fopen(opts->romFilename, "rb");
	if(!romFile) {
		fprintf(stderr, "Cannot open ROM file %s\n", opts->romFilename);
		exit(1);
	}
	n = fread(as->rom, 1, ROM_SIZE, romFile);
	if(n == ROM_SIZE) {
		n = fread(&overflow, 1, 1, romFile);
		if(n == 1) {
			fprintf(stderr, "ROM file is too big; should be %ld bytes.\n", ROM_SIZE);
			fclose(romFile);
			exit(1);
		}
	}
	fclose(romFile);

	as->ram = (UBYTE *)malloc(PHYS_RAM_SIZE);
	if(!as->ram) {
		fprintf(stderr, "Cannot allocate physical RAM for emulated computer.\n");
		exit(1);
	}

	for(n = 0; n < MAX_DEVS; n++) {
		as->writers[n] = no_writer;
		as->readers[n] = no_reader;
	}
	as->readers[15] = rom_reader;
	as->writers[0] = ram_writer;
	as->readers[0] = ram_reader;
	as->writers[1] = gpia_writer;
	as->readers[1] = gpia_reader;
	as->writers[14] = uart_writer;
	as->readers[14] = uart_reader;

	for(n = 0; n < MAX_DEVS; n++) {
		assert(as->writers[n]);
		assert(as->readers[n]);
	}
	assert(as->rom);
	assert(as->ram);

	as->sdc = sdcard_new();
	assert(as->sdc);
	return as;
}


static int
valid_card(DWORD address) {
	int card = (address & CARD_MASK) >> 60;
	int element = 1 << card;
	return (element & 0x8003) != 0;		// Cards 0, 1, and 15 are valid.
}

static void
store_byte(AddressSpace *as, DWORD address, BYTE datum) {
	int dev = (address & DEV_MASK) >> 56;
	if(!valid_card(address)) {
		fprintf(stderr, "Warning: attempt to write to %016llX.\n", address);
		return;
	}
	assert(as->writers);
	assert(as->writers[dev]);
	as->writers[dev](as, address, datum, 0);
}


static void
store_hword(AddressSpace *as, DWORD address, UHWORD datum) {
	int dev = (address & DEV_MASK) >> 56;
	if(!valid_card(address)) {
		fprintf(stderr, "Warning: attempt to write to %016llX.\n", address);
		return;
	}
	assert(as->writers);
	assert(as->writers[dev]);
	as->writers[dev](as, address, datum, 1);
}


static void
store_word(AddressSpace *as, DWORD address, UWORD datum) {
	int dev = (address & DEV_MASK) >> 56;
	if(!valid_card(address)) {
		fprintf(stderr, "Warning: attempt to write to %016llX.\n", address);
		return;
	}
	assert(as->writers);
	assert(as->writers[dev]);
	as->writers[dev](as, address, datum, 2);
}


static void
store_dword(AddressSpace *as, DWORD address, UDWORD datum) {
	int dev = (address & DEV_MASK) >> 56;
	if(!valid_card(address)) {
		fprintf(stderr, "Warning: attempt to write to %016llX.\n", address);
		return;
	}
	assert(as->writers);
	assert(as->writers[dev]);
	as->writers[dev](as, address, datum, 3);
}


static BYTE
fetch_byte(AddressSpace *as, DWORD address) {
	int dev = (address & DEV_MASK) >> 56;
	if(!valid_card(address)) {
		fprintf(stderr, "Warning: attempt to read from %016llX; returning 0xCC\n", address);
		return 0xCC;
	}
	assert(as->readers);
	assert(as->readers[dev]);
	return as->readers[dev](as, address, 0);
}


static HWORD
fetch_hword(AddressSpace *as, DWORD address) {
	int dev = (address & DEV_MASK) >> 56;
	if(!valid_card(address)) {
		fprintf(stderr, "Warning: attempt to read from %016llX; returning 0xCCCC\n", address);
		return 0xCCCC;
	}
	assert(as->readers);
	assert(as->readers[dev]);
	return as->readers[dev](as, address, 1);
}


static WORD
fetch_word(AddressSpace *as, DWORD address) {
	int dev = (address & DEV_MASK) >> 56;
	if(!valid_card(address)) {
		fprintf(stderr, "Warning: attempt to read from %016llX; returning 0xCCCCCCCC\n", address);
		return 0xCCCCCCCC;
	}
	assert(as->readers);
	assert(as->readers[dev]);
	return as->readers[dev](as, address, 2);
}


static DWORD
fetch_dword(AddressSpace *as, DWORD address) {
	int dev = (address & DEV_MASK) >> 56;
	if(!valid_card(address)) {
		fprintf(stderr, "Warning: attempt to read from %016llX; returning 0xCCCCCCCCCCCCCCCC\n", address);
		return 0xCCCCCCCCCCCCCCCC;
	}
	assert(as->readers);
	assert(as->readers[dev]);
	return as->readers[dev](as, address, 3);
}


const struct interface_AddressSpace module_AddressSpace = {
	.make		= &make,

	.store_byte	= &store_byte,
	.store_hword	= &store_hword,
	.store_word	= &store_word,
	.store_dword	= &store_dword,

	.fetch_byte	= &fetch_byte,
	.fetch_hword	= &fetch_hword,
	.fetch_word	= &fetch_word,
	.fetch_dword	= &fetch_dword,
};

