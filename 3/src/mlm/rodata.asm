\ BIOS Read-Only Data structure goes here.

	$0F000000.00000000 D,	( UART base )
	$01000000.00001000 D,	( Cold-boot SP initial value )
	$01000000.00000000 D,	( BIOS Control Block at start of RAM )

-> banner
	S" MLM/K3 V1" ASCII, 10 B, 0 B,
-> banner_end
-> crash_msg
  S" For some reason, the program crashes beyond this point, still not" ascii, 10 b,
  S" quite sure why.  So, for now, I deliberately deadlock here.  Sorry!" ascii, 10 b,
  S" The bug seems to be in bios_getline based on principle of elimination." ascii, 10 b, 0 b,

banner_end banner - CONSTANT banner_length

