#include <stdio.h>
#include <assert.h>

#include <SDL/SDL.h>

typedef Uint32                  L;
typedef enum { NO, YES }        B;
typedef SDL_Surface *           S;

typedef struct k_state {
    /* Buses */
    L       _rst_i, rst_i;
    L       i_adr_o, i_dat_i;
    L       d_adr_o, d_dat_o, d_dat_i, _d_we_o, d_we_o;
    /* Processor State */
    L       _nip, nip;
    L       _pc_r;
    L       ds[32], _n, _t, _dsp, t, dsp;
    L       rs[32], _rsp, rsp;
    /* Memory */
    L       ram[32768];
    /* Emulator Condition */
    B       stop_emulation;
} k_state, *K;

const int VB=0x4000;    /* Video base address */

#define DB(f,args...)           fprintf(stderr, f, ##args);
#define N                       kk->ds[31&(kk->dsp-1)]
#define nV(x)                   L x(K kk)
#define R                       kk->rs[31&(kk->rsp-1)]
#define RT(x)                   if((x))return;
#define RF(x)                   RT(!(x))
#define _SL(x)                  ((signed long)((x)))
#define T                       kk->t
#define TIMES(x,y,z)            for(x=0;x<(y);x++){z}
#define V(x)                    void x (K kk)
#define Vn(x)                   void x (K kk, L n)
#define _L(x)                   ((L*)((x)))
#define _UL(x)                  ((unsigned long)((x)))


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

V(ram_sample) {
}

V(ram_latch) {
    kk->i_dat_i = kk->ram[kk->i_adr_o];
    kk->d_dat_i = kk->ram[kk->d_adr_o];
    RF(kk->d_we_o);
    kk->ram[kk->d_adr_o] = kk->d_dat_o;
}

nV(aluT) { return T; }
nV(aluN) { return N; }
nV(aluTplN) { return T+N; }
nV(aluTandN) { return T&N; }
nV(aluTorN) { return T|N; }
nV(aluTxorN) { return T^N; }
nV(aluTnot) { return ~T; }
nV(aluNeqT) { return -1*(N==T); }
nV(aluNltT) { return -1*(_SL(N) < _SL(T)); }
nV(aluNrshT) { return N<<T; }
nV(aluTm1) { return T-1; }
nV(aluR) { return R; }
nV(aluFetch) { return kk->d_dat_i; }
nV(aluNlshT) { return N>>T; }
nV(aluDepth) { DB("depth not implemented at address %04X\n", kk->nip); return 0; }
nV(aluNultT) { return -1*(_UL(N)<_UL(T)); }

typedef L ALUOP(K);
ALUOP *aluOp[16] = {aluT, aluN, aluTplN, aluTandN, aluTorN, aluTxorN, aluTnot, aluNeqT, aluNltT, aluNrshT, aluTm1, aluR, aluFetch, aluNlshT, aluDepth, aluNultT};

V(dbg) { DB("N:%04X T:%04X DSP:%d R: %04X RSP: %d NIP: %04X IN:%04X RA:%04X RD:%04X %s:%04X\n", N, T, kk->dsp, R, kk->rsp, kk->nip, kk->ram[kk->nip], kk->d_adr_o, kk->d_dat_i, (kk->d_we_o?"wr":"WR"), kk->d_dat_o); }

Vn(jump) { kk->_nip = n; }
Vn(call) { kk->_pc_r = YES; jump(kk, n); }
Vn(walk) { kk->_nip = kk->nip+1; }
Vn(jumpT0) { kk->_dsp = kk->_dsp-1; kk->_t = N; if(kk->t) walk(kk,n); else jump(kk,n); }
Vn(literal) { kk->ds[kk->dsp] = kk->t; kk->_t = n; kk->_dsp = 31&(kk->dsp+1); walk(kk,n); }
Vn(alu) {
    walk(kk,n);
    if(n&0x1000) kk->_nip = R;
    kk->_t = aluOp[(n&0x0F00)>>8](kk);
    if(n&0x0080) kk->ds[kk->_dsp] = kk->t;
    if(n&0x0040) kk->rs[kk->_rsp] = kk->t;
    kk->d_we_o = (n&0x0020) != 0;
    if(n&0x0010) dbg(kk);
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
}

V(tt) {
    static time_t m, n;
    static long freq;
    n = m;
    time(&m);
    if(n!=m){fprintf(stderr,"\rClk: %ld Hz", freq);freq=0;}
    else{freq++;}
}

V(sample) {cpu_sample(kk); ram_sample(kk); }
V(latch)  {cpu_latch(kk); ram_latch(kk); tt(kk);}

void react(K kk) {
    SDL_Event e;
    while(SDL_PollEvent(&e)){
        switch(e.type){
            case SDL_QUIT:      kk->stop_emulation=YES; break;
        }
    }
}

void emulate(S fb) {
    k_state kk = {1,1,};
    int h, v;
    FILE *romFile;

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

