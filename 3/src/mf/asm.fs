\ This file's job is to produce actual assembly language output for the code
\ currently in the compiler buffer, in a syntax suitable for an assembler.
\ The implementation currently targets my home-grown Python-written assembler.

: addr		ci @ cells buf + ;
: insn		addr @ ;
: 256/		2/ 2/ 2/ 2/ 2/ 2/ 2/ 2/ ;
: r1		insn 8 rshift $FF and ;
: r2		insn 16 rshift $FF and ;
: r3		insn 24 rshift $FF and ;
: param		insn 256/ 256/ 256/ 256/ ;
: offset	param 8 * ;	 ( for now )

variable lgplab
: lgp0		0 lgplab ! ;
lgp0

: .align	."  align 8" cr ;
: _noop		."  addi  x0, x0, 0" cr ;
: _lit		."  ld    x" r1 . ." , (" cur @ name type ." -LGP" lgplab ? ." )" offset . ." (gp)" cr ;
: .add		r1 . ." , x" r2 . ." , x" r3 . cr ;
: _add		."  add   x" .add ;
: _sub		."  sub   x" .add ;
: _and		."  and   x" .add ;
: _or		."  or    x" .add ;
: _xor		."  xor   x" .add ;
: _label	." L" insn 8 rshift . ." :" cr ;
: _@8		."  lb    x" r1 . ." , 0(x" r1 . ." )" cr ;
: _@16		."  lh    x" r1 . ." , 0(x" r1 . ." )" cr ;
: _@32		."  lw    x" r1 . ." , 0(x" r1 . ." )" cr ;
: _@64		."  ld    x" r1 . ." , 0(x" r1 . ." )" cr ;
: _!8		."  sb    x" r2 . ." , 0(x" r1 . ." )" cr ;
: _!16		."  sh    x" r2 . ." , 0(x" r1 . ." )" cr ;
: _!32		."  sw    x" r2 . ." , 0(x" r1 . ." )" cr ;
: _!64		."  sd    x" r2 . ." , 0(x" r1 . ." )" cr ;
: _j		."  jal   x0, L" insn 256/ . cr ;
: .jz		r1 . ." , x0, L" param . cr ;
: _jz		."  beq   x" .jz ;
: _call		."  jal   ra, " insn 256/ name type cr ;
: _rfs		."  jalr  x0, 0(ra)" cr ;
: drsp		."  addi  rsp, rsp, -8" cr ;
: irsp		."  addi  rsp, rsp, 8" cr ;
: _>r		drsp ."  sd    x" r1 . ." , 0(rsp)" cr ;
: _r>		."  ld    x" r1 . ." , 0(rsp)" cr irsp ;
: _r@		."  ld    x" r1 . ." , " offset . ." (rsp)" cr ;
: _r!		."  sd    x" r1 . ." , " offset . ." (rsp)" cr ;
: ddsp		."  addi  dsp, dsp, -8" cr ;
: idsp		."  addi  dsp, dsp, 8" cr ;
: _>d		ddsp ."  sd    x" r1 . ." , 0(dsp)" cr ;
: _d>		."  ld    x" r1 . ." , 0(dsp)" cr idsp ;
: _d@		."  ld    x" r1 . ." , " offset . ." (dsp)" cr ;
: _d!		."  sd    x" r1 . ." , " offset . ." (dsp)" cr ;
: _dup		( handled internally by the compiler ) ;
: _over		( handled internally by the compiler ) ;
: _drop		( handled internally by the compiler ) ;
: _nip		( handled internally by the compiler ) ;
: _rot		( handled internally by the compiler ) ;
: _swap		( handled internally by the compiler ) ;
: _lgp		1 lgplab +! ." LGP" lgplab ? ." :" cr ."  auipc gp, 0" cr ;
: _prolog	drsp ."  sd    ra, 0(rsp)" cr ;
: _epilog	."  ld    ra, 0(rsp)" cr irsp ;
: _jnz		."  bne   x" .jz ;
: .2*		r1 . ." , x" r1 . ." , 1" cr ;
: _2*		."  slli  x" .2* ;
: _u2/		."  srli  x" .2* ;
: _2/		."  srai  x" .2* ;
: _jge		."  bge   x" .jz ;
: _gvpea	."  addi  x" r1 . ." , gvp, " param . cr ;

create procedures
' _noop ,
' _lit ,
' _add ,	( + )
' _sub ,	( - )
' _and ,	( and )
' _or ,		( or )
' _xor ,	( xor )
' _label ,	( label )
' _@8 ,		( @8 )
' _@16 ,	( @16 )
' _@32 ,	( @32 )
' _@64 ,	( @64 )
' _!8 ,		( !8 )
' _!16 ,	( !16 )
' _!32 ,	( !32 )
' _!64 ,	( !64 )
' _j ,		( J )
' _jz ,		( JZ )
' _call ,	( CALL )
' _rfs ,	( RFS )
' _>r ,		( >R )
' _r> ,		( R> )
' _r@ ,		( R@ )
' _r! ,		( R! )
' _>d ,		( >D )
' _d> ,		( D> )
' _d@ ,		( D@ )
' _d! ,		( D! )
' _dup ,
' _over ,
' _drop ,
' _nip ,
' _rot ,
' _swap ,
' _lgp ,	( LGP )
' _prolog ,	( PROLOG )
' _epilog ,	( EPILOG )
' _jnz ,	( JNZ )
' _2* ,		( LSHIFT )
' _u2/ ,	( RSHIFT )
' _2/ ,		( RSHIFT arithmetic )
' _jge ,	( JGE )
' _gvpea ,	( GVPEA )

: value		insn s>d hex <# # # # # # # # # # # # # # # # # #> type ;
: dword		base @ ."   dword $" value cr base ! ;
: dwords0	begin ci @ fi @ >= if exit then dword ci inc again ;
: .dwords	0 ci ! dwords0 ;

: .label	cur @ name type ." :" cr ;

: opcode	insn 255 and ;
: dispatch	opcode cells procedures + @ execute ;
: code0		begin ci @ ni @ >= if exit then dispatch ci inc again ;
: .code		fi @ ci ! code0 ;

: asm		.align .dwords .label .code ;

