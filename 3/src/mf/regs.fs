\ This file's job is to assign registers to ephemeral stack positions.
\ We walk through the compiler buffer, looking for higher-level operations.
\ We then replace them with RISCy equivalents, this time encoding register
\ assignments.
\ 
\ Our stack starts with register X16, and continues up to and including X31.
\ This gives us a 16-deep ephemeral stack to play with, though honestly,
\ you'll probably rarely use more than 6 elements for any given computation
\ (based on my experience with the S16X4 in the Kestrel-2).
\ 
\ We need to reset the state of the registers on every basic boundary we
\ detect.  For example, if we hit a label, there's a high probability that
\ control will flow into the label from a different part of the program.
\ The state of the registers from one flow versus another flow will be
\ completely unknown; thus, we assume the worst (total destruction), and
\ reset the state the of ephemeral stack to default conditions.
\ This also must happen for CALLs as well, since control flow will return
\ after the subroutine has completed, and it will have destroyed registers.
\ 
\ This means, in no uncertain terms, that *ALL* ephemeral stack items must
\ either be don't-cares or be persisted into memory somehow prior to ANY
\ construct which introduces a new basic block.
\ 
\ Here's an illustration why.  Suppose we didn't reset the stack automatically
\ with each basic block boundary:
\ 
\	d# 1 d# 2 if
\	    subroutine
\	else
\	    d# 3
\	then
\ 
\ Forget what the value of the top of stack is, _where_ is the top of stack
\ after "then"?  If you follow the consequent, the TOS will be in X17.  If
\ you follow the alternate, the TOS will be in X18.
\ 
\ With ephemeral stack resets at each basic boundary, the TOS will not exist
\ after the then.  This is because the ephemeral stack will be empty at the
\ start of both the alternate and the consequent, AND it will be empty again
\ after the then statement.  Unlike normal Forth, this Machine Forth dialect
\ demands that if-else-then be a procedural _statement_, not an _expression_.
\ 
\ From a Forth programming perspective, this is rather inconvenient.
\ To preserve the desired behavior, you'll need to use words like >D or >R
\ to preserve values onto one of the in-memory stacks explicitly.

\ Allocates a new register for use.
\ Read something like this: *reg == POOF! A register!
variable regmask
: regmask0	0 regmask ! ;

: check		1 over lshift regmask @ and if exit then r> drop 1 over lshift regmask @ or regmask ! ;
: *reg		16 begin dup 32 < while check 1+ repeat -1 abort" Out of regs" ;

\ Frees the indicated register.
\ Read something like this: reg* == A register!  POOF!  It's gone!
: reg*		1 swap lshift invert regmask @ and regmask ! ;

\ Ephemeral Stack.  This is where the compiler maps which registers corresopnd
\ to which ephemeral stack location.
create es
16 allot
variable esp
: esp0		0 esp ! ;
: push		esp @ cells es + !  esp inc ;
: pop		-1 esp +!  esp @ cells es + @ ;
: reserve	*reg push ;
: top		esp @ 1- cells es + @ ;
: stop		esp @ 2 - cells es + @ ;
: ttop		esp @ 3 - cells es + @ ;
: top!		esp @ 1- cells es + ! ;
: stop!		esp @ 2 - cells es + ! ;
: ttop!		esp @ 3 - cells es + ! ;
: release	pop reg* ;

: addr		ci @ cells buf + ;
: insn		addr @ ;

: r1		8 lshift or ;
: r2		16 lshift or ;
: r3		24 lshift or ;
: scoot		insn -256 and 24 lshift insn 255 and or ;

: _noop		( nothing needed ) ;
: _lit		reserve scoot top r1 addr ! ;
: _add		scoot stop r1 stop r2 top r3 addr ! release ;
: _@8		scoot top r1 addr ! ;
: _!8		scoot top r1 stop r2 addr ! release release ;
: _>r		scoot top r1 addr ! release ;
: _r>		reserve insn top r1 addr ! ;
: _r@		reserve scoot top r1 addr ! ;
: _r!		scoot top r1 addr ! release ;
: _d@		reserve scoot top r1 addr ! ;
: _d!		scoot top r1 addr ! release ;
: _dup		pop dup push push ;
: _over		stop push ;
: _drop		release ;
: _swap		top stop top! stop! ;
: _nip		_swap _drop ;
: _rot		stop top ttop top! stop! ttop! ;
: _reset	regmask0 esp0 ;
: _jz		_@8 _reset ;
: _lsh		scoot top r1 addr ! ;

create procedures
' _noop ,
' _lit ,
' _add ,	( + )
' _add ,	( - )
' _add ,	( and )
' _add ,	( or )
' _add ,	( xor )
' _reset ,	( label )
' _@8 ,		( @8 )
' _@8 ,		( @16 )
' _@8 ,		( @32 )
' _@8 ,		( @64 )
' _!8 ,		( !8 )
' _!8 ,		( !16 )
' _!8 ,		( !32 )
' _!8 ,		( !64 )
' _reset ,	( J )
' _jz ,		( JZ )
' _reset ,	( CALL )
' _reset ,	( RFS )
' _>r ,		( >R )
' _r> ,		( R> )
' _r@ ,		( R@ )
' _r! ,		( R! )
' _>r ,		( >D )
' _r> ,		( D> )
' _d@ ,		( D@ )
' _d! ,		( D! )
' _dup ,
' _over ,
' _drop ,
' _nip ,
' _rot ,
' _swap ,
' _noop ,	( LGP )
' _noop ,	( PROLOG )
' _noop ,	( EPILOG )
' _jz ,		( JNZ )
' _lsh ,	( LSHIFT )
' _lsh ,	( RSHIFT )
' _lsh ,	( RSHIFT arithmetic )
' _jz ,		( JGE )

: opcode	insn 255 and ;
: dispatch	opcode cells procedures + @ execute ;
: reg0		begin ci @ ni @ >= if exit then dispatch ci inc again ;
: reg		fi @ ci ! reg0 ;
