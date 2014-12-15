/* vim: set noet sw=8 ts=8: */


#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>


typedef long long DWORD;

typedef struct InputSource InputSource;
typedef struct Word Word;
typedef struct Image Image;
typedef struct Label Label;
typedef struct Buffer Buffer;

typedef void (*Handler)(InputSource *, char *, Image *);


enum {
	KB		= 1024,

	INSN_JUMP	= 0x67,
	FN3_JALR	= 0,

	INSN_STORE	= 0x23,
	INSN_LOAD	= 0x03,
	FN3_SB		= 0,
	FN3_SD		= 3,

	INSN_OP_IMM	= 0x13,
	FN3_ADDI	= 0,

	REG_0		= 0,
	REG_RA		= 1,
	REG_SP		= 2,
	REG_KP		= 14,
	REG_T		= 16,
	REG_S		= 17,
	REG_GP		= 31,
};


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


struct Buffer {
	char * contents;
	long   point;
	long   size;
};


struct Image {
	Buffer code;
	Buffer rodata;
	long   base;
	Label *words;
	long   current_word_address;
};


struct Label {
	Label *next;
	char * name;
	long   address;
};


static int showListing = 0;


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


int buffer_init(Buffer *buf, int size) {
	buf->size = size;
	buf->contents = (char *)malloc(size);
	return buf->contents != NULL;
}


void buffer_free(Buffer *buf) {
	if(buf->contents) {
		free(buf->contents);
		buf->contents = NULL;
		buf->size = 0;
		buf->point = 0;
	}
}


void buffer_place_byte(Buffer *buf, char b) {
	long oldp = buf->point;
	assert(buf->point <= (buf->size - 1));

	if(showListing) printf("%02X ", b & 0xFF);

	buf->contents[buf->point] = b;
	buf->point++;

	assert(buf->point <= buf->size);
	assert(buf->point == (oldp + 1));
}


void buffer_place_hword(Buffer *buf, short w) {
	long oldp = buf->point;
	assert(buf->point <= (buf->size - 2));

	buffer_place_byte(buf, (w & 0xFF));
	buffer_place_byte(buf, ((w >> 8) & 0xFF));

	assert(buf->point <= buf->size);
	assert(buf->point == (oldp + 2));
}


void buffer_place_word(Buffer *buf, long w) {
	long oldp = buf->point;
	assert(buf->point <= (buf->size - 4));

	buffer_place_hword(buf, (w & 0xFFFF));
	buffer_place_hword(buf, ((w >> 16) & 0xFFFF));

	assert(buf->point <= buf->size);
	assert(buf->point == (oldp + 4));
}


void buffer_place_dword(Buffer *buf, DWORD w) {
	long oldp = buf->point;
	assert(buf->point <= (buf->size - 8));

	buffer_place_word(buf, (w & 0xFFFFFFFF));
	buffer_place_word(buf, ((w >> 32) & 0xFFFFFFFF));

	assert(buf->point <= buf->size);
	assert(buf->point == (oldp + 8));
}


long buffer_address(Buffer *buf) {
	return buf->point;
}


void image_dispose(Image *img) {
	Label *label;

	buffer_free(&img->code);
	buffer_free(&img->rodata);
	for(;;) {
		if(!img->words) break;
		label = img->words;
		img->words = label->next;
		free(label);
	}
	free(img);
}


Image *image_new(long codeSize, long dataSize) {
	Image *img = (Image *)malloc(sizeof(Image));
	if(img) {
		memset(img, 0, sizeof(Image));
		if(!buffer_init(&img->code, codeSize)) goto error;
		if(!buffer_init(&img->rodata, dataSize)) goto error;
	}
	return img;

error:
	image_dispose(img);
	return NULL;
}


void image_place_uj_insn(Image *img, long displacement, int xreg, int opcode) {
	int d20, d11, d10_1, d19_12, d;

	assert((-1048576 <= displacement) && (displacement <= 1048575));
	assert((displacement & 1) == 0);
	assert((0 <= xreg) && (xreg < 32));
	assert(opcode < 128);

	d20 = displacement & 0x100000;
	d11 = (displacement & 0x800) >> 11;
	d10_1 = (displacement & 0x7FE) >> 1;
	d19_12 = (displacement & 0xFF000) >> 12;
	d = (d20 << 20) | (d10_1 << 9) | (d11 << 8) | d19_12;
	buffer_place_word(&img->code, ((displacement & 0x1FFFFE) << 11) | ((xreg & 0x1F) << 7) | (opcode & 0x7F));
}


void image_place_s_insn(Image *img, int disp, int rs2, int rs1, int fn3, int opcode) {
	int disp4_0 = disp & 0x1F;
	int disp11_5 = disp >> 5;

	assert((-2048 <= disp) && (disp <= 2047));
	assert((0 <= rs2) && (rs2 <= 31));
	assert((0 <= rs1) && (rs1 <= 31));
	assert(fn3 < 8);
	assert(opcode < 128);

	buffer_place_word(&img->code, (disp11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (fn3 << 12) | (disp4_0 << 7) | (opcode & 0x7F));
}


void image_place_i_insn(Image *img, int immediate, int rs1, int fn3, int rd, int opcode) {
	assert((-2048 <= immediate) && (immediate <= 2047));
	assert((0 <= rs1) && (rs1 <= 31));
	assert((0 <= rd) && (rd <= 31));
	assert(fn3 < 8);
	assert(opcode < 128);

	buffer_place_word(&img->code, (immediate << 20) | (rs1 << 15) | (fn3 << 12) | (rd << 7) | (opcode & 0x7F));
}


long image_code_address(Image *img) {
	return buffer_address(&img->code);
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


void asm_jal(Image *img, int rd, int displacement) {
	image_place_uj_insn(img, displacement, rd, 0x6F);
	// Note: no +4 in effective address calculation here because point is already advanced by 4.
	if(showListing) printf("\tJAL \tX%d, %d ($%08lX)\n", rd, displacement, displacement + image_code_address(img));
}


void asm_jalr(Image *img, int rd, int rs1, int offset) {
	image_place_i_insn(img, offset, rs1, FN3_JALR, rd, INSN_JUMP);
	if(showListing) printf("\tJALR\tX%d, X%d, %d\n", rd, rs1, offset);
}


// We swap rs2 and rs1 from the normal assembly syntax to retain uniformity with LD and related insns.
void asm_sd(Image *img, int rs2, int rs1, int displacement) {
	image_place_s_insn(img, displacement, rs2, rs1, FN3_SD, INSN_STORE);
	if(showListing) printf("\tSD  \tX%d, X%d, %d\n", rs2, rs1, displacement);
}


void asm_sb(Image *img, int rs2, int rs1, int displacement) {
	image_place_s_insn(img, displacement, rs2, rs1, FN3_SB, INSN_STORE);
	if(showListing) printf("\tSB  \tX%d, X%d, %d\n", rs2, rs1, displacement);
}


void asm_addi(Image *img, int rd, int rs1, int immediate) {
	image_place_i_insn(img, immediate, rs1, FN3_ADDI, rd, INSN_OP_IMM);
	if(showListing) printf("\tADDI\tX%d, X%d, %d\n", rd, rs1, immediate);
}


void asm_ld(Image *img, int rd, int rs1, int offset) {
	image_place_i_insn(img, offset, rs1, FN3_SD, rd, INSN_LOAD);
	if(showListing) printf("\tLD  \tX%d, X%d, %d\n", rd, rs1, offset);
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


void create_word(InputSource *is, Image *img) {
	char *name;
	long address;
	Label *label;

	name = input_source_next_name(is);
	address = image_code_address(img);
	label = label_new(img->words, name, address);
	if(!label) {
		fprintf(stderr, "Critical: Unable to create label structure for %s\n", name);
		exit(1);
	}
	img->words = label;
	img->current_word_address = address;
	if(showListing) printf("\n\t%s: ($%08lX)\n", name, address);

	assert(img->words);
	assert(!strcmp(img->words->name, name));
	assert(img->words->address == address);
}


void doDefer(InputSource *is, char *_, Image *img) {
	create_word(is, img);
	asm_jal(img, 0, 0);
}


void doColon(InputSource *is, char *_, Image *img) {
	create_word(is, img);
	asm_sd(img, REG_RA, REG_KP, 0);
	asm_addi(img, REG_KP, REG_KP, -8);
}


void doExit(InputSource *is, char *_, Image *img) {
	asm_addi(img, REG_KP, REG_KP, 8);
	asm_ld(img, REG_RA, REG_KP, 0);
	asm_jalr(img, REG_0, REG_RA, 0);
}


void doCStore(InputSource *is, char *_, Image *img) {
	asm_ld(img, REG_S, REG_SP, 8);
	asm_sb(img, REG_T, REG_S, 0);
	asm_ld(img, REG_T, REG_SP, 16);
	asm_addi(img, REG_SP, REG_SP, 16);
}


void doBis(InputSource *is, char *_, Image *img) {
	// JAL's base address is NOT the JAL itself, but the subsequent instruction.
	// Hence the -4.
	long offset = img->current_word_address - image_code_address(img) - 4;
	// But, we skip over the word's preamble, so we don't overflow our stacks.
	asm_jal(img, 0, offset + 8);
}


Word dictionary[] = {
	{"\\", doLineComment},
	{":", doColon},
	{";", doExit},
	{"DEFER", doDefer},
	{"C!", doCStore},
	{"BIS", doBis},
	{"EXIT", doExit},
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


void compile_number(Image *img, DWORD value) {
	long offset;
	int oldShow = showListing;

	asm_sd(img, REG_T, REG_SP, 0);
	asm_addi(img, REG_SP, REG_SP, -8);

	if((-2048 <= value) && (value <= 2047)) {
		asm_addi(img, REG_T, 0, value);
	} else {
		showListing = 0;
		offset = buffer_address(&img->rodata);
		buffer_place_dword(&img->rodata, value);
		showListing = oldShow;
		asm_ld(img, REG_T, REG_GP, offset);
	}
}


int try_number(char *name, Image *img, DWORD *value) {
	if(('0' <= *name) && (*name <= '9')) {
		*value = strtoll(name, NULL, 10);
		return (errno == 0);
	} else if(*name == '$') {
		*value = strtoll(&name[1], NULL, 16);
		return (errno == 0);
	} else if(*name == '-') {
		try_number(&name[1], img, value);
		*value = -(*value);
		return (errno == 0);
	}
	return 0;
}


int main(int argc, char *argv[]) {
	int i;
	char *inputFilename = NULL, *name;
	InputSource *is;
	Handler handler;
	Image *img;
	DWORD value;

	printf("This is fc, the machine Forth compiler.\n");
	printf("Version 0.1.0\n");

	img = image_new(14*KB, 2*KB);
	if(!img) {
		fprintf(stderr, "Unable to allocate initial image.\n");
		exit(1);
	}

	i = 1;
	for(;;) {
		assert(i <= argc);
		if(i >= argc) break;

		assert(i < argc);
		if(!strcmp(argv[i], "list")) {
			showListing = 1;
			i++;
		} else if(!strcmp(argv[i], "from")) {
			if(i >= (argc - 1)) break;
			inputFilename = argv[i+1];
			i = i + 2;
		} else {
			fprintf(stderr, "WARNING: Unknown option %s\n", argv[i]);
			i++;
		}
		assert(i <= argc);
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
		} else if(try_number(name, img, &value)) {
			compile_number(img, value);
			continue;
		} else {
			fprintf(stderr, "Unknown word: %s ?\n", name);
			input_source_dispose(is);
			image_dispose(img);
			exit(1);
		}
	}

	input_source_dispose(is);
	image_dispose(img);
}

