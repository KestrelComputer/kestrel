\ Kestrel Forth V1.0
\ Copyright 2016 Samuel A. Falvo II
\ 
\ This Source Code Form is subject to the terms of the
\ Mozilla Public License, v. 2.0.  If a copy of the MPL
\ was not distributed with this file, You can obtain one
\ at https://mozilla.org/MPL/2.0/.
\ 
\ This file contains the eForth kernel, as documented by
\ Dr. C. H. Ting and Juergen Pintaske, as of 2013-Apr-20.
\ See http://www.exemark.com/FORTH/eForthOverviewv5.pdf


\ ?next decrements the top of return stack.  If it falls
\ BELOW zero (e.g., goes negative), then the branch back
\ to a corresponding FOR-loop's entry is NOT taken.
tcode ?next
	0 rsp x9 ld,
	-1 x9 x9 addi,
	16 x9 x0 blt,
	0 rsp x9 sd,
	0 ip ip ld,
	next,
	8 rsp rsp addi,
	8 ip ip addi,
	next,
tend-code

tcode (dofor)
	0 dsp x9 ld,
	8 dsp dsp addi,
	-1 x9 x9 addi,
	-8 rsp rsp addi,
	0 rsp x9 sd,
	next,
tend-code

\ ?branch causes a control flow change if the TOS is zero.
\ This primitive consumes the stack item.
tcode ?branch
	0 dsp x9 ld,
	8 dsp dsp addi,
	12 x9 x0 bne,
	0 ip ip ld,
	next,
	8 ip ip addi,
	next,
tend-code

\ branch causes an unconditional control flow change.
tcode branch
	0 ip ip ld,
	next,
tend-code

\ EXECUTE causes an unconditional control flow change.
\ The execution token is taken from the top of the stack
\ instead of inline in the program thread.  After the
\ specified word has completed, execution resumes
\ immediately after EXECUTE.
tcode EXECUTE	\ TODO test
	0 dsp w ld,
	8 dsp dsp addi,
	0 w x9 ld,
	0 x9 x0 jalr,
tend-code

\ ! stores a cell at an arbitrary location in memory.
\ @ recalls a cell from any arbitrary location in memory.
\ Addresses must be cell-aligned.
\ 
\ W! and W@ are as ! and @, except instead of cells, the
\ unit is a 32-bit wide word.  Addresses must have word-
\ alignment.
\ 
\ H! and H@ are as W! and W@, except instead of words, the
\ unit is a 16-bit half-word.  Addresses must have half-
\ word alignment.
\ 
\ C! and C@ are as H! and H@, but for 8-bit bytes.  Addresses
\ need not have any particular alignment.
\ 
\ s@, Ws@, Hs@, and Cs@ are signed equivalents to
\ @, W@, H@, and C@.
tcode !
	0 dsp x8 ld,
	8 dsp x9 ld,
	0 x8 x9 sd,
	16 dsp dsp addi,
	next,
tend-code

tcode W!
	0 dsp x8 ld,
	8 dsp x9 ld,
	0 x8 x9 sw,
	16 dsp dsp addi,
	next,
tend-code

tcode H!
	0 dsp x8 ld,
	8 dsp x9 ld,
	0 x8 x9 sh,
	16 dsp dsp addi,
	next,
tend-code

tcode C!
	0 dsp x8 ld,
	8 dsp x9 ld,
	0 x8 x9 sb,
	16 dsp dsp addi,
	next,
tend-code

tcode @
	0 dsp x8 ld,
	0 x8 x8 ldu,
	0 dsp x8 sd,
	next,
tend-code

tcode W@
	0 dsp x8 ld,
	0 x8 x8 lwu,
	0 dsp x8 sd,
	next,
tend-code

tcode H@
	0 dsp x8 ld,
	0 x8 x8 lhu,
	0 dsp x8 sd,
	next,
tend-code

tcode C@
	0 dsp x8 ld,
	0 x8 x8 lbu,
	0 dsp x8 sd,
	next,
tend-code

tcode s@
	0 dsp x8 ld,
	0 x8 x8 ld,
	0 dsp x8 sd,
	next,
tend-code

tcode Ws@
	0 dsp x8 ld,
	0 x8 x8 lw,
	0 dsp x8 sd,
	next,
tend-code

tcode Hs@
	0 dsp x8 ld,
	0 x8 x8 lh,
	0 dsp x8 sd,
	next,
tend-code

tcode Cs@
	0 dsp x8 ld,
	0 x8 x8 lb,
	0 dsp x8 sd,
	next,
tend-code

\ RP@ and RP! retrieve and reset the current return stack
\ pointer.

tcode RP@	\ TODO test
	-8 dsp dsp addi,
	0 dsp rsp sd,
	next,
tend-code

tcode RP!	\ TODO test
	0 dsp rsp ld,
	8 dsp dsp addi,
	next,
tend-code

\ R> pops a cell from the return stack, and pushes it onto
\ the data stack.  >R does the opposite.  R@ retrieves the
\ current top of the return stack.  R@ is also known as I,
\ for applications working with DO...LOOP constructs.

tcode R>	\ TODO test
	0 rsp x8 ld,
	8 rsp rsp addi,
	-8 dsp dsp addi,
	0 dsp x8 sd,
	next,
tend-code

tcode >R	\ TODO test
	0 dsp x8 ld,
	8 dsp dsp addi,
	-8 rsp rsp addi,
	0 rsp x8 sd,
	next,
tend-code

tcode R@	\ TODO test
	0 rsp x8 ld,
	-8 dsp dsp addi,
	0 dsp x8 sd,
	next,
tend-code

\ SP@ and SP! retrieve and reset the data stack pointer.
\ BE EXTREMELY CAREFUL WHEN USING SP!, AS THIS CAN LEAD
\ TO UNPREDICTABLE BEHAVIOR VERY EASILY.  Stack pointers
\ MUST be cell-aligned.
\ 
\ Note that SP@ retrieves the stack pointer BEFORE pushing
\ the stack pointer's current value.  In other words,
\ SP@ SP! and SP@ DROP are semantically equivalent.
tcode SP@	\ TODO test
	0 dsp x8 addi,
	-8 dsp dsp addi,
	0 dsp x8 sd,
	next,
tend-code

tcode SP!	\ TODO test
	0 dsp dsp ld,
	next,
tend-code

\ DROP irreparably removes the top of data stack.
\ DUP duplicates the top of the data stack, so that two
\ copies of the datum now exist.  SWAP exchanges the
\ positions of the two top-most stack items.  OVER
\ duplicates the 2nd top of data stack.
tcode DROP
	8 dsp dsp addi,
	next,
tend-code

tcode DUP
	0 dsp x8 ld,
	-8 dsp dsp addi,
	0 dsp x8 sd,
	next,
tend-code

tcode SWAP	\ TODO test
	0 dsp x8 ld,
	8 dsp x9 ld,
	0 dsp x9 sd,
	8 dsp x8 sd,
	next,
tend-code

tcode OVER
	8 dsp x8 ld,
	-8 dsp dsp addi,
	0 dsp x8 sd,
	next,
tend-code

\ 0< compares top of data stack to zero; if less than zero,
\ -1 is pushed as the predicate result.
tcode 0<
	0 dsp x8 ld,
	16 x8 x0 blt,
	0 x0 x8 addi,
	0 dsp x8 sd,
	next,
	-1 x0 x8 addi,
	0 dsp x8 sd,
	next,
tend-code

\ AND, OR, XOR all consume two parameters, and pushes the
\ result of applying the eponymously named function.
tcode AND	\ TODO test
	0 dsp x8 ld,
	8 dsp x9 ld,
	x8 x9 x8 and,
	8 dsp x8 sd,
	8 dsp dsp addi,
	next,
tend-code

tcode XOR	\ TODO test
	0 dsp x8 ld,
	8 dsp x9 ld,
	x8 x9 x8 xor,
	8 dsp x8 sd,
	8 dsp dsp addi,
	next,
tend-code

tcode OR	\ TODO test
	0 dsp x8 ld,
	8 dsp x9 ld,
	x8 x9 x8 or,
	8 dsp x8 sd,
	8 dsp dsp addi,
	next,
tend-code

\ BIC will clear bits.  For each '1' bit in the top of stack,
\ the corresponding bit in the 2nd top of stack is guaranteed to
\ be cleared.  Only the final result will remain.
tcode BIC	\ TODO test
	0 dsp x8 ld,
	8 dsp x9 ld,
	-1 x9 x9 xori,
	x8 x9 x8 and,
	8 dsp x8 sd,
	8 dsp dsp addi,
	next,
tend-code

\ UM+ adds the two top-most cells, leaving the sum and a carry
\ flag, in that order.  NOTE: unlike most boolean values, the
\ carry flag assumes 1 for true value, making it more useful
\ in multi-precision integer arithmetic.
tcode UM+
	0 x0 w addi,	( carry flag initially zero )
	0 dsp x8 ld,
	8 dsp x9 ld,
	x8 x9 x8 add,
	8 x8 x9 bgeu,	( x8 < x9 iff carry happened )
	1 x0 w addi,	( set carry flag true if so )
	8 dsp x8 sd,
	0 dsp w sd,
	next,
tend-code

\ IF, ELSE, THEN performs conditional execution of blocks
\ of code.  BEGIN/AGAIN is used to construct infinite loops.
\ BEGIN/WHILE/REPEAT and BEGIN/UNTIL are used to construct
\ indefinite loops.

\ tested
: ~IF		[t'] ?branch t, there 0 t, ;
: ~THEN		there swap t! ;
: ~ELSE		[t'] branch t, there 0 t, swap ~THEN ;
: ~BEGIN	there ;
: ~WHILE	~IF swap ;
: ~REPEAT	[t'] branch t, t, ~THEN ;

\ TODO test
: ~AGAIN	[t'] branch t, t, ;
: ~UNTIL	[t'] ?branch t, t, ;
: ~FOR		[t'] (dofor) t, there ;
: ~NEXT		[t'] ?next t, t, ;

\ PANIC will stop all program execution until the machine
\ is physically reset.  This includes interrupt handlers.
tcode PANIC
	0 0 jal,
tend-code

