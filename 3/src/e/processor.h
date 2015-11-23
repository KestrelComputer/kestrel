#ifndef E_PROCESSOR_H
#define E_PROCESSOR_H

typedef struct Processor	Processor;

struct Processor {
	UDWORD       csr[i_MAXCSR];
	UDWORD       x[32];
	UDWORD       pc;
	AddressSpace *as;
	int          running;
	int          rc;
};


struct interface_Processor {
	Processor *(*make)(AddressSpace *as);
	void (*step)(Processor *, Timeline *);
};

extern const struct interface_Processor module_Processor;

#endif

