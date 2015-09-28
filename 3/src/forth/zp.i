; Base address for console UART device.
zpUartBase			= 0

; The number of tests that the asrt.asm package should run.
zpNumTests			= zpUartBase + 8

; Pointer to the next entry in the test table to run.
zpTestPtr			= zpNumTests + 8

; Unit tests need linkage to dependencies.  This field points to a test-
; defined jump-table that tests can populate with their own specializations
; of dependencies needed by the software under test.
zpV				= zpTestPtr + 8

; Pointer to word body in the Forth dictionary.  Populated by a dictionary
; search.
zpWordBody			= zpV + 8

; Current numeric value from last number conversion.
zpValue				= zpWordBody + 8

; LEGACY: Older unit tests store their return address here.  Recommend NOT
; using this field for newer tests.  Use the stack instead.
zpTestPC			= zpValue + 8

; Offset to the next character to read in the source buffer.  Interpreter
; starts or resumes interpreting from this point.
zpScanIndex			= zpTestPC + 8

; The total line length of the source buffer.
zpLineLength			= zpScanIndex + 8

; Pointer to the source buffer itself.
zpLineBuffer			= zpLineLength + 8

; The numeric base to use when converting a number from text to binary.
zpBase				= zpLineBuffer + 8

; Pointer (not index!) into the source buffer of the currently lexed word.
zpWordStart			= zpBase + 8

; The length of the lexed word.
zpWordLength			= zpWordStart + 8

; Current error status.
zpError				= zpWordLength + 8

; Reserved for unit testing.
zpCalled			= zpError + 8

; Index into the current word (pointed at by zpWordStart) used for numeric
; conversion.
zpWordIndex			= zpCalled + 8

; Reserved for unit testing.
zpWordFound			= zpWordIndex + 8

; Pointer to bottom of return stack.
zpRP0				= zpWordFound + 8

; Pointer to bottom of data stack.
zpDP0				= zpRP0 + 8

; Lower bound for the return stack.
zpRPL				= zpDP0 + 8

; Lower bound for the data stack.
zpDPL				= zpRPL + 8

; True if negation needed when converting a number.
zpSign				= zpDPL + 8

; Padding.
zpReserved1			= zpSign + 1
zpReserved2			= zpReserved1 + 1
zpReserved3			= zpReserved2 + 1
zpReserved4			= zpReserved3 + 1
zpReserved5			= zpReserved4 + 1
zpReserved6			= zpReserved5 + 1
zpReserved7			= zpReserved6 + 1

; If exiting the emulator, this variable holds the HTIF command
; block.  Unused otherwise.
zpExitCB                        = zpReserved7 + 1

; Pointer to the most recently defined word.  Note that this is NOT
; the word currently being defined, if one exists.
zpContext			= zpExitCB + 8

