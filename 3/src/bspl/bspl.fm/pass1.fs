\ This "Machine" Forth compiler exists in several different passes.
\ Pass 1 is just translation from textual Forth-like representation
\ into a symbolic form suitable for subsequent processing.
\ Eventually, the intermediate representation will map 1-to-1 to RISC-V
\ instruction sequences.  At this point, compilation is done, and we
\ just emit the generated source code for consumption by the assembler.

\ Number of elements in the compiler buffer.
1024 constant #buf

\ Size of the compiler buffer in bytes.
\ 
\ Each element holds one virtual instruction.
\ Unless otherwise documented, each virtual instruction has the following
\ layout in memory:
\ 
\ ...        8 7      0
\ +-----------+--------+
\ | parameter | opcode |
\ +-----------+--------+
1 cells constant /cell
#buf /cell * constant /buf

\ The compiler buffer workspace.
create buf
/buf allot

\ Reset buffer to known state.
: buf0		buf /buf $CC fill ;
buf0

\ We find our first virtual instruction at index fi.
\ 0 <= fi < #buf
variable fi

\ We place our next instruction at ni.
\ 0 <= ni <= #buf, implying fi < ni except at the start.
variable ni

: fi0		0 fi ! ;
: ni0		0 ni ! ;
fi0 ni0

: addr		@ cells buf + ;
: insn,		ni addr !  ni inc ;

\ The space between index 0 and fi are reserved for numeric constants.
\ Pushing a constant requires that we store this constant at index 0,
\ pushing literally everything up to ni up one cell.  This means we
\ also have to move fi and ni one cell up as well.
\ 
\ NOTE: This requires that program code refer to numeric literals through
\ a base pointer register, using negative offsets.  The pointer used for
\ this purpose is known as the "global pointer", or GP, register.
\ It's name derives from its use in the C programming language and similar
\ languages, where this register is used to refer to a module's global
\ variables.
: size		ni @ cells ;
: vacate	buf dup cell+ size move ;
: lit!		vacate buf ! fi inc ni inc ;

\ Pushing a literal allocates a register, allocates a literal slot, then loads
\ the register from a GP-relative location.  At this point, we assume some
\ magic instruction exists which lets us reference literals relative to the
\ first instruction in the routine.
: lit,		lit! fi @ negate 8 lshift 1 or insn, ;

\ For reasons of convenience, I'd like to define a Forth compiler "mode" that
\ lets me use (as close to) normal Forth words to target compile.  We'll start
\ with defining the colon compiler entry point.
\ 
\ :: is an escape for us, letting us use the host's : compiler even when target
\ compiling.  Be careful though; it can get confusing really fast!
\ 
\ target does *not* switch to a special compiler per se.  It simply inserts
\ a target-aware set of Forth words at the head of the search order, so that
\ target-specific words may be compiled into the compiler buffer.
\ 
\ host undoes whatever actions target performs, leaving you (hopefully!) in the
\ same state as just prior to invoking target.  As you might imagine, you must
\ ensure your search order is the same as whatever target set it as.
\ 
\ Because of their nature, we'll define : and ; at the end of the module.
: ::		: ;
: ;;		postpone ; ; immediate

wordlist constant target-wl

: target	get-order target-wl swap 1+ set-order ;
: host		get-order nip 1- set-order ;

\ Since the host Forth environment is technically interpreting word for word,
\ we must use parsing words to retrieve literals and emit literal load
\ instructions.
target definitions

:: d#		bl word count evaluate lit, ;;
:: h#		base @ hex d# base ! ;;

\ Once we have literals on the stack, we can use it to reference memory.
\ Forth only defines cell-wide and character-wide accessors.  The RISC-V
\ processor, however, has four accessor widths: byte, half-word, word, and
\ double-word.  I define all widths below using non-standard terms first,
\ then define the standard Forth accessors in those terms.

:: @8		8 insn, ;;
:: @16		9 insn, ;;
:: @32		10 insn, ;;
:: @64		11 insn, ;;
:: !8		12 insn, ;;
:: !16		13 insn, ;;
:: !32		14 insn, ;;
:: !64		15 insn, ;;

:: @		@64 ;;
:: !		!64 ;;

:: C@		@8 ;;
:: C!		!8 ;;

\ Once we have something on the stack, we can start to work with values.

:: noop		0 insn, ;;
:: +		2 insn, ;;
:: -		3 insn, ;;
:: and		4 insn, ;;
:: or		5 insn, ;;
:: xor		6 insn, ;;

\ Labels are psuedo-instructions which will be removed in later compiler
\ passes, but which enable structured programming constructs in the mean-time.
\ Note that label, leaves the label ID on the stack for later use.

host definitions

variable label
: label0	0 label ! ;
label0

: *label	label @ label inc ;
: label,	8 lshift 7 or insn, ;
: goto,		8 lshift 16 or insn, ;
: gotoz,	8 lshift 17 or insn, ;
: gotonz,	8 lshift $25 or insn, ;
: gotoge,	8 lshift $29 or insn, ;

: begin,	*label dup label, ;
: if,		*label dup gotoz, ;
: ifz,		*label dup gotonz, ;
: -if,		*label dup gotoge, ;
: else,		*label dup goto, swap label, ;
: then,		label, ;

: while,	if, swap ;
: repeat,	goto, then, ;
: until,	gotoz, ;

target definitions

:: begin	begin, ;;
:: again	goto, ;;

:: if		if, ;;
:: 0=if		ifz, ;;
:: -if		-if, ;;
:: else		else, ;;
:: then		then, ;;

:: while	while, ;;
:: repeat	repeat, ;;
:: until	until, ;;

\ We reference other subroutines by their offset from the dictionary image.
\ The RISC-V processor's JAL instruction provides us with 21 bits of signed
\ displacement range (expressed in 20 bits).  This means that we can call
\ any subroutine we define provided it's less than 1MB away.
\ 
\ To provide a simpler mental model than a sliding window, we just _define_
\ a dictionary image to never exceed 1MB of space.  If you need more room
\ than this, use dynamic memory management techniques (e.g., ALLOCATE and
\ FREE in ANS Forth).  @ and ! can still access memory anywhere in the
\ address space.  Keep the code space compact.  1MB is positively ginormous
\ by Forth standards, so it'll be a long, long time before we need to
\ exceed this limit for any reason what-so-ever.

host definitions

: call,		8 lshift 18 or insn, ;
: rfs,		19 insn, ;

target definitions

:: exit		rfs, ;;

\ With a RISC processor, the evaluation stack must be an ephemeral construct.
\ It exists solely in the mind of the compiler.  Thus, the data and return
\ stacks must reside in memory, since the CPU offers only registers to work
\ with.
\ 
\ Since all RISC processors are load/store architectures by definition, we
\ need to provide accessors for the data and stacks.  >R R> and R@ are already
\ familiar to the programmer.  However, we also introduce >D D> and D@ as
\ well to provide similar access to the Forth data stack.
\ 
\ Note that D@, R@, D!, and R! take indices into the stack, permitting random
\ access into these structures.

host definitions

: >r,		20 insn, ;
: r>,		21 insn, ;
: r@,		8 lshift 22 or insn, ;
: r!,		8 lshift 23 or insn, ;
: >d,		24 insn, ;
: d>,		25 insn, ;
: d@,		8 lshift 26 or insn, ;
: d!,		8 lshift 27 or insn, ;

target definitions

:: >r		>r, ;;
:: r>		r>, ;;
:: r@		r@, ;;
:: r!		r!, ;;
:: >d		>d, ;;
:: d>		d>, ;;
:: d@		d@, ;;
:: d!		d!, ;;

\ The normal Forth stack accessors that you're used to now apply only to the
\ evaluation stack, NOT to the data stack.  (Sorry!)  Any other approach will
\ just add too much runtime overhead and will not yield good runtime
\ performance.

host definitions

: dup,		28 insn, ;
: over,		29 insn, ;
: drop,		30 insn, ;
: nip,		31 insn, ;
: rot,		32 insn, ;
: swap,		33 insn, ;

target definitions

:: dup		dup, ;;
:: over		over, ;;
:: drop		drop, ;;
:: nip		nip, ;;
:: rot		rot, ;;
:: swap		swap, ;;

\ Logical shifts

host definitions

: 2*,		$26 insn, ;
: u2/,		$27 insn, ;
: 2/,		$28 insn, ;

target definitions

:: 2*		2*, ;;
:: u2/		u2/, ;;
:: 2/		2/, ;;

\ Variables are reserved relative to a Global Variables Pointer, or GVP
\ register.  This grants the program up to 4KB of storage for uninitialized
\ variables.  Offsets range from -2048 to 2047 inclusive, giving enough
\ storage space for 512 dword-sized variables.

host definitions

variable gvpofs
: gvpofs0	-2048 gvpofs ! ;

: gvpea,	8 lshift $2A or insn, ;
: byte:		create gvpofs @ , gvpofs inc does> @ gvpea, ;
: hword:	create gvpofs @ 1 + -2 and dup , 2 + gvpofs ! does> @ gvpea, ;
: word:		create gvpofs @ 3 + -4 and dup , 4 + gvpofs ! does> @ gvpea, ;
: dword:	create gvpofs @ 7 + -8 and dup , 8 + gvpofs ! does> @ gvpea, ;
: buffer:	create gvpofs @ 7 + -8 and dup , + gvpofs ! does> @ gvpea, ;

target definitions

:: byte		byte: ;;
:: hword	hword: ;;
:: word		word: ;;
:: dword	dword: ;;
:: buffer	buffer: ;;

:: bytes	;;
:: hwords	bytes 2* ;;
:: words	hwords 2* ;;
:: dwords	words 2* ;;

\ Strings are constants, and so reside along-side the code.
\ When you invoke the name of a string, its length and address are put on the stack,
\ in that order.  This facilitates ANS-like string argument passing conventions with
\ a minimum of keywords: aString >D >D instead of aString swap >d >d.

host definitions

: string,	34 word count dictate 8 lshift $2B or insn, ;

target definitions

:: S"		string, ;; ( " -- to fix editor coloring )

\ Numeric constants are frequently used, so we provide support for them here.

host definitions

: const,	create , does> @ lit, ;

target definitions

:: const	const, ;;

host definitions

