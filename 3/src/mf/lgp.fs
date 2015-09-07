\ The LGP pass scans through the compiler buffer, looking for literal load
\ pseudo-instructions.  If found, it will insert an LGP psuedo-instruction
\ to make sure the GP register holds an appropriate value.
\ 
\ The LGP instruction need only be introduced once, namely prior to the first
\ literal load instruction.  Thereafter, the same GP value can be reused for
\ subsequent literal loads.  Where this assumption fails is after a CALL
\ instruction.  After a subroutine returns, it could well have used a literal
\ of its own, thus requiring its own GP value.  So, we must assume GP is
\ garbage upon return from a subroutine.  Therefore, we introduce an LGP
\ instruction not just in front of the first literal load instruction, but
\ also in front of the first literal load instruction that follows a CALL
\ instruction.

\ ci refers to the current instruction.  fi <= ci < ni.
variable ci

\ Most of the time, we won't have to do anything.
: ignore	;

\ When we encounter a lit pseudo-instruction, we need to record the fact
\ that we injected an lgp psuedo-instruction to prevent doing this for
\ every lit instruction we come across.  inserted e. {True, False}
variable inserted

\ The address of the current instruction.
: addr		ci @ cells buf + ;

\ The size of the program, starting from the current instruction.
: size		ni @ ci @ - cells ;

\ Insert an LGP pseudo-instruction.
: vacate	addr dup cell+ size move ;
: insert	inserted on vacate $22 addr ! ni inc ;

\ Resets the state of inserted since we cannot assume the value of GP
\ is correct after we return from a subroutine.
: reset		inserted off ;

\ A table of how to work with the current instruction given the current
\ state of inserted.
create procedures
' ignore ,	( neither lit, nor call, or already inserted )
' insert ,	( lit and not inserted yet )
' reset ,	( call instruction found )

\ The current instruction.
: insn		addr @ ;

\ The current opcode.
: opcode	insn 255 and ;

\ Decide what procedure to execute to properly handle the current instruction.
: insert?	opcode $01 = inserted @ 0= and ;
: call?		opcode $12 = ;
: classify	insert? 1 and call? 2 and or ;
: plan		classify cells procedures + @ ;

\ Optionally insert an LGP psuedo-instruction into the current program.
: ?insert	plan execute ;

\ Scan the program, and insert an LGP where it needs to go.
\ This requires that we adjust the ni variable for each insertion.
: lgp0		begin ci @ ni @ >= if exit then ?insert 1 ci +! again ;
: lgp		inserted off fi @ ci ! lgp0 ;

