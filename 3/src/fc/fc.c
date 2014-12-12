/* vim: set noet sw=8 ts=8: */


#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef struct InputSource InputSource;
typedef struct Word Word;

typedef void (*Handler)(InputSource *, char *);


struct InputSource {
	char *filename;
	char *contents;
	long point;
	long size;
};


struct Word {
	char *k;
	Handler v;
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


Word dictionary[] = {
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

	printf("This is fc, the machine Forth compiler.\n");
	printf("Version 0.1.0\n");

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
			handler(is, name);
			continue;
		} else {
			fprintf(stderr, "Unknown word: %s ?\n", name);
			input_source_dispose(is);
			exit(1);
		}
	}

	input_source_dispose(is);
}

