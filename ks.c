#include <stdio.h>
#include <assert.h>

#include <SDL/SDL.h>

typedef Uint32                  L;
typedef enum { NO, YES }        B;
typedef SDL_Surface *           S;

typedef struct k_state {
    L       _rst_i, rst_i;
    L       i_adr_o, i_dat_i;
    L       d_adr_o, d_dat_o, d_dat_i, _d_we_o, d_we_o;

    L       ds[32], rs[32];         /* Data and Return stacks */
    L       _t, t;                  /* Top of data stack */
    L       _nip, nip;              /* Next Instruction Pointer */
    L       _dsp, dsp, _rsp, rsp;   /* Data and Return stack pointers */

    L       _n;

    L       _pc_r;

    L       ram[32768];

    B       stop_emulation;

    L       dbg;

    long kbqu;

    int kbct;

} k_state, *K;

const int VB=0x4000;    /* Video base address */
const int KB=0x7FFC;    /* Keyboard I/O registers */

#define DB(f,args...)           fprintf(stderr, f, ##args);

#define N                       kk->ds[31&(kk->dsp-1)]
#define R                       kk->rs[31&(kk->rsp-1)]
#define T                       kk->t

#define nV(x)                   L x(K kk)
#define V(x)                    void x (K kk)
#define Vn(x)                   void x (K kk, L n)

#define RT(x)                   if((x))return;
#define RF(x)                   RT(!(x))

#define _SL(x)                  ((signed long)((x)))
#define _L(x)                   ((L*)((x)))
#define _UL(x)                  ((unsigned long)((x)))

#define TIMES(x,y,z)            for(x=0;x<(y);x++){z}


V(dbg) { DB("N:%04X T:%04X DSP:%d R: %04X RSP: %d NIP: %04X IN:%04X RA:%04X RD:%04X %s:%04X\n", N, T, kk->dsp, R, kk->rsp, kk->nip, kk->ram[kk->nip], kk->d_adr_o, kk->d_dat_i, (kk->d_we_o?"wr":"WR"), kk->d_dat_o); }

void with_sdl(void(*f)()) {
    if(SDL_Init(SDL_INIT_VIDEO)) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        exit(1);
    }
    f();
    SDL_Quit();
}

void with_framebuffer(void(*f)(S)) {
    S fb;

    fb = SDL_SetVideoMode(640, 400, 32, SDL_SWSURFACE);
    if(fb) {
        f(fb);
        SDL_FreeSurface(fb);
    } else {
        fprintf(stderr, "with_framebuffer: %s\n", SDL_GetError());
    }
}

void expand(L **s, L **d) {
    L i,j=**s; (*s)++;
    TIMES(i,16,**d=(((j&0x8000)!=0)*0xFFFFFF); j<<=1; (*d)++;);
}

void transcribe_line(K kk, S fb, int line) {
    L i, l=line-125, *d = _L(fb->pixels+fb->pitch*l), *s = _L(kk->ram+VB+40*(l>>1));
    RT(line<125); RT(line&1);
    TIMES(i,40,expand(&s,&d););
}

Vn(walk) { kk->_nip = kk->nip+1; }

Vn(jump) { kk->_nip = n; }
Vn(call) { kk->_pc_r = YES; jump(kk, n); }
Vn(jumpT0) { kk->_dsp = kk->_dsp-1; kk->_t = N; if(kk->t) walk(kk,n); else jump(kk,n); }

Vn(literal) { kk->ds[kk->dsp] = kk->t; kk->_t = n; kk->_dsp = 31&(kk->dsp+1); walk(kk,n); }

nV(aluT) { return T; }
nV(aluN) { return N; }
nV(aluTplN) { return T+N; }
nV(aluTandN) { return T&N; }
nV(aluTorN) { return T|N; }
nV(aluTxorN) { return T^N; }
nV(aluTnot) { return ~T; }
nV(aluNeqT) { return -1*(N==T); }
nV(aluNltT) { return -1*(_SL(N) < _SL(T)); }
nV(aluNrshT) { return N>>T; }
nV(aluTm1) { return T-1; }
nV(aluR) { return R; }
nV(aluFetch) { return kk->d_dat_i; }
nV(aluNlshT) { return N<<T; }
nV(aluDepth) { DB("depth not implemented at address %04X\n", kk->nip); return 0; }
nV(aluNultT) { return -1*(_UL(N)<_UL(T)); }

typedef L ALUOP(K);
ALUOP *aluOp[16] = {aluT, aluN, aluTplN, aluTandN, aluTorN, aluTxorN, aluTnot, aluNeqT, aluNltT, aluNrshT, aluTm1, aluR, aluFetch, aluNlshT, aluDepth, aluNultT};

Vn(alu) {
    walk(kk,n);
    if(n&0x1000) kk->_nip = R;
    kk->_t = aluOp[(n&0x0F00)>>8](kk);
    kk->d_we_o = (n&0x0020) != 0;
    kk->dbg^=n&0x0010;
    switch((n&0x000C)>>2) {
        case 0: break;
        case 1: kk->_rsp = (kk->rsp+1); break;
        case 2: kk->_rsp = (kk->rsp-2); break;
        case 3: kk->_rsp = (kk->rsp-1); break;
    }
    switch(n&3) {
        case 0: break;
        case 1: kk->_dsp = (kk->dsp+1); break;
        case 2: kk->_dsp = (kk->dsp-2); break;
        case 3: kk->_dsp = (kk->dsp-1); break;
    }
    if(n&0x0080) kk->ds[kk->_dsp-1] = kk->t;
    if(n&0x0040) kk->rs[kk->_rsp] = kk->t;
}

Vn(all) {
    kk->d_dat_o = N;
    kk->d_adr_o = (T>>1);
}

V(cpu_sample) {
    L i15_13 = (kk->i_dat_i & 0xE000)>>13;
    L i12_0 = kk->i_dat_i & 0x1FFF;

    kk->_rst_i = (kk->rst_i)?(kk->rst_i-1):0;
    kk->d_we_o = 0;
    all(kk,i12_0);
    switch(i15_13) {
        case 0:     jump(kk, i12_0); break;
        case 1:     jumpT0(kk, i12_0); break;
        case 2:     call(kk, i12_0); break;
        case 3:     alu(kk, i12_0); break;
        default:    literal(kk, kk->i_dat_i&0x7FFF); break;
    }
    kk->_nip &= 0x1FFF;
}

V(ram_sample) {}

V(sample) {cpu_sample(kk); ram_sample(kk); }

V(cpu_latch) {
    kk->rst_i = kk->_rst_i;

    if(kk->_pc_r) {
        kk->rs[kk->rsp] = kk->nip+1;
        kk->_rsp = kk->rsp+1;
        kk->_pc_r = NO;
    }

    kk->t = 0xFFFF&kk->_t;
    kk->nip = kk->_nip;
    kk->i_adr_o = kk->nip;
    kk->dsp = 31&kk->_dsp;
    kk->rsp = 31&kk->_rsp;

    if(kk->dbg) dbg(kk);
}

V(ram_latch) {
    kk->i_dat_i = kk->ram[kk->i_adr_o];

    switch(kk->d_adr_o){
        case 0x7FFF:    kk->d_dat_i=(kk->kbqu&0xFFFF0000)>>16; break;
        case 0x7FFE:    kk->d_dat_i=kk->kbqu&0x0000FFFF; break;
        case 0x7FFD:    kk->d_dat_i=kk->kbct; break;
        case 0x7FFC:    kk->d_dat_i=0x0000; break;  /* Unused hardware register at this time. */

        default:        kk->d_dat_i=kk->ram[kk->d_adr_o];
    }

    RF(kk->d_we_o);
    kk->ram[kk->d_adr_o] = kk->d_dat_o;


}

V(tt) {
    static time_t m, n;
    static long freq;
    n = m;
    time(&m);
    if(n!=m){fprintf(stderr,"\rClk: %ld Hz", freq);freq=0;}
    else{freq++;}
}

V(latch)  {cpu_latch(kk); ram_latch(kk); tt(kk);}

static int SDL2kbd[]={
    '`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0x08,
    0x09, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\\',
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', 0x0D,
    'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', ' ',

    0x0130, 0x012F,                     /* Left, Right shift */
    0x0132, 0x0131,                     /* Left, Right control */
    0x0134, 0x0133,                     /* Left, Right Alt */
    0x012D,                             /* CAPS Lock */
    0x001B,                             /* ESC */
    0x011A, 0x011B, 0x011C, 0x011D,     /* F1...  */
    0x011E, 0x011F, 0x0120, 0x0121,
    0x0122, 0x0123, 0x0124, 0x0125,     /* ...F12 */
    0x0111, 0x0112, 0x0113, 0x0114,     /* Cursor up, down, right, left */
};

static int kbd2PS2[]={
    0x0E, 0x16, 0x1E, 0x26, 0x25, 0x2E, 0x36, 0x3D, 0x3E, 0x46, 0x45, 0x4E, 0x55, 0x66,
    0x0D, 0x15, 0x1D, 0x24, 0x2D, 0x2C, 0x35, 0x3C, 0x43, 0x44, 0x4D, 0x54, 0x5B, 0x5D,
    0x1C, 0x1B, 0x23, 0x2B, 0x34, 0x33, 0x3B, 0x42, 0x4B, 0x4C, 0x52, 0x5A,
    0x12, 0x22, 0x21, 0x2A, 0x32, 0x31, 0x3A, 0x41, 0x49, 0x4A, 0x29,

    0x12, 0x59,                         /* Left, right shift */
    0x14, 0xE014,                       /* Left, right control */
    0x11, 0xE011,                       /* Left, right Alt */
    0x58,                               /* CAPS Lock */
    0x76,                               /* ESC */
    0x05, 0x06, 0x04, 0x0C,             /* F1...  */
    0x03, 0x0B, 0x83, 0x0A,
    0x01, 0x09, 0x78, 0x07,             /* ...F12 */
    0xE075, 0xE072, 0xE074, 0xE06B,     /* Cursor up, down, right, left */
};

void enqu(K kk, int c) {kk->kbqu=(kk->kbqu<<8)|(c&0xFF); kk->kbct++;}

void keypress(int up, SDL_Event *e, K kk) {
    int i,c,ext;

    for(i=0;i<512;i++){if(SDL2kbd[i]==e->key.keysym.sym)break;}

    c=kbd2PS2[i];

    ext=2*((c&0xFF00)==0xE000);
    switch(ext+up) {
        case 0:     break;
        case 1:     enqu(kk, 0xF0); break;
        case 2:     enqu(kk, 0xE0); break;
        case 3:     enqu(kk, 0xE0); enqu(kk, 0xF0); break;
    }
    enqu(kk, c);

}

void react(K kk) {
    SDL_Event e;
    while(SDL_PollEvent(&e)){
        switch(e.type){
            case SDL_QUIT:      kk->stop_emulation=YES; break;
            case SDL_KEYDOWN:   keypress(0, &e, kk); break;
            case SDL_KEYUP:     keypress(1, &e, kk); break;
        }
    }
}

void emulate(S fb) {
    k_state kk = {1,1,};

    FILE *romFile;

    int h, v;

    romFile = fopen("romfile", "rb");
    if(romFile){
        int i=0,h,l;
        for(;;){
            if(feof(romFile)) break;
            if(i>=8192) break;
            h=fgetc(romFile)&0xFF;  l=fgetc(romFile)&0xFF;
            kk.ram[i++]=l|(h<<8);
        }
        fclose(romFile);
    }else{
        perror("main: romfile");
        exit(1);
    }

    memset(fb->pixels, 0, fb->pitch * fb->h);
    for(kk.stop_emulation = NO; !kk.stop_emulation;){
        TIMES(v,525,TIMES(h,397,sample(&kk);latch(&kk););transcribe_line(&kk, fb, v);)
        SDL_Flip(fb);
        react(&kk);
    }

}

void show_monitor(void)             { with_framebuffer(emulate); }

int  main(int argc, char *argv[])   { with_sdl(show_monitor); return 0; }


