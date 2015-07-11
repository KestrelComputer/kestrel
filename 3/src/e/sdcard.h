#ifndef E_SDCARD_H
#define E_SDCARD_H


#define GPIA_OUT_SD_LED		0x0001
#define GPIA_OUT_SD_SS		0x0002
#define GPIA_OUT_SD_MOSI	0x0004
#define GPIA_OUT_SD_CLK		0x0008

#define GPIA_IN_SD_CD		0x0001
#define GPIA_IN_SD_WP		0x0002
#define GPIA_IN_SD_MISO		0x0004


extern UDWORD gpia_out;
extern UDWORD gpia_in;


void handle_spi(void);


#endif

