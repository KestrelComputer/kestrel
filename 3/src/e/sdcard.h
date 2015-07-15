#ifndef E_SDCARD_H
#define E_SDCARD_H


#define GPIA_OUT_SD_LED		0x0001
#define GPIA_OUT_SD_SS		0x0002
#define GPIA_OUT_SD_MOSI	0x0004
#define GPIA_OUT_SD_CLK		0x0008

#define GPIA_IN_SD_CD		0x0001
#define GPIA_IN_SD_WP		0x0002
#define GPIA_IN_SD_MISO		0x0004


#define	SDCMD_GO_IDLE_STATE	0
#define SDCMD_SEND_OP_COND	1
#define SDCMD_SEND_IF_COND	8
#define SDCMD_SEND_CSD		9
#define SDCMD_SEND_CID		10
#define SDCMD_STOP_TRANSMISSION	12
#define SDCMD_SET_BLKLEN	16
#define SDCMD_READ_BLOCK	17
#define SDCMD_READ_MULTIPLE	18
#define SDCMD_SET_BLK_COUNT	23
#define SDCMD_WRITE_BLOCK	24
#define SDCMD_WRITE_MULTIPLE	25
#define SDCMD_APP_CMD		55
#define SDCMD_READ_OCR		58

#define SDBUF_SIZE		3172


typedef struct SDCard SDCard;


struct SDCard {
	int	selected;
	void	(*cmd_handler)(SDCard *);
	BYTE	command[SDBUF_SIZE];
	int	cmd_index;
	int	cmd_length;
	BYTE	response[SDBUF_SIZE];
	int	response_rd;
	int	response_wr;
	int	acmdPrefix;
	int	blockLength;
	WORD	seek_address;
};


SDCard *	sdcard_new(void);
void		sdcard_dispose(SDCard *);
BYTE		sdcard_byte(SDCard *, BYTE);
void		sdcard_select(SDCard *);
void		sdcard_enqueue_response(SDCard *, BYTE);

#endif

