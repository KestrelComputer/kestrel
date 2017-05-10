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

\ We use a table of procedures to dispatch to handlers for each instruction
\ encountered in the compiler buffer.  For most instructions, we don't need
\ to do anything, but we still need a procedure to dispatch to.  Hence why
\ we have an empty procedure here.
: ignore	;

\ When we encounter a lit pseudo-instruction, we need to record the fact
\ that we injected an lgp psuedo-instruction to prevent doing this for
\ every lit instruction we come across.  inserted e. {True, False}
variable inserted

\ When we encounter a lit psuedo-instruction AND we have not yet inserted
\ an LGP pseudo-instruction, we must insert the LGP instruction in front
\ of the LIT instruction.
: addr		ci @ cells buf + ;
: size		ni @ ci @ - cells ;
: vacate	addr dup cell+ size move ;
: insert	inserted on vacate $22 addr ! ni inc ;

\ When we encounter a CALL instruction, we must assume the value of GP
\ has been destroyed by the called subroutine.
: reset		inserted off ;

\ Here's that table of procedures I was talking about above.
create procedures
' ignore ,	( neither lit, nor call, or already inserted )
' insert ,	( lit and not inserted yet )
' reset ,	( call instruction found )

\ Look at the current instruction, and decide how best to handle it.
\ Then, execute on that plan.
: insn		addr @ ;
: opcode	insn 255 and ;
: insert?	opcode $01 = inserted @ 0= and ;
: call?		opcode $12 = ;
: label?  opcode $07 = ;
: classify	insert? 1 and call? label? or 2 and or ;
: plan		classify cells procedures + @ ;
: ?insert	plan execute ;

\ Scan the program, and insert an LGP where it needs to go.
\ This requires that we adjust the ni variable for each insertion.
: lgp0		begin ci @ ni @ >= if exit then ?insert 1 ci +! again ;
: lgp		inserted off fi @ ci ! lgp0 ;

