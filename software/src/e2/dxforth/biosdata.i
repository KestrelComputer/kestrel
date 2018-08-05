BI_MATCHWORD	=	$0BADC0DEB105DA7A

bi_matchword		=	0
bi_term_cursor_on	=	bi_matchword+8
bi_term_cursor_off	=	bi_term_cursor_on+8
bi_term_cursor_swap	=	bi_term_cursor_off+8
bi_term_out_clear	=	bi_term_cursor_swap+8
bi_term_out_chr		=	bi_term_out_clear+8
bi_term_out_buf		=	bi_term_out_chr+8
bi_term_out_str		=	bi_term_out_buf+8
bi_term_in_pollraw	=	bi_term_out_str+8
bi_term_in_rawtoascii	=	bi_term_in_pollraw+8
bi_term_in_getmeta	=	bi_term_in_rawtoascii+8
bi_term_in_setshift	=	bi_term_in_getmeta+8
bi_term_in_setctrl	=	bi_term_in_setshift+8
bi_sdmmc_writeblock	=	bi_term_in_setctrl+8
bi_sdmmc_readblock	=	bi_sdmmc_writeblock+8
bi_sdmmc_idle		=	bi_sdmmc_readblock+8
bi_sdmmc_is_present	=	bi_sdmmc_idle+8
bi_spi_select   	=	bi_sdmmc_is_present+8
bi_spi_deselect         =	bi_spi_select+8
bi_SIZEOF		=	bi_spi_deselect+8

RAWKEY_CTRL_L           =       $0014
RAWKEY_CTRL_R           =       $0114
RAWKEY_SHIFT_L          =       $0012
RAWKEY_SHIFT_R          =       $0059
RAWKEYF_RELEASE         =       $8000

