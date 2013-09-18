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

\ open attempts to open the file named in the filnamptr/filnamlen variables.
\ Note that all filenames MUST include the volume or device on which to locate
\ the file.  STS lacks any concept of a "process" in the Unix or Windows sense,
\ and thus lacks the concept of a current directory or current device.
\ 
\ This procedure returns the file's stream control block in the filscb variable,
\ with rsn set to 0 if successful.  Otherwise, filscb is undefined, and rsn
\ will be set accordingly.

:, open
	volsecbuf @, 0=
	if,	0 #, filscb !,  EVOLUME rsn !,  exit,
	then,

	fnddevnam
	rsn @,
	if,	0 #, filscb !,  exit,
	then,

	devnamlen @, 0=
	if,	0 #, filscb !,  ENOTFOUND rsn !,  exit,
	then,

	filnamlen @, 0=
	if,	0 #, filscb !,  ENOTFOUND rsn !,  exit,
	then,

	devnamptr @, strptr1 !,  devnamlen @, strlen1 !,  "SYS" 1 #, +, strptr2 !,  3 #, strlen2 !,  compare
	strres @,
	if,	devnamptr @, strptr1 !, devnamlen @, strlen1 !,   volnamptr @, strptr2 !, volnamlen @, strlen2 !,  compare
		strres @,
		if,	0 #, filscb !,  ENOTFOUND rsn !,  exit,
		then,
	then,

	-1 #, filscb !,  0 #, rsn !, ;,

