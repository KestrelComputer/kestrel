include sdb.fs

\ Wishbone bus-specific flags for various types of devices.
$8F CONSTANT WB_RAMROM ( little-endian, all widths )
$88 CONSTANT WB_GPIA2 ( little-endian, 64-bit access only )
$01 CONSTANT WB_KIA ( 8-bit access only )

\ Kestrel Computer Project vendor ID.  Chosen to be pseudo-
\ random with low probability of collision.
$C0C21E6D3B1EDF88 CONSTANT V_KESTREL

\ Kestrel-2 and Kestrel-3 devices.
1 CONSTANT D_MOTHERBOARD_E ( emulated motherboard )
2 CONSTANT D_S16X4_CPU	( 16-bit CPU used in Kestrel-2 )
3 CONSTANT D_E_RTS_CPU	( E Red Tail Subset CPU for Kestrel-3 )
4 CONSTANT D_REDTAIL_CPU ( RV64-compliant CPU for Kestrel-3 )
5 CONSTANT D_RAM	( generic RAM )
6 CONSTANT D_GPIA1	( 16-bit GPIA for Kestrel-2 )
7 CONSTANT D_GPIA2	( 64-bit GPIA for Kestrel-3 )
8 CONSTANT D_KIA	( KIA for Kestrel-2/-3 )
9 CONSTANT D_ROM	( generic ROM )

\ Kestrel-3 device classes.  These actually set the ABI
\ of a particular device.
1 CONSTANT C_RV64IS_CORE	( 64-bit RISC-V CPU )
2 CONSTANT C_RAM		( generic RAM )
3 CONSTANT C_GPIA2		( 64-bit GPIA-2 )
4 CONSTANT C_KIA_KBD		( 8-bit KIA-I or KIA-II )
5 CONSTANT C_KIA_MOUSE		( 8-bit KIA-I or KIA-II )
6 CONSTANT C_MGIA_FRAMEBUFFER	( framebuffer RAM )
7 CONSTANT C_SDB_CONFIG_ROM	( ROM containing SDB data )
8 CONSTANT C_BOOTSTRAP_ROM	( ROM containing boot code )

\ Kestrel-3 Emulator definition
B_WISHBONE interconnect(
0 -1 range
V_KESTREL D_MOTHERBOARD_E $00003000 version
$20160416 date
S" e-emulator" name

	C_RV64IS_CORE 0 0 0 device
	0 0 range
	V_KESTREL D_E_RTS_CPU 0 version
	$20160416 date
	S" cpu" name

	C_RAM 0 0 WB_RAMROM device
	$000000 $FEFFFF range
	V_KESTREL D_RAM 0 version
	$20160416 date
	S" ram" name

	C_MGIA_FRAMEBUFFER 0 1 WB_RAMROM device
	$FF0000 $FFFFFF range
	V_KESTREL D_RAM 0 version
	$20160416 date
	S" framebuffer" name

	C_GPIA2 0 0 WB_GPIA2 device
	$0100000000000000 $010000000000000F range
	V_KESTREL D_GPIA2 0 version
	$20160416 date
	S" gpia2" name

	C_KIA_KBD 0 0 WB_KIA device
	$0200000000000000 $0200000000000001 range
	V_KESTREL D_KIA 1 version
	$20160416 date
	S" kia-sdl" name

	C_SDB_CONFIG_ROM 0 0 WB_RAMROM device
	$0300000000000000 $03000000000001FF range
	V_KESTREL D_ROM 0 version
	$20160416 date
	S" sdb-config-rom" name

	C_BOOTSTRAP_ROM 0 0 WB_RAMROM device
	$FFFFFFFFFFF00000 $FFFFFFFFFFFFFFFF range
	V_KESTREL D_ROM 0 version
	$20160416 date
	S" boot-rom" name
)interconnect

save sdb.rom
bye
