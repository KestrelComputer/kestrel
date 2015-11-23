/* vim: set noet ts=8 sw=8: */


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <termios.h>
#include <unistd.h>

#include <SDL.h>

#include "types.h"
#include "config.h"
#include "options.h"
#include "address_space.h"
#include "timeline.h"
#include "processor.h"

extern const struct interface_AddressSpace module_AddressSpace;
static const struct interface_AddressSpace *as = &module_AddressSpace;

extern const struct interface_Processor module_Processor;
static const struct interface_Processor *pp = &module_Processor;

extern const struct interface_Options module_Options;
static const struct interface_Options *oo = &module_Options;

extern const struct interface_Timeline module_Timeline;
static const struct interface_Timeline *tt = &module_Timeline;

static struct termios stored_settings;

struct MGIA {
	SDL_Window *win;
	SDL_Renderer *ren;
	SDL_Texture *tex;
	Uint32 *pix;
	int scanline;
	AddressSpace *fb;
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



void destroyMGIA(struct MGIA *m) {
	if(!m) return;
	if(m->pix)	free(m->pix);
	if(m->tex)	SDL_DestroyTexture(m->tex);
	if(m->ren)	SDL_DestroyRenderer(m->ren);
	if(m->win)	SDL_DestroyWindow(m->win);
	free(m);
}


struct MGIA *makeMGIA(char *title, AddressSpace *fb) {
	struct MGIA *m;

	m = (struct MGIA *)(malloc(sizeof(struct MGIA)));
	if(m) {
		memset(m, 0, sizeof(struct MGIA));

		m->win = SDL_CreateWindow(
			title,
			SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
			640, 480, 0
		);
		if(!m->win) goto out;
		m->ren = SDL_CreateRenderer(m->win, -1, 0);
		if(!m->ren) goto out;
		m->tex = SDL_CreateTexture(
			m->ren,
			SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
			640, 480
		);
		if(!m->tex) goto out;
		SDL_SetTextureBlendMode(m->tex, SDL_BLENDMODE_NONE);
		m->pix = (Uint32 *)(malloc(640 * 480 * sizeof(Uint32)));
		if(!m->pix) goto out;
		m->fb = fb;
	}
	return m;

out:	destroyMGIA(m);
	return NULL;
}


void do_crt_frame(Timeline *t, void *pcrt) {
	struct MGIA *crt = (struct MGIA *)pcrt;
	DWORD fbaddr = 0xFF0000;
	Uint32 *pixadr, *p;
	int pitch;
	HWORD h, i, j;

	SDL_LockTexture(
		crt->tex, NULL,
		(void **)&pixadr, &pitch
	);
	for(crt->scanline = 0; crt->scanline < 480; crt->scanline++) {
		p = pixadr;
		for(i = 0; i < 40; i++) {
			h = as->fetch_hword(crt->fb, fbaddr);
			h = ((h >> 8) & 0xFF) | ((h & 0xFF) << 8);
			fbaddr += 2;
			for(j = 0; j < 16; j++) {
				*p++ = (h & 0x8000) ? 0xFFFFFFFF : 0;
				h <<= 1;
			}
		}
		pixadr = (Uint32 *)(((char *)pixadr) + pitch);
	}
	SDL_UnlockTexture(crt->tex);
	SDL_RenderClear(crt->ren);
	SDL_RenderCopy(crt->ren, crt->tex, NULL, NULL);
	SDL_RenderPresent(crt->ren);

	crt->scanline++;
	if(crt->scanline >= 480) crt->scanline = 0;

	tt->schedule(t, &do_crt_frame, 525*400, pcrt);
}

int run(int argc, char *argv[]) {
	Processor *p = NULL;
	Timeline *t;
	int running = 1;
	SDL_Event sdlEvent;
	struct MGIA *crt;
	char version[32];
	int rc = 1;
	AddressSpace *cpuAS = NULL;

	SDL_Init(SDL_INIT_VIDEO);

	printf("This is e, the Polaris 64-bit RISC-V architecture emulator.\n");
	printf("Version %d.%d.%d.\n", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
	cpuAS = as->make(oo->make(argc, argv));
	p = pp->make(cpuAS);
	if(!p) {
		fprintf(stderr, "Out of memory allocating processor\n");
		goto out;
	}

	sprintf(version, "e Version %d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
	crt = makeMGIA(version, cpuAS);
	if(!crt) {
		fprintf(stderr, "Unable to emulate video display.\n");
		goto out;
	}

	t = tt->make();
	if(!t) {
		fprintf(stderr, "Out of memory allocating a timeline\n");
		goto out;
	}

	tt->schedule(t, &do_crt_frame, 480*400, crt);

	while(running) {
		tt->pending(t);
		pp->step(p, t);
		running &= p->running;
		while(SDL_PollEvent(&sdlEvent)) {
			switch(sdlEvent.type) {
			case SDL_QUIT:
				running = 0;
				break;
			}
		}
	}

	rc = p->rc;

out:	if(t)		tt->destroy(t);
	if(crt)		destroyMGIA(crt);
	SDL_Quit();

	return rc;
}


int main(int argc, char *argv[]) {
	int result;

	console_1char_mode();
	result = run(argc, argv);
	console_line_mode();
	return result;
}

