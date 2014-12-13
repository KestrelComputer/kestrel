/* vim: set noet sw=8 ts=8: */


#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>


typedef struct InputSource InputSource;
typedef struct Word Word;
typedef struct Image Image;
typedef struct Label Label;

typedef void (*Handler)(InputSource *, char *, Image *);


struct InputSource {
	char *contents;
	long point;
	long size;
	char *filename;
};


struct Word {
	char *k;
	Handler v;
};


struct Image {
	char * contents;
	long   point;
	long   size;
	long   base;
	Label *words;
};


struct Label {
	Label *next;
	char * name;
	long   address;
};


long fsize(FILE *f) {
	long size;

	fseek(f, 0, SEEK_END);
	size = ftell(f);
	fseek(f, 0, SEEK_SET);
	return size;
}


void input_source_fetch(InputSource *is, char *filename) {
	FILE *f;
	long size;

	f = fopen(filename, "ra");
	if(!f) return;
	is->filename = filename;
	size = fsize(f);
	is->contents = (char *)malloc(size);
	is->size = fread(is->contents, 1, size, f);
	if(is->size != size) {
		fprintf(stderr, "Unable to read contents of %s; file truncated?\n", filename);
		fclose(f);
		free(is->contents);
		is->contents = NULL;
		return;
	}
	fclose(f);
}


InputSource *input_source_new(char *filename) {
	InputSource *is = (InputSource *)malloc(sizeof(InputSource));
	if(is) {
		memset(is, 0, sizeof(InputSource));
		input_source_fetch(is, filename);
		assert(is->filename);
		assert(is->contents);
		assert(is->point == 0);
		assert(is->size > 0);
	}
	return is;
}


void input_source_dispose(InputSource *is) {
	if(is->contents) free(is->contents);
	free(is);
}


int input_source_exhausted(InputSource *is) {
	return is->point >= is->size;
}


void input_source_skip_whitespace(InputSource *is) {
	assert(is->point <= is->size);
	while((is->point < is->size) && isspace(is->contents[is->point])) is->point++;
	assert(is->point <= is->size);
}


void input_source_skip_nonwhitespace(InputSource *is) {
	assert(is->point <= is->size);
	while((is->point < is->size) && !isspace(is->contents[is->point])) is->point++;
	assert(is->point <= is->size);
}


char *input_source_next_name(InputSource *is) {
	char *n;

	input_source_skip_whitespace(is);
	n = &is->contents[is->point];
	input_source_skip_nonwhitespace(is);
	is->contents[is->point] = 0;
	is->point++;
	return n;
}


void image_dispose(Image *img) {
	Label *label;

	if(img->contents) free(img->contents);
	for(;;) {
		if(!img->words) break;
		label = img->words;
		img->words = label->next;
		free(label);
	}
	free(img);
}


Image *image_new(long size) {
	Image *img = (Image *)malloc(sizeof(Image));
	if(img) {
		memset(img, 0, sizeof(Image));
		img->size = size;
		img->contents = (char *)malloc(size);
		if(!img->contents) {
			image_dispose(img);
			img = NULL;
		}
	}
	return img;
}


void image_place_byte(Image *img, char b) {
	long oldp = img->point;
	assert(img->point <= (img->size - 1));

	img->contents[img->point] = b;
	img->point++;

	assert(img->point <= img->size);
	assert(img->point == (oldp + 1));
}


void image_place_hword(Image *img, short w) {
	long oldp = img->point;
	assert(img->point <= (img->size - 2));

	image_place_byte(img, (w & 0xFF));
	image_place_byte(img, ((w >> 8) & 0xFF));

	assert(img->point <= img->size);
	assert(img->point == (oldp + 2));
}


void image_place_word(Image *img, long w) {
	long oldp = img->point;
	assert(img->point <= (img->size - 4));

	image_place_hword(img, (w & 0xFFFF));
	image_place_hword(img, ((w >> 16) & 0xFFFF));

	assert(img->point <= img->size);
	assert(img->point == (oldp + 4));
}


void image_place_uj_insn(Image *img, long displacement, int xreg, int opcode) {
	image_place_word(img, ((displacement & 0x1FFFFE) << 11) | ((xreg & 0x1F) << 7) | (opcode & 0x7F));
}


long image_address(Image *img) {
	return img->point + img->base;
}


Label *label_new(Label *next, char *name, long address) {
	Label *l = (Label *)malloc(sizeof(Label));
	if(l) {
		memset(l, 0, sizeof(Label));
		l->next = next;
		l->name = name;
		l->address = address;
	}
	return l;
}


void doLineComment(InputSource *is, char *_, Image *__) {
	for(;;) {
		if(is->point >= is->size) break;
		if(is->contents[is->point] != '\n') {
			is->point++;
			continue;
		} else {
			is->point++;	/* Skip the \n character. */
			break;
		}
	}
}


void doDefer(InputSource *is, char *_, Image *img) {
	long oldimgp = img->point;
	long oldisp = is->point;
	long address;
	char *name;
	Label *label;
	assert(img->point <= (img->size - 4));
	assert(is->point < img->size);

	name = input_source_next_name(is);
	address = image_address(img);
	label = label_new(img->words, name, address);
	if(!label) {
		fprintf(stderr, "Critical: Unable to create label structure for %s\n", name);
		exit(1);
	}
	img->words = label;

	image_place_uj_insn(img, 0, 0, 0x6F);	/* JAL X0,0 */

	assert(img->point <= img->size);
	assert(img->point == (oldimgp+4));
	assert(img->words);
	assert(!strcmp(img->words->name, name));
	assert(img->words->address == address);
	assert(is->point <= is->size);
	assert(is->point > oldisp);
}


Word dictionary[] = {
	{"\\", doLineComment},
	{"DEFER", doDefer},
	{NULL, NULL},
};


Handler handlers_find(char *name) {
	Word *w = &dictionary[0];
	for(;;) {
		if(!w->k) return NULL;
		if(!strcmp(w->k, name)) return w->v;
		w++;
	}
}


int main(int argc, char *argv[]) {
	int i;
	char *inputFilename = NULL, *name;
	InputSource *is;
	Handler handler;
	Image *img;


	printf("This is fc, the machine Forth compiler.\n");
	printf("Version 0.1.0\n");

	img = image_new(16384);
	if(!img) {
		fprintf(stderr, "Unable to allocate initial image.\n");
		exit(1);
	}

	i = 1;
	for(;;) {
		if(i >= (argc - 1)) break;

		if(!strcmp(argv[i], "from")) {
			inputFilename = argv[i+1];
			i = i + 2;
		} else {
			fprintf(stderr, "WARNING: Unknown option %s\n", argv[i]);
			i++;
		}
	}

	if(!inputFilename) {
		fprintf(stderr, "I need a source file to compile.\n");
		exit(1);
	}

	assert(inputFilename);

	is = input_source_new(inputFilename);
	if(!is) {
		fprintf(stderr, "Cannot open source file %s\n", inputFilename);
		exit(1);
	}

	for(;;) {
		if(input_source_exhausted(is)) break;

		name = input_source_next_name(is);
		assert(name);
		handler = handlers_find(name);
		if(handler) {
			handler(is, name, img);
			continue;
		} else {
			fprintf(stderr, "Unknown word: %s ?\n", name);
			input_source_dispose(is);
			exit(1);
		}
	}

	input_source_dispose(is);
	image_dispose(img);
}

