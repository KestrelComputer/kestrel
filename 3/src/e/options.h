#ifndef E_OPTIONS_H
#define E_OPTIONS_H


typedef struct Options		Options;

struct Options {
	char *	romFilename;
	char *	sdbFilename;
	char *  sdcardFilename;
};


struct interface_Options {
	Options *(*make)(int argc, char *argv[]);
};

extern const struct interface_Options module_Options;

#endif
