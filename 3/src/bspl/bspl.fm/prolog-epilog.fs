\ This file looks for CALL instructions.  If at least one is found, we need to
\ insert a prolog into the compile buffer.
\ 
\ If we had to insert a prolog, then we need to scan for RFS pseudo-
\ instructions.  For each one found, we need to insert an epilog in front of it.
\ 
\ This ensures the correct state of the return stack for non-leaf procedures
\ (e.g., procedures that invoke sub-procedures).

\ Requires you to have loaded lgp.fs first, as we use the following words from
\ that package:
\ 
\ inserted ( - a ) flag indicating whether or not we inserted our prolog.

: addr		fi @ cells buf + ;
: size		ni @ fi @ - cells ;
: vacate	addr dup cell+ size move ni inc ;
: insert	vacate $23 addr ! inserted on ;
: ?prolog	opcode $12 = if insert then ;
: prolog0	begin ci @ ni @ >= inserted @ or if exit then ?prolog ci inc again ;
: prolog	fi @ ci ! inserted off prolog0 ;

: addr		ci @ cells buf + ;
: size		ni @ ci @ - cells ;
: vacate	addr dup cell+ size move  ni inc ;
: insert	vacate $24 addr ! ci inc ;
: ?epilog	opcode $13 = if insert then ;
: epilogs0	begin ci @ ni @ >= if exit then ?epilog ci inc again ;
: epilogs	inserted @ if fi @ ci ! epilogs0 then ;
