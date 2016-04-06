\ This driver interfaces EForth to the KIA-2 core, which
\ communicates to the host using keycodes expressed in SDL
\ library format.  This most often occurs when the Kestrel
\ is running in emulation.

tcreate unshifted
$00 tc, $01 tc, $02 tc, $03 tc, $04 tc, $05 tc, $06 tc, $07 tc,
$08 tc, $09 tc, $0A tc, $0B tc, $0C tc, $0D tc, $0E tc, $0F tc,
$10 tc, $11 tc, $12 tc, $13 tc, $14 tc, $15 tc, $16 tc, $17 tc,
$18 tc, $19 tc, $1A tc, $1B tc, $1C tc, $1D tc, $1E tc, $1F tc,
$20 tc, $21 tc, $00 tc, $23 tc, $24 tc, $25 tc, $26 tc, $27 tc,
$28 tc, $29 tc, $2A tc, $2B tc, $2C tc, $2D tc, $2E tc, $2F tc,
'0 tc, '1 tc, '2 tc, '3 tc, '4 tc, '5 tc, '6 tc, '7 tc,
'8 tc, '9 tc, '; tc, '; tc, ', tc, '= tc, '. tc, '/ tc,
'@ tc, 'a tc, 'b tc, 'c tc, 'd tc, 'e tc, 'f tc, 'g tc,
'h tc, 'i tc, 'j tc, 'k tc, 'l tc, 'm tc, 'n tc, 'o tc,
'p tc, 'q tc, 'r tc, 's tc, 't tc, 'u tc, 'v tc, 'w tc,
'x tc, 'y tc, 'z tc, '[ tc, '\ tc, '] tc, '^ tc, '- tc,
'` tc, 'a tc, 'b tc, 'c tc, 'd tc, 'e tc, 'f tc, 'g tc,
'h tc, 'i tc, 'j tc, 'k tc, 'l tc, 'm tc, 'n tc, 'o tc,
'p tc, 'q tc, 'r tc, 's tc, 't tc, 'u tc, 'v tc, 'w tc,
'x tc, 'y tc, 'z tc, '[ tc, '\ tc, '] tc, '^ tc, 127 tc,

tcreate ctrled
$00 tc, $01 tc, $02 tc, $03 tc, $04 tc, $05 tc, $06 tc, $07 tc,
$08 tc, $09 tc, $0A tc, $0B tc, $0C tc, $0D tc, $0E tc, $0F tc,
$10 tc, $11 tc, $12 tc, $13 tc, $14 tc, $15 tc, $16 tc, $17 tc,
$18 tc, $19 tc, $1A tc, $1B tc, $1C tc, $1D tc, $1E tc, $1F tc,
$20 tc, $21 tc, $00 tc, $23 tc, $24 tc, $25 tc, $26 tc, $27 tc,
$28 tc, $29 tc, $2A tc, $2B tc, $2C tc, $2D tc, $2E tc, $2F tc,
'0 tc, '1 tc, $00 tc, '3 tc, '4 tc, '5 tc, '6 tc, '7 tc,
'8 tc, '9 tc, '; tc, '; tc, ', tc, '= tc, '. tc, '/ tc,
$00 tc, $01 tc, $02 tc, $03 tc, $04 tc, $05 tc, $06 tc, $07 tc,
$08 tc, $09 tc, $0A tc, $0B tc, $0C tc, $0D tc, $0E tc, $0F tc,
$10 tc, $11 tc, $12 tc, $13 tc, $14 tc, $15 tc, $16 tc, $17 tc,
$18 tc, $19 tc, $1A tc, $1B tc, $1C tc, $1D tc, $1E tc, $1F tc,
$00 tc, $01 tc, $02 tc, $03 tc, $04 tc, $05 tc, $06 tc, $07 tc,
$08 tc, $09 tc, $0A tc, $0B tc, $0C tc, $0D tc, $0E tc, $0F tc,
$10 tc, $11 tc, $12 tc, $13 tc, $14 tc, $15 tc, $16 tc, $17 tc,
$18 tc, $19 tc, $1A tc, $1B tc, $1C tc, $1D tc, $1E tc, $08 tc,

tcreate shifted
$00 tc, $01 tc, $02 tc, $03 tc, $04 tc, $05 tc, $06 tc, $07 tc,
$08 tc, $09 tc, $0A tc, $0B tc, $0C tc, $0D tc, $0E tc, $0F tc,
$10 tc, $11 tc, $12 tc, $13 tc, $14 tc, $15 tc, $16 tc, $17 tc,
$18 tc, $19 tc, $1A tc, $1B tc, $1C tc, $1D tc, $1E tc, $1F tc,
$20 tc, $21 tc, $00 tc, $23 tc, $24 tc, $25 tc, $26 tc, $22 tc,
$28 tc, $29 tc, $2A tc, $2B tc, '< tc, '_ tc, '> tc, '? tc,
') tc, '! tc, '@ tc, '# tc, '$ tc, '% tc, '^ tc, '& tc,
'* tc, '( tc, ': tc, ': tc, '< tc, '+ tc, '> tc, '? tc,
'@ tc, 'A tc, 'B tc, 'C tc, 'D tc, 'E tc, 'F tc, 'G tc,
'H tc, 'I tc, 'J tc, 'K tc, 'L tc, 'M tc, 'N tc, 'O tc,
'P tc, 'Q tc, 'R tc, 'S tc, 'T tc, 'U tc, 'V tc, 'W tc,
'X tc, 'Y tc, 'Z tc, '{ tc, '| tc, '} tc, '~ tc, '_ tc,
'` tc, 'A tc, 'B tc, 'C tc, 'D tc, 'E tc, 'F tc, 'G tc,
'H tc, 'I tc, 'J tc, 'K tc, 'L tc, 'M tc, 'N tc, 'O tc,
'P tc, 'Q tc, 'R tc, 'S tc, 'T tc, 'U tc, 'V tc, 'W tc,
'X tc, 'Y tc, 'Z tc, '{ tc, '| tc, '} tc, '~ tc, 127 tc,

tcreate alted
$00 tc, $01 tc, $02 tc, $03 tc, $04 tc, $05 tc, $06 tc, $07 tc, 
$08 tc, $09 tc, $0A tc, $0B tc, $0C tc, $0D tc, $0E tc, $0F tc, 
$90 tc, $91 tc, $92 tc, $93 tc, $94 tc, $95 tc, $96 tc, $97 tc, 
$98 tc, $99 tc, $9A tc, $9B tc, $9C tc, $9D tc, $9E tc, $9F tc, 
$A0 tc, $A1 tc, $00 tc, $A3 tc, $A4 tc, $A5 tc, $A6 tc, $A7 tc, 
$A8 tc, $A9 tc, $AA tc, $AB tc, $AC tc, $AD tc, $AE tc, $AF tc, 
$B0 tc, $B1 tc, $B2 tc, $B3 tc, $B4 tc, $B5 tc, $B6 tc, $B7 tc, 
$B8 tc, $B9 tc, $BA tc, $BB tc, $BC tc, $BD tc, $BE tc, $BF tc, 
$E0 tc, $E1 tc, $E2 tc, $E3 tc, $E4 tc, $E5 tc, $E6 tc, $E7 tc, 
$E8 tc, $E9 tc, $EA tc, $EB tc, $EC tc, $ED tc, $EE tc, $EF tc, 
$F0 tc, $F1 tc, $F2 tc, $F3 tc, $F4 tc, $F5 tc, $F6 tc, $F7 tc, 
$F8 tc, $F9 tc, $FA tc, $FB tc, $FC tc, $FD tc, $FE tc, $FF tc, 
$E0 tc, $E1 tc, $E2 tc, $E3 tc, $E4 tc, $E5 tc, $E6 tc, $E7 tc, 
$E8 tc, $E9 tc, $EA tc, $EB tc, $EC tc, $ED tc, $EE tc, $EF tc, 
$F0 tc, $F1 tc, $F2 tc, $F3 tc, $F4 tc, $F5 tc, $F6 tc, $F7 tc, 
$F8 tc, $F9 tc, $FA tc, $FB tc, $FC tc, $FD tc, $FE tc, $FF tc, 

tcreate shiftalted
$00 tc, $01 tc, $02 tc, $03 tc, $04 tc, $05 tc, $06 tc, $07 tc, 
$08 tc, $09 tc, $0A tc, $0B tc, $0C tc, $0D tc, $0E tc, $0F tc, 
$90 tc, $91 tc, $92 tc, $93 tc, $94 tc, $95 tc, $96 tc, $97 tc, 
$98 tc, $99 tc, $9A tc, $9B tc, $9C tc, $9D tc, $9E tc, $9F tc, 
$A0 tc, $A1 tc, $00 tc, $A3 tc, $A4 tc, $A5 tc, $A6 tc, $A7 tc, 
$A8 tc, $A9 tc, $AA tc, $AB tc, $AC tc, $AD tc, $AE tc, $AF tc, 
$B0 tc, $B1 tc, $B2 tc, $B3 tc, $B4 tc, $B5 tc, $B6 tc, $B7 tc, 
$B8 tc, $B9 tc, $BA tc, $BB tc, $BC tc, $BD tc, $BE tc, $BF tc, 
$C0 tc, $C1 tc, $C2 tc, $C3 tc, $C4 tc, $C5 tc, $C6 tc, $C7 tc, 
$C8 tc, $C9 tc, $CA tc, $CB tc, $CC tc, $CD tc, $CE tc, $CF tc, 
$D0 tc, $D1 tc, $D2 tc, $D3 tc, $D4 tc, $D5 tc, $D6 tc, $D7 tc, 
$D8 tc, $D9 tc, $DA tc, $DB tc, $DC tc, $DD tc, $DE tc, $DF tc, 
$C0 tc, $C1 tc, $C2 tc, $C3 tc, $C4 tc, $C5 tc, $C6 tc, $C7 tc, 
$C8 tc, $C9 tc, $CA tc, $CB tc, $CC tc, $CD tc, $CE tc, $CF tc, 
$D0 tc, $D1 tc, $D2 tc, $D3 tc, $D4 tc, $D5 tc, $D6 tc, $D7 tc, 
$D8 tc, $D9 tc, $DA tc, $DB tc, $DC tc, $DD tc, $DE tc, $DF tc, 

tcreate lookups
  t' unshifted t>h cell+ @ t,
  t' ctrled t>h cell+ @ t,		( ctrl )
  t' shifted t>h cell+ @ t,		( shift )
  t' ctrled t>h cell+ @ t,		( ctrl+shift )
  t' alted t>h cell+ @ t,		( alt )
  t' ctrled t>h cell+ @ t,		( ctrl+alt )
  t' shiftalted t>h cell+ @ t,	( shift+alt )
  t' ctrled t>h cell+ @ t,		( ctrl+alt+shift )

\ The KIA interface consists of the KQSTAT register at
\ address $0100000000000000, and the KQDATA register at
\ address $0100000000000001.  Both are byte-wide registers.
\ 
\ The status register consists of four bits:
\	7 6 5 4 3 2 1 0
\	U N - - - - F E
\
\ E is set if the KIA queue is empty.  F is set if full.
\ N is set if the character code received is non-graphic.
\ U is set if the character code received is a key up
\ event.
\
\ The KQDATA register just contains the 8-bit scancode.
\
\ After reading KQDATA, the queue must be manually popped.
\ This is done by writing an arbitrary value back to KQDATA.

t: kia?		$0200000000000000 C@ 1 AND 1 XOR ;
t: scan		$0200000000000000 C@ $C0 AND 56 LSHIFT
		$0200000000000001 C@ OR ;
t: popq		DUP $0200000000000001 C! ;

\ ?kia is intended to have a similar interface as ?rx.

t: ?kia		kia? IF scan -1 popq ELSE 0 THEN ;

\ If you have a raw KIA scancode, then you should be
\ able to filter it through >ascii to compute the
\ corresponding plain, 7-bit ASCII code for the scan
\ code, if any exists at all.

tglobal shiftBits

t: clr		shiftBits @ SWAP NOT AND ;
t: set		shiftBits @ OR ;
t: !bits	OVER 0< IF clr ELSE set THEN shiftBits ! DROP ;
t: shift	1 OVER 7 AND LSHIFT !bits ;
t: ?shift	DUP $F8 AND $E0 = IF shift THEN DEPTH $FF2000 ! 0 ;
t: mirror	DUP 4 RSHIFT OR ;
t: table	shiftBits @ mirror 7 AND CELLS lookups + @ ;
t: lookup	table SWAP 255 AND + C@ -1 ;
t: ?chr		DUP 0< IF DROP 0 EXIT THEN lookup ;
t: >ascii	DUP 2* 0< IF ?shift ELSE ?chr THEN ;

t: ?rx		?kia IF >ascii ELSE 0 THEN ;

t: 0kia		0 shiftBits ! doLIT ?rx '?KEY ! ;

