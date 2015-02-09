/* vim: set noet ts=8 sw=8: */


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <termios.h>
#include <unistd.h>


static struct termios stored_settings;


enum {
	VERSION_MAJOR	= 0,
	VERSION_MINOR	= 1,
	VERSION_PATCH	= 0,

	MAX_PAGES	= 131072,
	PAGE_FIELD	= 8,
	PAGE_MASK	= MAX_PAGES-1,

	MB		= 1048576L,

	ROM_SIZE	= 16384,
	PHYS_RAM_SIZE	= 16*MB,
	PHYS_RAM_MASK	= PHYS_RAM_SIZE - 1,
	PHYS_ADDR_SIZE	= 32*MB,
};


typedef signed char		BYTE;
typedef signed short		HWORD;
typedef signed long		WORD;
typedef signed long long	DWORD;

typedef unsigned char		UBYTE;
typedef unsigned short		UHWORD;
typedef unsigned long		UWORD;
typedef unsigned long long	UDWORD;

typedef struct AddressSpace	AddressSpace;
typedef struct Options		Options;

typedef void (*WRFUNC)(AddressSpace *, UDWORD, BYTE);
typedef BYTE (*RDFUNC)(AddressSpace *, UDWORD);


struct AddressSpace {
	BYTE	*romImage;
	BYTE	*ram;
	WRFUNC	writers[MAX_PAGES];
	RDFUNC	readers[MAX_PAGES];
};


struct Options {
	char *	romFilename;
};


void console_1char_mode(void) {
	struct termios new_settings;

	tcgetattr(0, &stored_settings);
	new_settings = stored_settings;
	new_settings.c_lflag &= ~ICANON;
	new_settings.c_lflag &= ~ECHO;
	new_settings.c_cc[VTIME] = 0;
	new_settings.c_cc[VMIN] = 1;

	tcsetattr(0, TCSANOW, &new_settings);
}


void console_line_mode(void) {
	tcsetattr(0,TCSANOW,&stored_settings);
}


AddressSpace *address_space_new(void) {
	AddressSpace *as = (AddressSpace*)malloc(sizeof(AddressSpace));
	if(as) {
		memset(as, 0, sizeof(AddressSpace));
	}
	return as;
}


void address_space_ram_writer(AddressSpace *as, UDWORD addr, BYTE b) {
	assert(addr <= PHYS_ADDR_SIZE);
	as->ram[addr & PHYS_RAM_MASK] = b;
}


BYTE address_space_ram_reader(AddressSpace *as, UDWORD addr) {
	assert(addr <= PHYS_ADDR_SIZE);
	return as->ram[addr & PHYS_RAM_MASK];
}


void address_space_io_writer(AddressSpace *as, UDWORD addr, BYTE b) {
	switch(addr & 1) {
	case 0:		printf("%c", b); break;
	default:	break;
	}
}


BYTE address_space_io_reader(AddressSpace *as, UDWORD addr) {
	int n;
	BYTE c;

	switch(addr & 1) {
	case 0:		return 0;
	case 1:
		for(n = 0; !n; n = read(1, &c, 1));
		return c;
	}
	return 0;
}


AddressSpace *address_space_configure(Options *opts) {
	AddressSpace *as = address_space_new();
	FILE *romFile;
	int n, overflow;

	assert(opts);
	assert(opts->romFilename);

	as->romImage = (BYTE *)malloc(ROM_SIZE);
	memset(as->romImage, 0, ROM_SIZE);
	romFile = fopen(opts->romFilename, "rb");
	if(!romFile) {
		fprintf(stderr, "Cannot open ROM file %s\n", opts->romFilename);
		exit(1);
	}
	n = fread(as->romImage, 1, ROM_SIZE, romFile);
	if(n == ROM_SIZE) {
		n = fread(&overflow, 1, 1, romFile);
		if(n == 1) {
			fprintf(stderr, "ROM file is too big; should be %d bytes.\n", ROM_SIZE);
			fclose(romFile);
			exit(1);
		}
	}
	fclose(romFile);

	as->ram = (BYTE *)malloc(PHYS_RAM_SIZE);
	if(!as->ram) {
		fprintf(stderr, "Cannot allocate physical RAM for emulated computer.\n");
		exit(1);
	}

	for(n = 0; n < MAX_PAGES; n++) {
		as->writers[n] = address_space_ram_writer;
		as->readers[n] = address_space_ram_reader;
	}
	as->writers[0x0FFFF] = address_space_io_writer;
	as->readers[0x0FFFF] = address_space_io_reader;

	for(n = 0; n < MAX_PAGES; n++) {
		assert(as->writers[n]);
		assert(as->readers[n]);
	}
	assert(as->romImage);
	assert(as->ram);
	return as;
}

void address_space_store_byte(AddressSpace *as, DWORD address, BYTE datum) {
	int page = (address >> PAGE_FIELD) & PAGE_MASK;
	assert(as->writers);
	assert(as->writers[page]);
	as->writers[page](as, address, datum);
}


BYTE address_space_fetch_byte(AddressSpace *as, DWORD address) {
	int page = (address >> PAGE_FIELD) & PAGE_MASK;
	assert(as->readers);
	assert(as->readers[page]);
	return as->readers[page](as, address);
}


Options *options_new() {
	Options *opts = (Options *)malloc(sizeof(Options));
	if(opts) {
		memset(opts, 0, sizeof(Options));
	}
	return opts;
}


Options *options_get(int argc, char *argv[]) {
	Options *opts = options_new();
	int i = 1;

	for(;;) {
		if(i >= (argc - 1)) break;

		if(!strcmp(argv[i], "romfile")) {
			opts->romFilename = argv[i+1];
			i = i + 2;
		} else {
			fprintf(stderr, "Warning: unknown option %s\n", argv[i]);
			i++;
		}
	}

	return opts;
}


int run(int argc, char *argv[]) {
	Options *opts = NULL;
	AddressSpace *as = NULL;

	printf("This is e, the Polaris 64-bit RISC-V architecture emulator.\n");
	printf("Version %d.%d.%d.\n", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
	opts = options_get(argc, argv);
	as = address_space_configure(opts);

	do {
		char *msg = "Press any key to continue.\n";
		while(*msg) {
			address_space_store_byte(as, 0x0FFFF00, *msg);
			msg++;
		}
	} while(0);
	do {
		BYTE b = 0;
		while(!b) b = address_space_fetch_byte(as, 0x0FFFF01);
		printf("You typed: %d\n", b);
	} while(0);

	return 0;
}


int main(int argc, char *argv[]) {
	int result;

	console_1char_mode();
	result = run(argc, argv);
	console_line_mode();
	return result;
}

