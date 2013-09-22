\ These words provide a crude filing system implementation.  Due to memory
\ constraints, we cannot separate filing system from actual DOS implementation.
\ Thus, when providing a filename like SYS:foo or WorkDisk:bar, no actual handler
\ dispatching happens.  Only two logical devices exist as of this writing: SYS:
\ and the name of the boot disk.  STS does not support swapping volumes either.
\ Maybe with time, and with extra memory support, I can get a more robust filing
\ system implementation for STS off the ground.

\ devnamptr/devnamlen point to the application's desired logical or physical
\ device name.  This is everything to the left of the filename's first colon.

int, devnamptr
int, devnamlen

\ filnamptr/filnamlen point to the filename currently of interest to the calling
\ program.  These values are adjusted to point to just the filename part as part
\ of calling open.  As inputs to open, they must point to a device:filename-formatted
\ filename.

int, filnamptr
int, filnamlen

\ filscb points to the open stream control block if open succeeds.  Undefined
\ otherwise.

int, filscb

\ mount attempts to read the volume-related information from the storage device
\ and validates it to make sure we can use it as a storage volume.
\ It returns 0 in rsn if everything is OK; otherwise, some reasonable error code
\ is returned.

int, volsecbuf
int, volnamptr
int, volnamlen
int, voldirsta
int, -voldirend

create, "$DIR"
	C", $DIR"

create, "SYS"
	C", SYS"

:, mount
	512 #, memsiz !,
	getmem
	rsn @, if, exit, then,

	memptr @, volsecbuf !,
	memptr @, devbufptr !,
	16 #, devsec !,
	devget
	rsn @,
	if,	0 #, volsecbuf !,
		relmem  exit,
	then,

	memptr @, strptr1 !,
	"$DIR" strptr2 !,
	strdif
	strres @,
	if,	0 #, volsecbuf !,
		relmem exit,
	then,

	memptr @, 64 #, +, c@, -48 #, +, $8000 #, and, $8000 #, xor,
	if,	0 #, volsecbuf !,
		relmem exit,
	then,

	memptr @, 112 #, +, c@, dirtype_volumelabel xor,
	if,	0 #, volsecbuf !,
		relmem exit,
	then,

	volsecbuf @, 64 #, +, c@, volnamlen !,
	volsecbuf @, 65 #, +, volnamptr !,
	volsecbuf @, dirt1_starts +, @, voldirsta !,
	volsecbuf @, dirt1_ends +, @, -1 #, xor, 1 #, +, -voldirend !,
	;,

\ fnddevnam splits out the device name (everything to the left of the first colon)
\ from the rest of the filename, and updates the devnam* and filnam* variables
\ accordingly.

:, fnddevnam
	0 #, devnamlen !,
	begin,	devnamlen @, filnamlen @, xor, 0=
		if,	ENAME rsn !,  exit,
		then,
		filnamptr @, devnamlen @, +, c@, $3A #, xor, 0=
		if,	filnamptr @, devnamptr !,
			devnamlen @, 1 #, +, filnamptr @, +, filnamptr !,
			devnamlen @, 1 #, +, -1 #, xor, 1 #, +, filnamlen @, +, filnamlen !,
			0 #, rsn !,  exit,
		then,
		devnamlen @, 1 #, +, devnamlen !,
	again, ;,

int, ndirents
int, dirptr

\ Read a sector into an SCB's buffer.  Update the SCB's sector field, then call rdsec
\ to make sure the SCB's buffer is synchronized with the sector field.  Relies upon
\ devget, so see devget for more information.

:, rdsec
	filscb @, scb_sector +, @, devsec !,
	filscb @, scb_buffer +, @, devbufptr !,
	devget ;,

\ fndfil performs a directory scan for the volume.  If it cannot be found, rsn
\ indicates why, and filsta and filend are undefined.  Otherwise, rsn is zero, and
\ filsta indicates the file's first sector, and filend indicates the last sector.
\ Note that filsta <= filend.

int, filsta
int, filend

:, fndfil
	voldirsta @, filscb @, scb_sector +, !,
	begin,	filscb @, scb_sector +, @,  -voldirend @, +, -1 #, +, $8000 #, and,
		( while filscb.sector < [voldirend+1] )
	while,	rdsec
		rsn @,
		if,	exit,
		then,

		8 #, ndirents !,	( 8 dirents per 512-byte sector )
		filscb @, scb_buffer +, @, dirptr !,
		begin,	ndirents @,
		while,	dirptr @, c@, filnamlen @, xor, 0=
			if,	dirptr @, dir_type +, c@, dirtype_file xor, 0=
				if,	dirptr @, 1 #, +, strptr1 !,
					dirptr @, c@, strlen1 !,
					filnamptr @, strptr2 !,
					filnamlen @, strlen2 !,
					compare
					strres @, 0=
					if,	dirptr @, dirt1_starts +, @, filsta !,
						dirptr @, dirt1_ends +, @, filend !,
						0 #, rsn !,
						exit,
					then,
				then,
			then,
			dirptr @, 64 #, +, dirptr !,
			ndirents @, -1 #, +, ndirents !,
		repeat,
		filscb @, scb_sector +, @, 1 #, +, filscb @, scb_sector +, !,
	repeat,
	ENOTFOUND rsn !, ;,

\ open attempts to open the file named in the filnamptr/filnamlen variables.
\ Note that all filenames MUST include the volume or device on which to locate
\ the file.  STS lacks any concept of a "process" in the Unix or Windows sense,
\ and thus lacks the concept of a current directory or current device.
\ 
\ This procedure returns the file's stream control block in the filscb variable,
\ with rsn set to 0 if successful.  Otherwise, filscb is undefined, and rsn
\ will be set accordingly.

:, open
	0 #, filscb !,  0 #, rsn !,

	volsecbuf @, 0=
	if,	EVOLUME rsn !,  exit,
	then,

	fnddevnam
	rsn @,
	if,	exit,
	then,

	devnamlen @, 0=
	if,	ENOTFOUND rsn !,  exit,
	then,

	filnamlen @, 0=
	if,	ENOTFOUND rsn !,  exit,
	then,

	devnamptr @, strptr1 !,  devnamlen @, strlen1 !,  "SYS" 1 #, +, strptr2 !,  3 #, strlen2 !,  compare
	strres @,
	if,	devnamptr @, strptr1 !, devnamlen @, strlen1 !,   volnamptr @, strptr2 !, volnamlen @, strlen2 !,  compare
		strres @,
		if,	ENOTFOUND rsn !,  exit,
		then,
	then,


	/scb 512 #, +, memsiz !, getmem
	rsn @,
	if,	exit,
	then,

	memptr @, filscb !,
	filscb @, /scb +, filscb @, scb_buffer +, !,

	fndfil
	rsn @,
	if,	relmem   0 #, filscb !,   exit,
	then,
	filsta @,  filscb @, scb_starts +, !,
	filend @,  filscb @, scb_ends +, !,
	0 #, filscb @, scb_index +, !,

	filsta @,  filscb @, scb_sector +, @, xor,
	if,	filsta @,  filscb @, scb_sector +, !,
		rdsec
		rsn @,
		if,	relmem  0 #, filscb !,  exit,
		then,
	then, ;,

\ close will free resources consumed by open.  NOTE: This filesystem is
\ read-only at this time.  Thus, no buffers can be dirty, and so we can simply
\ just free memory without having to write anything back.  However, don't
\ depend on this behavior.  Assume that the filesystem can go read/write with
\ any future version of STS.
\ 
\ The scb to close should be in the filscb variable,
\ This function currently doesn't return anything, but for future compatibility,
\ it sets rsn to 0.

:, close
	filscb @, memptr !,  relmem ;,


\ read will transfer up to inplen bytes of data from the file referenced by the
\ inpscb variable, into a buffer pointed to by inpbuf.  Upon completion, inpcnt
\ indicates how many bytes were actually transferred, and rsn indicates any reason
\ for stopping prematurely, if any.  Note that, except for inpscb, all input
\ variables are altered, and will need to be reset for the next call to read.

int, inpcnt
int, inpscb
int, inpbuf
int, inplen

int, (inplen)
int, (inpcnt)

:, (read)
	inpscb @, scb_index +, @,  512 #, xor, 0=
	if,	inpscb @, scb_sector +, @, inpscb @, scb_ends +, @, xor,
		if,	inpscb @, scb_sector +, @, 1 #, +, inpscb @, scb_sector +, !,
			inpscb @, filscb !,  rdsec
			rsn @,
			if,	inpscb @, scb_sector +, @, -1 #, +, inpscb @, scb_sector +, !,
				0 #, (inpcnt) !,
				exit,
			then,
			0 #, inpscb @, scb_index +, !,
			again,
		else,	EEOF rsn !,  0 #, (inpcnt) !,  exit,
		then,
	then,

	inpscb @, scb_index +, @, (inplen) @, +,  -512 #, +, $8000 #, and,
	if,	inpscb @, scb_index +, @, (inplen) @, +, (inplen) !,
	else,	512 #, (inplen) !,
	then,
	inpscb @, scb_index +, @, -1 #, xor, 1 #, +, (inplen) @, +, (inplen) !,

	inpscb @, scb_buffer +, @,  inpscb @, scb_index +, @,  +,  strptr1 !,
	inpbuf @, strptr2 !,
	(inplen) @, strlen1 !,
	movmem
	inpscb @, scb_index +, @, (inplen) @, +, inpscb @, scb_index +, !,
	(inplen) @, (inpcnt) !,
	0 #, rsn !,  ;,

:, read
	0 #, inpcnt !,  0 #, rsn !,
	begin,	rsn @, 0=  inplen @, and,
	while,	inplen @, (inplen) !, (read)
		(inpcnt) @, inpbuf @, +, inpbuf !,
		(inpcnt) @, -1 #, xor, 1 #, +,  inplen @, +, inplen !,
		(inpcnt) @, inpcnt @, +, inpcnt !,
	repeat,
	rsn @, EEOF xor, 0=
	if,	0 #, rsn !,
	then,
;,

