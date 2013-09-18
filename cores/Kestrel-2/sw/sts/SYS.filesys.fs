\ These words provide a crude filing system implementation.  Due to memory
\ constraints, we cannot separate filing system from actual DOS implementation.
\ Thus, when providing a filename like SYS:foo or WorkDisk:bar, no actual handler
\ dispatching happens.  Only two logical devices exist as of this writing: SYS:
\ and the name of the boot disk.  STS does not support swapping volumes either.
\ Maybe with time, and with extra memory support, I can get a more robust filing
\ system implementation for STS off the ground.

\ mount attempts to read the volume-related information from the storage device
\ and validates it to make sure we can use it as a storage volume.
\ It returns 0 in rsn if everything is OK; otherwise, some reasonable error code
\ is returned.

int, volsecbuf

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

	memptr @, 0 #, +, @, $2404 #, xor,
	if,	0 #, volsecbuf !,
		relmem exit,
	then,
	memptr @, 2 #, +, @, $4944 #, xor,
	if,	0 #, volsecbuf !,
		relmem exit,
	then,
	memptr @, 4 #, +, c@, $52 #, xor,
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
	;,

