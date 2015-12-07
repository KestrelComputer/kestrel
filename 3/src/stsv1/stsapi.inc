; When a program is launched under STS, the registers are set
; as follows, according to the existing BSPL ABI:
;
; X1		Return Address to whatever launched your program
; X2		Data Stack Pointer
; X3		Return Stack Pointer
; X4		Global Variables Pointer
; X5..X15	Undefined; best not to use them without saving first.
; X16..X31	Undefined; these needn't be saved.
;
; Note that X1, X2, X3, and X4 refer to the CALLING PROGRAM's data,
; return, and GV areas.  A well-written STS program will set up its
; own environment to isolate itself from the calling program.  This
; involves saving X1, X2, X3, and X4 somewhere safe, so that when
; your program wants to exit, you can restore these registers and
; return to the calling program.
;
; The calling program will place some parameters on the data stack
; for your benefit, however.  The data stack will be laid out as
; follows:
;
; DSP+0		Pointer to STS jump table.
; DSP+8		Return code (defaults to 0).
; DSP+16	Pointer to the first segment of the program.
; DSP+24	Length of the command name.
; DSP+32	Address of the command name.
; DSP+40	Length of the command tail.
; DSP+48	Address of the command tail.
;
; If your program wishes to return a result code to the calling
; program, such as a command shell, you'll need to update the
; value at DSP+8 with the appropriate value.  This value will
; be interpreted by the calling program.  It defaults to zero,
; usually taken to mean "success", so programs don't need to
; explicitly change it unless it wants to communicate a failure.
;
; The STS_xxx definitions provide byte-offsets from the STS-
; provided vtable, allowing applications to make system calls.

STS_GETVER	=	0	; V1.5+
STS_GETMEM	=	4	; V1.0+
STS_FREMEM	=	8	; V1.0+
STS_MOVMEM	=	12	; V1.2+
STS_SETMEM	=	16	; V1.5+
STS_ZERMEM	=	20	; V1.5+
STS_OPEN	=	24	; V1.0+
STS_CLOSE	=	28	; V1.0+
STS_FILSIZ	=	32	; V1.5+
STS_READ	=	36	; V1.0+
STS_WRITE	=	40	; V1.5+
STS_SEEK	=	44	; V1.5+
STS_LOADSEG	=	48	; V1.0+
STS_UNLOADSEG	=	52	; V1.0+
STS_STREQL	=	56	; V1.1+
STS_STRDUP	=	60	; V1.5+

; The following entry points into STS are not standardized,
; and almost certainly will change in the future.

STS_STRSPLSLASH	=	64
STS_EMIT	=	68
STS_TYPE	=	72
STS_CR		=	76
STS_SPACE	=	80
STS_HEX64	=	84
STS_POLKEY	=	88
STS_GETKEY	=	92
