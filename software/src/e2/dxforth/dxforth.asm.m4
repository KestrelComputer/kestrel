; DX-Forth
; Copyright (c) 2017-2019 Samuel A. Falvo II
; See LICENSE file in this or nearest parent directory.
;
; V1.0 : 2018-02-10
; Initial release for Kestrel-2DX.
;
; V1.1 : 2018-??-??
; Initial release for Kestrel-3/E2.
; BIOS dependency removed; DX-Forth *is* the new BIOS.

	include	"regs.i"
	include "dxforth.regs.i"


	; This is the cold-boot entry point of the KCP53K
	; family of processors.  Our task is to copy the
	; DX-Forth image to its final resting place in RAM.
	; Then, jump into RAM to start the DX-Forth image.
_bios_entry:
	auipc	gp,0		; GP := 0, basically.
	lw	a0,_n1-_bios_entry(gp)
	lw	a1,_n2-_bios_entry(gp)
	lw	a2,_n3-_bios_entry(gp)

_bios_copy:
	ld	a3,0(a0)
	sd	a3,0(a2)
	addi	a0,a0,8
	addi	a2,a2,8
	blt	a0,a1,_bios_copy

_bios_boot:
	lw	D,_n3-_bios_entry(gp)
	jalr	x0,0(D)

_n1:	word	_start
_n2:	word	_end
_n3:	word	$40000000

	; This is the official starting image of the DX-Forth
	; program image.  This jump instruction will appear
	; at $40000000 if all goes according to plan, and this
	; will then cause DX-Forth to launch.
_start:
	jal	x0,start_dxforth

; Define our dictionary structure.  NOTE: This does not
; actually produce code yet.  But it will pre-define a
; number of labels which are needed elsewhere to make the
; linkage work.  This must come somewhere after the
; definition of _start.

define(`defctr', `0')dnl
define(`incdefs', `define(`defctr', eval(defctr+1))')dnl
define(`defwd', `$1 = _$1 - _start
divert(`1')hword $1
divert(`2')byte "$2"
divert(`3')byte $3
divert`'incdefs`'dnl')dnl
define(`assoc', `defwd(`$1',`$2',`0')')dnl
define(`immed', `defwd(`$1',`$2',`1')')dnl
assoc(`zgo',       `0BRANCH ')
assoc(`nzgo',      `-0BRANCH')
assoc(`go',        `BRANCH  ')
assoc(`cold',      `COLD    ')
assoc(`empty',     `EMPTY   ')
assoc(`quit',      `QUIT    ')
assoc(`_3drop',    `3DROP   ')
assoc(`twodrop',   `2DROP   ')
assoc(`ntib',      `#TIB    ')
assoc(`tib',       `TIB     ')
assoc(`accept',    `ACCEPT  ')
assoc(`key',       `KEY     ')
assoc(`base',      `BASE    ')
assoc(`cmove',     `CMOVE   ')
assoc(`bye',       `BYE     ')
assoc(`drop',      `DROP    ')
assoc(`dup',       `DUP     ')
dnl''assoc(`curson',    `CURSON  ')
dnl''assoc(`cursoff',   `CURSOFF ')
dnl''assoc(`cursxy',    `CURSXY  ')
dnl''assoc(`pemitp',    `(EMIT)  ')
assoc(`emit',      `EMIT    ')
dnl''assoc(`ptypep',    `(TYPE)  ')
assoc(`type',      `TYPE    ')
assoc(`evaluate',  `EVALUATE')
assoc(`execute',   `EXECUTE ')
assoc(`exit',      `EXIT    ')
assoc(`fill',      `FILL    ')
assoc(`interpret', `INTERPRE')
assoc(`max',       `MAX     ')
assoc(`min',       `MIN     ')
assoc(`mmult',     `M*      ')
assoc(`name',      `NAME    ')
assoc(`parse',     `PARSE   ')
assoc(`tonumber',  `>NUMBER ')
assoc(`namtab',    `namtab  ')
assoc(`cfatab',    `cfatab  ')
assoc(`flgtab',    `flgtab  ')
assoc(`handler',   `handler ')
assoc(`negate',    `NEGATE  ')
assoc(`nip',       `NIP     ')
assoc(`nsrc',      `#SRC    ')
assoc(`obey',      `OBEY    ')
immed(`literal',   `LITERAL ')
assoc(`over',      `OVER    ')
assoc(`rdrop',     `RDROP   ')
assoc(`rot',       `ROT     ')
assoc(`tuck',      `TUCK    ')
assoc(`rtosrc',    `R>SRC   ')
assoc(`source_id', `SOURCE-I')
assoc(`source',    `SOURCE  ')
assoc(`space',     `SPACE   ')
assoc(`srcid',     `SRCID   ')
assoc(`src',       `SRC     ')
assoc(`srctor',    `SRC>R   ')
assoc(`blk',       `BLK     ')
assoc(`swap',      `SWAP    ')
assoc(`toin',      `>IN     ')
assoc(`tor',       `>R      ')
assoc(`rfetch',    `R@      ')
assoc(`twodup',    `2DUP    ')
assoc(`tworfrom',  `2R>     ')
assoc(`twotor',    `2>R     ')
assoc(`_u2slash',  `U2/     ')
assoc(`_4slash',   `4/      ')
assoc(`_8slash',   `8/      ')
assoc(`within',    `WITHIN  ')
assoc(`off',       `OFF     ')
assoc(`on',        `ON      ')
assoc(`_and',      `AND     ')
assoc(`_bic',      `BIC     ')
assoc(`_or',       `OR      ')
assoc(`_xor',      `XOR     ')
assoc(`cr',        `CR      ')
assoc(`_1minus',   `1-      ')
assoc(`_1plus',    `1+      ')
assoc(`_2slash',   `2/      ')
assoc(`_2star',    `2*      ')
assoc(`lshift',    `LSHIFT  ')
assoc(`rshift',    `RSHIFT  ')
assoc(`cells',     `CELLS   ')
assoc(`chars',     `CHARS   ')
assoc(`rfrom',     `R>      ')
assoc(`zeq',       `0=      ')
assoc(`zlt',       `0<      ')
assoc(`is_lt',     `<       ')
assoc(`is_eq',     `=       ')
assoc(`is_ge',     `>=      ')
assoc(`is_geu',    `U>=     ')
assoc(`hfetch',    `H@      ')
assoc(`hstore',    `H!      ')
assoc(`wfetch',    `W@      ')
assoc(`wstore',    `W!      ')
assoc(`cfetch',    `C@      ')
assoc(`cstore',    `C!      ')
assoc(`plussto',   `+!      ')
assoc(`mult',      `*       ')
assoc(`minus',     `-       ')
assoc(`plus',      `+       ')
assoc(`store',     `!       ')
assoc(`fetch',     `@       ')
assoc(`pad',       `PAD     ')
assoc(`hld',       `HLD     ')
assoc(`hold',      `HOLD    ')
assoc(`todigit',   `>DIGIT  ')
assoc(`nstart',    `<#      ')
assoc(`nnn',       `#       ')
assoc(`nns',       `#S      ')
assoc(`nend',      `#>      ')
assoc(`umdivmod',  `UM/MOD  ')
assoc(`smdivmod',  `SM/MOD  ')
assoc(`_div',      `/       ')
assoc(`_mod',      `MOD     ')
assoc(`udot',      `U.      ')
assoc(`dot',       `.       ')
assoc(`is_lt0',    `0<      ')
assoc(`abs',       `ABS     ')
assoc(`hex',       `HEX     ')
assoc(`decimal',   `DECIMAL ')
assoc(`binary',    `BINARY  ')
assoc(`dots',      `.S      ')
assoc(`depth',     `DEPTH   ')
assoc(`pick',      `PICK    ')
dnl``START BLOCK vocabulary
dnl``assoc(`remount',   `remount ')
assoc(`first',     `FIRST   ')
dnl``assoc(`flags',     `FLAGS   ')
dnl``assoc(`bns',       `BNS     ')
dnl``assoc(`used',      `USED    ')
dnl``assoc(`empty_bufs',`EMPTY-BU')
dnl``assoc(`fbic',      `find-blo')
dnl``assoc(`ba',        `block-ad')
assoc(`bclr',      `BCLR    ')
assoc(`bset',      `BSET    ')
dnl``assoc(`snb',       `select-n')
dnl``assoc(`wb',        `write-bl')
dnl``assoc(`fb',        `flush-bl')
dnl``assoc(`cb',        `configur')
dnl``assoc(`lob',       `load-blo')
dnl``assoc(`block',     `BLOCK   ')
dnl``assoc(`update',    `UPDATE  ')
dnl``assoc(`buffer',    `BUFFER  ')
dnl``assoc(`flush',     `FLUSH   ')
dnl``assoc(`load',      `LOAD    ')
dnl``END BLOCK vocabulary
assoc(`hh',        `H       ')
assoc(`here',      `HERE    ')
assoc(`avail',     `AVAIL   ')
assoc(`allot',     `ALLOT   ')
assoc(`alignh',    `ALIGNH  ')
assoc(`alignw',    `ALIGNW  ')
assoc(`alignd',    `ALIGND  ')
assoc(`ccomma',    `C,      ')
assoc(`hcomma',    `H,      ')
assoc(`wcomma',    `W,      ')
assoc(`comma',     `,       ')
assoc(`tlast',     `tlast   ')
assoc(`last',      `LAST    ')
assoc(`record',    `record  ')
assoc(`nfaok',     `nfaok   ')
assoc(`setnfa',    `setnfa  ')
assoc(`tooff',     `>OFF    ')
assoc(`setcfa',    `setcfa  ')
assoc(`torel',     `>rel    ')
assoc(`tojal',     `>jal    ')
assoc(`pcreatep',  `(create)')
assoc(`create',    `CREATE  ')
assoc(`immediate', `IMMEDIAT')
assoc(`variable',  `VARIABLE')
assoc(`constant',  `CONSTANT')
assoc(`state',     `STATE   ')
immed(`interp',    `[       ')
assoc(`compil',    `]       ')
assoc(`colon',     `:       ')
immed(`semi',      `;       ')
immed(`sq',        `S",34,"      ')
immed(`dq',        `.",34,"      ')
immed(`_if',       `IF      ')
immed(`_then',     `THEN    ')
immed(`_bgn',      `BEGIN   ')
immed(`_agn',      `AGAIN   ')
immed(`_cm',       `(       ')
assoc(`hi',        `hi      ')


DXFORTH_BASE = $0000000040000000
DXFORTH_TOP  = DXFORTH_BASE + $6B00

; On the Kestrel-2DX:
;
; DX-Forth is intended to be loaded at address $14300, and not
; exceed $17FFF.  The dictionary space is intended to occupy
; from $18000-$1BFFF.  Somewhere in this space must also exist
; things like the Forth stacks and block buffers.
;
; The following memory map crudely represents the memory layout
; so far:
;
; $13E80 - $13FFF	Return Stack (aka BIOS stack)
; $14000 - $142FF	BIOS State (opaque; do not touch!)
; $14300 - $17FFF	DX-Forth Image and state
; $18000 - $1ADFF	User programs and state
; $1AE00 - $1BDFF	Block I/O buffers
; $1BE00 - $1BFFF	Data Stack
;
; On the Kestrel-3:
;
; DX-Forth is intended to be loaded at address $0000000040000000,
; and is not to exceed $000000004000FFFF.  Somewhere in this
; space must also exist things like Forth stacks and block
; buffers.
;
; The following memory map crudely represents the memory layout
; so far (all offsets are relative to $40000000):
;
; $0000 - $3FFF		DX-Forth Image and state (16KB)
; $4000 - $DFFF		User programs and state (40KB)
; $E000 - $EFFF		Reserved for block I/O buffers
; $F000 - $F7FF		Data Stack
; $F800 - $FFFF		Return Stack
;
; Note that the exact boundary between DX-Forth and the user
; dictionary space is fluid.  The above memory map assumes the
; worst-case scenario where DX-Forth occupies a solid 16KiB.

	align	4

dstack_top = DXFORTH_BASE + $0F800
rstack_top = DXFORTH_BASE + $10000

start_dxforth:
	lui	R,rstack_top
	lui	S,dstack_top
	addi	I,D,_cold_0-_start
	; fallthrough to next

; Execute the next Forth virtual instruction.

next:	lhu	W,0(I)
	addi	I,I,2
	add	W,W,D
	jalr	x0,0(W)

; _bye:	jalr	x0,0(x0)	; Kestrel-2DX
_bye:	jal	x0, _start	; BYE reboots on Kestrel-3/E2.


; ==== COLD
;
; Note that some words need relative references defined here
; to resolve circular dependencies.  E.g., we must invoke QUIT
; from here, despite QUIT being defined much later in the
; listing.

squote = _squote - _start
lit16 = _lit16 - _start
lit32 = _lit32 - _start
lit64 = _lit64 - _start

wedge = _wedge - _start
	align	4
_wedge:	auipc	gp,0
	lw	a0,_w0-_wedge(gp)
	sw	gp,0(a0)
_w1:	jal	x0,_w1
_w0:	word	$0BADC0DE

	align	4
_cold:	jal	W,_docol
_cold_0:
	hword	lit16, 10, base, store, empty
	hword	hi, wedge, quit, cold	; Quit should never return.

	align	4
_empty:	jal	W,_docol
	hword	lit16, eval(defctr-1)*8, tlast, store
	hword	lit16, _dxforth_end, lit32
	align	4
	word	DXFORTH_BASE
	hword	plus, hh, store
	hword	exit

; Indirect branch to a new location.
; I should point to the instruction after EXECUTE.

	align	4
_execute:
	add	W,T,D
	ld	T,0(S)
	addi	S,S,8
	jalr	x0,0(W)

; Unconditional branch to a new location.

	align	4
_go:
	lhu	I,0(I)
	add	I,I,D
	jal	x0,next

; Branch to new location if T=0; continue otherwise.

	align	4
_zgo:
	addi	W,T,0
	ld	T,0(S)
	addi	S,S,8
	beq	W,x0,_go
	addi	I,I,2
	jal	x0,next

; Branch to new location if T<>0; continue otherwise.

	align	4
_nzgo:
	addi	W,T,0
	ld	T,0(S)
	addi	S,S,8
	bne	W,x0,_go
	addi	I,I,2
	jal	x0,next

; Colon definitions are headed by a JAL W,_docol instruction.

	align	4
_docol:
	addi	R,R,-8
	sd	I,0(R)
	addi	I,W,0
	jal	x0,next

; Exiting from a colon definition is similar to an
; unconditional branch.

	align	4
_exit:	ld	I,0(R)
	addi	R,R,8
	jal	x0,next

; Basic stack manipulation primitives.

; Push 16-bit signed literal.  This is expected to be the most
; frequently used literal push procedure, as except for memory
; addresses, nearly all numeric constants easily fits in 16
; bits.

	align	4
_lit16:
	addi	S,S,-8
	sd	T,0(S)
	lh	T,0(I)
	addi	I,I,2
	jal	x0,next

; Push 32-bit (64-bit) signed literal.  This requires its
; parameter to be 32-bit aligned, so there may be some padding
; between the lit32 token and its parameter.

	align	4
_lit32:
	addi	I,I,3
	andi	I,I,-4
	addi	S,S,-8
	sd	T,0(S)
	lw	T,0(I)
	addi	I,I,4
	jal	x0,next

	align	4
_lit64:
	addi	I,I,7
	andi	I,I,-8
	addi	S,S,-8
	sd	T,0(S)
	ld	T,0(I)
	addi	I,I,8
	jal	x0,next

; Push the address of a string constant onto the data stack.
; This is what gets used inside a colon definition.

	align	4
_squote:
	addi	S,S,-16
	sd	T,8(S)
	lbu	T,0(I)	; W -> str, T = len
	addi	W,I,1
	sd	W,0(S)
	add	I,I,T
	addi	I,I,2	; 1 for length byte, 1 for rounding up
	andi	I,I,-2
	jal	x0,next

; Duplicate the top of stack.

	align	4
_dup:
	addi	S,S,-8
	sd	T,0(S)
	jal	x0,next

; Drop a single cell from the data stack.
; DROP discards the top of the stack; NIP the next top of stack.

	align	4
_drop:
	ld	T,0(S)
_nip:	addi	S,S,8
	jal	x0,next

	align	4
; Exchange the two top-most data stack items.

	align	4
_swap:
	ld	W,0(S)
	sd	T,0(S)
	addi	T,W,0
	jal	x0,next

; Pull stack item underneath the top to the top.

	align	4
_over:
	addi	S,S,-8
	sd	T,0(S)
	ld	T,8(S)
	jal	x0,next

; Duplicate a pair on the top of stack.

	align	4
_twodup:
	jal	W,_docol
	hword	over,over,exit

; Rotate three stack items ( a b c -- b c a )

	align	4
_rot:	ld	a1,0(S)	;T=c A1=b A2=a
	ld	a2,8(S)
	sd	a1,8(S)
	sd	T,0(S)
	addi	T,a2,0
	jal	x0,next

; Tuck a datum away.  ( a b -- b a b )

	align	4
_tuck:	jal	W,_docol
	hword	dup, rot, rot, exit

; Return stack manipulations.

	align	4
_rdrop:
	addi	R,R,8
	jal	x0,next

	align	4
_rfrom:	addi	S,S,-8
	sd	T,0(S)
	ld	T,0(R)
	addi	R,R,8
	jal	x0,next

	align	4
_tor:	addi	R,R,-8
	sd	T,0(R)
	jal	x0,_drop

	align	4
_rfetch:
	addi	S,S,-8
	sd	T,0(S)
	ld	T,0(R)
	jal	x0,next

	align	4
_twotor:
	addi	R,R,-16
	ld	W,0(S)
	sd	W,8(R)
	sd	T,0(R)
	jal	x0,_twodrop

	align	4
_tworfrom:
	addi	S,S,-16
	sd	T,8(S)
	ld	T,8(R)
	sd	T,0(S)
	ld	T,0(R)
	addi	R,R,16
	jal	x0,next

; Stack Introspection

	align	4
_depth: addi	S,S,-8
	sd	T,0(S)
	addi	T,S,8
	lui	W,dstack_top
	sub	T,W,T	; Remember, T<=W when depth >= 0
	srai	T,T,3	; 64-bit wide stack elements
	jal	x0,next

	align	4
_pick:	slli	T,T,3	; 64-bit wide stack elements
	add	T,T,S
	jal	x0,_fetch

; Core Arithmetic/Logical Primitives.

; Sets T to -1 if T=0; 0 otherwise.
	align	4
_zeq:
	beq	T,x0,_rtnT
	addi	T,x0,0
	jal	x0,next
_rtnT:	addi	T,x0,-1
	jal	x0,next

; Sets T to -1 if T<0; 0 otherwise.
	align	4
_zlt:
	blt	T,x0,_rtnT
	addi	T,x0,0
	jal	x0,next

; Sets T to -1 if T=T'; 0 otherwise.
	align	4
_is_eq:
	ld	W,0(S)
	addi	S,S,8
	beq	T,W,_rtnT
	addi	T,x0,0
	jal	x0,next

; Sets T to -1 if T'>=T; 0 otherwise.
	align	4
_is_ge:
	ld	W,0(S)
	addi	S,S,8
	bge	W,T,_rtnT
	addi	T,x0,0
	jal	x0,next

	align	4
_is_geu:
	ld	W,0(S)
	addi	S,S,8
	bgeu	W,T,_rtnT
	addi	T,x0,0
	jal	x0,next

; Sets T to -1 if T'<T; 0 otherwise.
	align	4
_is_lt:
	ld	W,0(S)
	addi	S,S,8
	blt	W,T,_rtnT
_rtnF:	addi	T,x0,0
	jal	x0,next

; Sets T to -1 if T<0; 0 otherwise.

	align	4
_is_lt0:
	blt	T,x0,_rtnT
	addi	T,x0,0
	jal	x0,next

; Bitwise AND, OR, XOR.

	align	4
__and:
	ld	W,0(S)
	addi	S,S,8
	and	T,T,W
	jal	x0,next

	align	4
__bic:	ld	W,0(S)
	addi	S,S,8
	xori	W,W,-1
	and	T,T,W
	jal	x0,next

	align	4
__or:	ld	W,0(S)
	addi	S,S,8
	or	T,T,W
	jal	x0,next

	align	4
__xor:	ld	W,0(S)
	addi	S,S,8
	xor	T,T,W
	jal	x0,next

; Maths

	align	4
_bclr:	jal	W,_docol
	hword	tuck, cfetch, _bic, swap, cstore, exit

	align	4
_bset:	jal	W,_docol
	hword	tuck, cfetch, _or, swap, cstore, exit

	align	4
_negate:
	xori	T,T,-1
	addi	T,T,1
	jal	x0,next

	align	4
_abs:	blt	T,x0,_negate
	jal	x0,next

	align	4
__2star:
	slli	T,T,1
	jal	x0,next

	align	4
__8slash:
	srai	T,T,1
__4slash:
	srai	T,T,1
__2slash:
	srai	T,T,1
	jal	x0,next

	align	4
_lshift:
	ld	W,0(S)
	addi	S,S,8
	sll	T,W,T
	jal	x0,next

	align	4
_rshift:
	ld	W,0(S)
	addi	S,S,8
	sra	T,W,T
	jal	x0,next

	align	4
_cells:	slli	T,T,3
_chars:	jal	x0,next

	align	4
__u2slash:
	srli	T,T,1
	jal	x0,next

	align	4
__1plus:
	addi	T,T,1
	jal	x0,next

	align	4
__1minus:
	addi	T,T,-1
	jal	x0,next

	align	4
_plus:
	ld	W,0(S)
	addi	S,S,8
	add	T,T,W
	jal	x0,next

	align	4
_minus:
	ld	W,0(S)
	addi	S,S,8
	sub	T,W,T
	jal	x0,next

; These multiplication and division routines were originally
; designed for the RetroForth interpreter; they have their
; roots in an even earlier Kestrel-3 emulation environment,
; which ran a ported version of the STS operating system.
; These routines are very nearly entirely intact.
;
; * * *
;
; This procedure multiplies two signed or unsigned 64-bit integers to
; yield a 128-bit result.  A0 and A1 hold the multiplicands on entry.
; On exit, A1 holds the most significant partial product, and A0 holds
; the least-significant partial product.
; 
; This routine can be made ever-so-slightly faster if you don't preserve
; the temporary registers; however, this will break Ngaro, and I'm not
; motivated to fix the register dependency issues.  Besides, if you
; really want performance, replace this routine with a CPU `mul` and `mulhi`
; instruction pair.

mathMultiply:   addi    sp, sp, -48
                sd      ra, 0(sp)
                sd      t0, 8(sp)
                sd      t1, 16(sp)
                sd      t2, 24(sp)
                sd      t3, 32(sp)              ; Scratch register.
                sd      t4, 40(sp)

                ori     t0, a1, 0               ; Sign-extend A0 into T4:T0
                srli    t4, a1, 63
                xori    t4, t4, -1
                addi    t4, t4, 1

                ori     t1, a0, 0               ; Sign-extend A1 into T2:T1
                srli    t2, a0, 63
                xori    t2, t2, -1
                addi    t2, t2, 1

                ori     a0, x0, 0               ; Start with zero product
                ori     a1, x0, 0

m_m_again:      bne     t4, x0, *+8             ; If no more 1 bits left in the
                beq     t0, x0, m_m_done        ;    multiplicand, stop early.

                andi    t3, t0, 1               ; If multiplicand odd,
                beq     t3, x0, m_m_even        ;    accumulate partial product.
                add     a0, a0, t1
                add     a1, a1, t2
                bgeu    a0, t1, m_m_even
                addi    a1, a1, 1

m_m_even:       srli    t0, t0, 1               ; Divide T4:T0 by two.
                slli    t3, t4, 63
                or      t0, t0, t3
                srli    t4, t4, 1

                slli    t2, t2, 1               ; Multiply T2:T1 by two.
                srli    t3, t1, 63
                or      t2, t2, t3
                slli    t1, t1, 1

                jal     x0, m_m_again           ; Repeat until we're done.

m_m_done:       ld      ra, 0(sp)
                ld      t0, 8(sp)
                ld      t1, 16(sp)
                ld      t2, 24(sp)
                ld      t3, 32(sp)
                ld      t4, 40(sp)
                addi    sp, sp, 48
                jalr    x0, 0(ra)


; This procedure performs a 128-bit by 64-bit unsigned division.  Upon
; entry, A1:A0 holds the 128-bit numerator, and A2 holds the denominator.
; Upon exit, A1 holds the remainder, and A0 the quotient.
;
; I use the long-division algorithm as documented in the eponymous Wikipedia
; article.

mathUDivMod:    addi    sp, sp, -48
                sd      ra, 0(sp)
                sd      a2, 8(sp)
                sd      t0, 16(sp)
                sd      t1, 24(sp)
                sd      t2, 32(sp)
                sd      t3, 40(sp)

                addi    t0, x0, 0               ; Quotient
                addi    t1, x0, 0               ; Remainder
                addi    t3, x0, 128             ; Our input (A1:A0) has 128 bits
mUDM0:          beq     t3, x0, mUDM1           ; While we have bits to process...

                slli    t1, t1, 1               ; Shift R:N as a 192-bit quantity left 1 bit
                srli    t2, a1, 63              ; (multiplies by two)
                or      t1, t1, t2
                slli    a1, a1, 1
                srli    t2, a0, 63
                or      a1, a1, t2
                slli    a0, a0, 1

                slli    t0, t0, 1               ; Shift quotient left by 1 too.
                bltu    t1, a2, mUDM2           ; If we can subtract, then
                sub     t1, t1, a2              ;    Perform subtraction off of remainder.
                ori     t0, t0, 1               ;    Account for it in the quotient.

mUDM2:          addi    t3, t3, -1              ;  Repeat for all bits.
                jal     x0, mUDM0

mUDM1:          ori     a0, t0, 0
                ori     a1, t1, 0
                ld      ra, 0(sp)
                ld      a2, 8(sp)
                ld      t0, 16(sp)
                ld      t1, 24(sp)
                ld      t2, 32(sp)
                ld      t3, 40(sp)
                addi    sp, sp, 48
                jalr    x0, 0(ra)


; This procedure performs a 128-bit by 64-bit signed division.
; Upon entry, A1:A0 holds the 128-bit numerator, while A2 holds the
; denominator.  Upon exit, A1 holds the signed remainder, while A0 holds the
; signed quotient.
; 
; I use the same algorithm as that documented in the eponymous article on
; Wikipedia.  A simple test shows the following results:
;
;         N     D        R       Q
;       A1:A0   A2      A1'     A0'
;       ==========      ===========
;        -45    -8      -5       5
;        -45     8       3      -6
;         45    -8      -3      -6
;         45     8       5       5
;       ==========      ===========
;
; I confirmed this behavior matches the behavior of 64-bit GForth 0.7.0 under
; MacOS X.
;
; This behavior differs from C-based Ngaro VM implementations, and is most
; likely a bug for doing so.  This is what a C-compatible implementation
; would return:
;
;         N     D        R       Q
;       A1:A0   A2      A1'     A0'
;       ==========      ===========
;        -45    -8      -5       5
;        -45     8      -5      -5
;         45    -8       5      -5
;         45     8       5       5
;       ==========      ===========
;
; I will need to discuss this with @crcx to determine if this is an
; acceptable ambiguity, or if I should actually have full compliance here.
; The code is easy enough to change to match C-style semantics, but I'd
; prefer to use Forth-style semantics since that's what everyone familiar with
; Forth will come to expect from an RPN language.

mathSDivMod:    addi    sp, sp, -56
                sd      ra, 0(sp)
                sd      a1, 8(sp)               ; preserve sign of numerator
                sd      a2, 16(sp)              ; preserve sign of denominator
                sd      t0, 24(sp)
                sd      t1, 32(sp)
                sd      t2, 40(sp)
                sd      t3, 48(sp)

                bge     a1, x0, mSDM_a1pos      ; Take absolute value of A1:A0
                xori    a1, a1, -1
                xori    a0, a0, -1
                addi    a0, a0, 1
                bgeu    a0, x0, mSDM_a1pos
                addi    a1, a1, 1

mSDM_a1pos:     bge     a2, x0, mSDM_a2pos      ; Take absolute value of A2
                xori    a2, a2, -1
                addi    a2, a2, 1

mSDM_a2pos:     jal     ra, mathUDivMod         ; perform the core division

                ld      t0, 8(sp)               ; t0[63] = sign of numerator
                ld      t1, 16(sp)              ; t1[63] = sign of denominator
                addi    t2, x0, 0               ; t2 = final remainder

                xor     t3, t0, t1              ; If sgn(num) != sgn(denom)
                bge     t3, x0, mSDM_signok     ;   then adjust results.
                xori    a0, a0, -1              ; negate and subtract one.
                add     t2, t2, t1              ; adjust remainder.

mSDM_signok:    bge     t0, x0, mSDM_dpos       ; If num < 0, negate remainder.
                xori    a1, a1, -1
                addi    a1, a1, 1

mSDM_dpos:      add     t2, t2, a1              ; accumulate final remainder
                ori     a1, t2, 0

                ld      ra, 0(sp)
                ld      a2, 16(sp)
                ld      t0, 24(sp)
                ld      t1, 32(sp)
                ld      t2, 40(sp)
                ld      t3, 48(sp)
                addi    sp, sp, 56
                jalr    x0, 0(ra)

; End routines.

; UM/MOD ( ud u -- r q )

	align	4
_umdivmod:
	addi	a2,T,0
	ld	a1,0(S)
	ld	a0,8(S)
	jal	ra,mathUDivMod
	sd	a1,8(S)
	addi	S,S,8
	jal	x0,next

; SM/MOD ( sd u -- r q )

	align	4
_smdivmod:
	addi	a2,T,0
	ld	a1,0(S)
	ld	a0,8(S)
	jal	ra,mathSDivMod
	sd	a1,8(S)
	addi	S,S,8
	jal	x0,next

; / and MOD

	align	4
__div:	jal	W,_docol
	hword	swap, dup, zlt, rot, smdivmod, nip, exit

	align	4
__mod:	jal	W,_docol
	hword	swap, dup, zlt, rot, smdivmod, drop, exit

; M* ( a b -- a*b.L a*b.H )
;
; This implementation isn't particularly efficient.  But,
; it should be correct.

	align	4
_mmult:	addi	S,S,-8
	sd	T,0(S)
	ld	a0,0(S)
	ld	a1,8(S)
	jal	ra,mathMultiply
	sd	a0,8(S)
	sd	a1,0(S)
	ld	T,0(S)
	addi	S,S,8
	jal	x0,next

	align	4
_mult:	jal	W,_docol
	hword	_mmult, drop, exit

	align	4
_min:	ld	W,0(S)
	addi	S,S,8
	bge	W,T,_min_0
	addi	T,W,0
_min_0:	jal	x0,next

	align	4
_max:	ld	W,0(S)
	addi	S,S,8
	blt	W,T,_max_0
	addi	T,W,0
_max_0:	jal	x0,next


; Bounds-check.  Given (a b c - f), f=-1 if b <= a < c.
; Comparisons are signed.

	align	4
_within:
	ld	t1,0(S)
	ld	W,8(S)
	addi	S,S,16
	blt	W,t1,_rtnF
	bge	W,T,_rtnF
	addi	T,x0,-1
	jal	x0,next

; Memory Operators

	align	4
_fetch:
	ld	T,0(T)
	jal	x0,next

	align	4
_wfetch:
	lw	T,0(T)
	jal	x0,next

	align	4
_hfetch:
	lh	T,0(T)
	jal	x0,next

	align	4
_cfetch:
	lbu	T,0(T)
	jal	x0,next


	align	4
_store:
	ld	W,0(S)
	sd	W,0(T)
_twodrop:
	ld	T,8(S)
	addi	S,S,16
	jal	x0,next

	align	4
_off:	sd	x0,0(T)
	jal	x0,_drop

	align	4
_on:	jal	W,_docol
	hword	lit16, -1, swap, store, exit

	align	4
_wstore:
	ld	W,0(S)
	sw	W,0(T)
	jal	x0,_twodrop

	align	4
_hstore:
	ld	W,0(S)
	sh	W,0(T)
	jal	x0,_twodrop

	align	4
_cstore:
	ld	W,0(S)
	sb	W,0(T)
	jal	x0,_twodrop

	align	4
_plussto:
	ld	W,0(S)
	ld	t1,0(T)
	add	t1,t1,W
	sd	t1,0(T)
	jal	x0,_twodrop

	align	4
_fill:	ld	W,0(S)	; T1->buf, W=len, T=filler
	ld	t1,8(S)
	add	t2,t1,W	; T2->end of buf
_fill0:	sb	T,0(t1)
	addi	t1,t1,1
	bne	t1,t2,_fill0
__3drop:
	ld	T,16(S)
	addi	S,S,24
	jal	x0,next

	align	4
_cmove:	ld	W,0(S)	; T1->src, W->dst, T=length
	ld	t1,8(S)
	blt	t1,W,_cmove_0
	; src >= dst; ascend through memory
_cmove_1:
	lb	t2,0(t1)
	sb	t2,0(W)
	addi	t1,t1,1
	addi	W,W,1
	addi	T,T,-1
	blt	x0,T,_cmove_1
	jal	x0,__3drop

_cmove_0: ; src < dst; descend through memory
	add	t1,t1,T
	add	W,W,T
_cmove_2:
	lb	t2,-1(t1)	; -1 bias because t1/W points
	sb	t2,-1(W)	; *beyond* the intended byte.
	addi	t1,t1,-1
	addi	W,W,-1
	addi	T,T,-1
	blt	x0,T,_cmove_2
	jal	x0,__3drop

; Variable definitions are laid out in memory aligned to a
; 4-byte boundary.  However, because the content of a variable
; is an 8-byte quantity, the variable's start address must be
; 64-bit aligned.
;
; dovar is called by a JAL W,_dovar instruction in the code
; field of a variable definition.
;
; Thus, in assembly language, a variable would look like:
;
; 1	_myVar:	jal	W,_dovar
; 2		align	8
; 3		dword	0
;
; Line 1 declares the variable, and provides the entry-point
; for it to reference in a colon definition.  Line 2 provides
; the proper alignment for the variable's storage allotment
; in line 3.

	align	4
dovar = _dovar - _start
_dovar:
	addi	W,W,7
	addi	S,S,-8
	sd	T,0(S)
	andi	T,W,-8
	jal	x0,next

; Constant definitions are laid out in memory identically to
; variables: aligned to 4-byte boundary, but with a payload
; aligned to 8 bytes.  They're just variables which pre-fetch
; their value, basically.

	align	4
docon = _docon - _start
_docon:
	addi	W,W,7
	addi	S,S,-8
	sd	T,0(S)
	andi	T,W,-8
	ld	T,0(T)
	jal	x0,next

; Print a single character to the user's console.
; The Kestrel-3/E2 version touches hardware directly.
; We assume that the console's SIA has been properly configured already.

	align	4
_emit:	jal	W,_docol
	hword	lit16, -4096, cstore, exit

; Perform a carriage return.

	align	4
_cr:	jal	W,_docol
	hword	lit16, 13, emit, lit16, 10, emit, exit

; Print a single space.

	align	4
_space:	jal	W,_docol
	hword	lit16, 32, emit, exit

; Type a whole string.

	align	4
_type:	jal	W,_docol
_type_0:
	hword	dup, zgo, _type_1
	hword	over, emit
	hword	lit16, -1, plus, swap, lit16, 1, plus, swap
	hword	go, _type_0
_type_1:
	hword	twodrop, exit

; Get a key from the user's console

	align	4
key = _key - _start
_key:	jal	W,_docol
	hword	_key		; deadlock until we figure out the input side of the SIA.

	align	4
_ntib:	jal	W,_dovar
	align	8
	dword	0

	align	4
_tib:	jal	W,_dovar
	align	8
	adv	*+256, 0


; ----- ACCEPT -----
;
; This implementation of ACCEPT is not elegant, but it is
; effective.

; Variable: Start of the edit buffer.

	align	4
strt = _strt - _start
_strt:	jal	W,_dovar
	align	8
	dword	0

; Variable: End of the edit buffer.

	align	4
end = _end - _start
_end:	jal	W,_dovar
	align	8
	dword	0

; Variable: Current write point in the buffer.
; At all times, strt <= cur < end.

	align	4
cur = _cur - _start
_cur:	jal	W,_dovar
	align	8
	dword	0

; Precondition: ensure character actually is a graphic
; character.  If not, ignore it.

	align	4
qgr = _qgr - _start
_qgr:	jal	W,_docol
	hword	dup, lit16, 32, lit16, 127, within, zeq, zgo, _qgr_0, rdrop
_qgr_0:	hword	exit

; Precondition: ensure the edit buffer is not full.  If it
; is, ignore the graphic character.

	align	4
notfull = _notfull - _start
_notfull:
	jal	W,_docol
	hword	cur, fetch, end, fetch, is_ge, zgo, _notfull_0 - _start, rdrop
_notfull_0:
	hword	exit

; Trap and handle graphic characters.  Place them in the
; edit buffer.

	align	4
gr = _gr - _start
_gr:	jal	W,_docol
	hword	qgr, notfull, dup, cur, fetch, cstore
	hword	lit16, 1, cur, plussto, dup, emit, exit

; Precondition: ensure >=1 character exists in the input
; buffer.  If not, abort backspace processing.

	align	4
notempty = _notempty - _start
_notempty:
	jal	W,_docol
	hword	cur, fetch, strt, fetch, is_eq, zgo, _notempty_0
	hword	lit16, 0, rdrop
_notempty_0:
	hword	exit

; Trap backspaces and handle them.

	align	4
dotbs = _dotbs - _start
_dotbs:	jal	W,_docol
	hword	lit16, 8, emit, lit16, 32, emit, lit16, 8, emit, exit

	align	4
bs = _bs - _start
_bs:	jal	W,_docol
	hword	dup, lit16, 8, is_eq, zgo, _bs_0
	hword	drop, notempty, lit16, -1, cur, plussto, dotbs, lit16, 0
_bs_0:	hword	exit

; Trap carriage returns (CTRL-M) and handle them.
; Per ANSI, we return the number of characters entered.

	align	4
c_m = _c_m - _start
_c_m:	jal	W,_docol
	hword	dup, lit16, 13, is_eq, zgo, _c_m_0
	hword	drop, cur, fetch, strt, fetch, minus, rdrop
_c_m_0:	hword	exit

; Trap line-aborts (CTRL-C) and handle them.
;
; This implementation simply forces ACCEPT to return a
; 0-length string by resetting the cur pointer and
; forcing a carriage return.

	align	4
c_c = _c_c - _start
_c_c:	jal	W,_docol
	hword	dup, lit16, 3, is_eq, zgo, _c_c_0
	hword	strt, fetch, cur, store, drop, lit16, 13
_c_c_0:	hword	exit

; ANSI ACCEPT.

	align	4
;accept = _accept - _start
_accept:
	jal	W,_docol
	hword	over, plus, end, store
	hword	dup, strt, store, cur, store
_accept_0:
	hword	key, bs, c_c, c_m, gr, drop, go, _accept_0 - _start

; END ACCEPT

; BEGIN PICTURED NUMERIC OUTPUT

	align	4
_pad:	jal	W,_docol
	hword	here, lit16, 256, plus, exit

	align	4
_hld:	jal	W,_dovar
	align	8
	dword	0

	align	4
_hold:	jal	W,_docol
	hword	lit16, -1, hld, plussto, hld, fetch, cstore, exit

	align	4
_todigit:
	jal	W,_docol
	hword	dup, lit16, 10, is_geu, zgo, _todigit_0
	hword	lit16, 7, plus
_todigit_0:
	hword	lit16, $30, plus, exit

	align	4
_nstart:
	jal	W,_docol
	hword	pad, hld, store, exit

	align	4
_nend:	jal	W,_docol
	hword	drop, hld, fetch, pad, over, minus, exit

	align	4
_nnn:	jal	W,_docol	; nn: is taken elsewhere.
	hword	lit16, 0, base, fetch, umdivmod, swap, todigit, hold, exit

	align	4
_nns:	jal	W,_docol
_nns_0:	hword	nnn, dup, zeq, zgo, _nns_0, exit

	align	4
_udot:	jal	W,_docol
	hword	nstart, nns, nend, type, exit

	align	4
_dot:	jal	W,_docol
	hword	dup, is_lt0, tor, abs, nstart, nns, rfrom
	hword	zgo, _dot_0, lit16, $2D, hold
_dot_0:	hword	nend, type, exit

	align	4
_dotdepth:
dotdepth = _dotdepth - _start
	jal	W,_docol
	hword	lit16, 91, emit, depth, dot, lit16, 93, emit, space, exit

	align	4
dotvals = _dotvals - _start
_dotvals:
	jal	W,_docol
	hword	depth, lit16, 0, max
_dotvals_0:
	hword	dup, zgo, _dotvals_1
	hword	dup, pick, dot, space, _1minus, go, _dotvals_0
_dotvals_1:
	hword	drop, exit

	align	4
_dots:	jal	W,_docol
	hword	dotdepth, dotvals, space, space, exit

; END PICTURED NUMERIC OUTPUT

; ==== Look stuff up in the dictionary.
;
; The dictionary is a mapping of word name to code field
; address (CFA).  The dictionary is expressed as a relational
; table with the following schema:
;
; Name		8 bytes		namtab
; CFA		2 bytes		cfatab
; Flags		1 byte		flgtab
;
; The flags are laid out as follows:
;
;	.... ...1	Word is immediate
;	.... ..1.	Word is compile-only
;	.... .1..	Word is private/"headerless"
;	xxxx x...	Reserved for future use.
;
; The constant #words indicates how many records exists in this
; table.  As I type this, 256 words are reserved, meaning the
; total relational table consists of 256*(8+2+1)=2816 bytes,
; basic overhead and procedure code notwithstanding.
;
; The columns of this table are stored as contiguous arrays.
; For example, the Name column consists of #words*8 bytes of
; space, the CFA column #words*2 bytes, and the Flags column
; takes up #words*1 bytes of space.
;
; The variable 'last points to the last defined word; note, NOT
; the next-to-be-defined word.  Since the most frequent
; operation on this table is to look up a word, 'last is kept
; as a byte offset relative to the start of the Name column.
; Since this column is 8 bytes wide, it follows that the
; following invariant must always hold: (0 <= 'last <
; Names+#words*8) /\ ('last = 8*('last/8))

	align	4
szCell = _szCell - _start
_szCell:
	jal	W,_docon
	align	8
	dword	8

	; The dictionary is configured to hold 256 words over the
	; statically compiled set found in this source listing.
	; This accounts for an extra 256*(8+2+1) = 2816 bytes of
	; the Forth image.

	align	4
nwords = _nwords - _start
_nwords:
	jal	W,_docon
	align	8
	dword	eval(defctr)+256

	align	4
;flgtab = _flgtab - _start
_flgtab:
	jal	W,_dovar
	align	8
undivert(3)
	adv	*+(256*1), 0

	align	4
;cfatab = _cfatab - _start
_cfatab:
	jal	W,_dovar
	align	8
undivert(1)
	adv	*+(256*2), 0

	align	4
;namtab = _namtab - _start
_namtab:
	jal	W,_dovar
	align	8
undivert(2)
	adv	*+(256*8), 32

	align	4
tlast = _tlast - _start
_tlast:	jal	W,_dovar
	align	8
	dword	0

	align	4
k = _k - _start
_k:	jal	W,_dovar
	align	8
	dword	0

	align	4
_last:	jal	W,_docol
	hword	tlast, fetch, exit

	align	4
cellm = _cellm - _start
_cellm:	jal	W,_docol
	hword	szCell, minus, exit

	align	4
match = _match - _start
_match:	jal	W,_docol
; : MATCH ( i-xt -1|xt 1)
;   DUP 2/ 2/ cfatab + H@
;   SWAP 2/ 2/ 2/ flgtab + C@ 1 AND 2* 1- ;
; ( yields xt -1 for non-immediate words, xt 1 for immediate )
; ( this is why immediate flag in bit 0 is important; it
;   eliminates the need for conditional branching here. )
	hword	dup, _4slash, cfatab, plus, hfetch
	hword	swap, _8slash, flgtab, plus, cfetch
	hword	lit16, 1, _and, _2star, _1minus, exit

	align	4
matchq = _matchq - _start
_matchq:
; : MATCH? ( i-if)
;   namtab OVER + @ K @ = ;
	jal	W,_docol
	hword	namtab, over, plus, fetch, k, fetch, is_eq
	hword	exit

	align	4
nmatch = _nmatch - _start
_nmatch:
; : -MATCH ( i-i|)
;   MATCH? IF MATCH 2RDROP THEN EXIT ;
	jal	W,_docol
	hword	matchq, zgo, _nmatch_0
	hword	match, rdrop, rdrop
_nmatch_0:
	hword	exit

	align	4
nlt0 = _nlt0 - _start
_nlt0:	jal	W,_docol
; : -LT0 ( i-i|)
;   DUP 0< IF DROP RDROP THEN ;
	hword	dup, zlt, zgo, _nlt0_0, drop, rdrop
_nlt0_0:
	hword	exit

	align	4
undef = _undef - _start
_undef:	jal	W,_docol
; : UNDEF ( -)
;   LAST BEGIN -LT0 -MATCH CELL- AGAIN ;
	hword	last
_undef_0:
	hword	nlt0, nmatch, cellm, go, _undef_0

	align	4
kstore = _kstore - _start
_kstore:
; : K! ( au-)
;   K 8 32 FILL  /CELL MIN K SWAP CMOVE ;
	jal	W,_docol
	hword	k, lit16, 8, lit16, 32, fill
	hword	szCell, min, k, swap, cmove, exit

	align	4
;handler = _handler - _start
_handler:
; : HANDLER ( au-0|xt -1|xt 1)
;   K! UNDEF 0 ;
	jal	W,_docol
	hword	kstore, undef, lit16, 0, exit

; ====== Outer Interpreter

	align	4		; >IN
_toin:	jal	W,_dovar
	align	8
	dword	0

	align	4		; #SRC
_nsrc:	jal	W,_dovar
	align	8
	dword	0

	align	4		; SRC
_src:	jal	W,_dovar
	align	8
	dword	0

	align	4		; BLK
_blk:	jal	W,_dovar
	align	8
	dword	0

	align	4		; SRCID (used to derive SOURCE-ID)
_srcid:	jal	W,_dovar	; 0 if interpreting interactively.
	align	8		; >0 if interpreting from an input "file" of some kind.
	dword	0		; Typically, +ve values refer to stream handles.

	align	4
_source:
	jal	W,_docol
	hword	blk, fetch, zgo, _source_1
;	hword	blk, fetch, block, lit16, 1024, exit
_source_1:
	hword	src, fetch, nsrc, fetch, exit

	align	4
_source_id:
	jal	W,_docol
	hword	srcid, fetch, exit

	align	4
point = _point - _start
_point:	jal	W,_docol
	hword	source, drop, toin, fetch, plus, exit

	align	4
budge = _budge - _start
_budge:	jal	W,_docol
	hword	lit16, 1, toin, plussto, exit

	align	4
not_eoi = _not_eoi - _start
_not_eoi:
	jal	W,_docol
	hword	toin, fetch, source, nip, is_ge, zgo, _not_eoi_0
	hword	rdrop
_not_eoi_0:
	hword	exit

	align	4
not_ws = _not_ws - _start
_not_ws:
	jal	W,_docol
	hword	point, cfetch, lit16, $21, is_lt, zgo, _not_ws_0, rdrop
_not_ws_0:
	hword	exit

	align	4
not_text = _not_text - _start
_not_text:
	jal	W,_docol
	hword	point, cfetch, lit16, $21, is_ge, zgo, _not_text_0, rdrop
_not_text_0:
	hword	exit

	align	4
text = _text - _start
_text:	jal	W,_docol
_text_0:
	hword	not_eoi, not_ws, budge, go, _text_0

	align	4
ws = _ws - _start
_ws:	jal	W,_docol
_ws_0:	hword	not_eoi, not_text, budge, go, _ws_0

	align	4
not_chr = _not_chr - _start
_not_chr:
	jal	W,_docol
	hword	point, cfetch, over, is_eq, zgo, _not_chr_0
	hword	rdrop
_not_chr_0:
	hword	exit

	align	4
scan = _scan - _start
_scan:	jal	W,_docol
_scan_0:
	hword	not_eoi, not_chr, budge, go, _scan_0

	align	4
_parse:	jal	W,_docol
	hword	point, swap, scan, drop, point, over, minus, budge, exit

	align	4
_name:	jal	W,_docol
	hword	ws, point, text, point, over, minus, budge, exit
	; We cannot define name in terms of parse, because
	; name stops reading text upon ANY whitespace character,
	; not just the one specified as the parameter to parse.

	align	4
err = _err - _start
_err:	jal	W,_docol
	hword	squote
	byte	3, "?? "
	align	2
	hword	type, type, squote
	byte	12, " undefined",13,10
	align	2
	hword	type, quit, exit		; circular reference to quit!

	align	4
not_word = _not_word - _start
_not_word:
	jal	W,_docol
	; ( if word not found )
	hword	twodup, handler, dup, zeq, zgo, _not_word_0
	hword	drop, exit
_not_word_0:
	; ( if word is not immediate )
	hword	dup, zlt, zgo, _not_word_1
	hword	drop, nip, nip, state, fetch, zgo, _not_word_2
	hword	hcomma, rdrop, exit
_not_word_2:
	hword	execute, rdrop, exit
_not_word_1:
	; ( otherwise, it must be immediate )
	hword	drop, nip, nip, execute, rdrop, exit

	align	4
not_eoi1 = _not_eoi1 - _start
_not_eoi1:
; : -eoi ( au-au )
;   DUP 0= IF 2DROP 2RDROP THEN ;
	jal	W,_docol
	hword	dup, zeq, zgo, _not_eoi1_0, twodrop, rdrop, rdrop
_not_eoi1_0:
	hword	exit

	align	4
_base:	jal	W,_dovar
	align	8
	dword	10

	align	4
_hex:	jal	W,_docol
	hword	lit16, 16, base, store, exit

	align	4
_decimal:
	jal	W,_docol
	hword	lit16, 10, base, store, exit

	align	4
_binary:
	jal	W,_docol
	hword	lit16, 2, base, store, exit

	align	4
sign = _sign - _start
_sign:	jal	W,_dovar
	align	8
	dword	0

	align	4
nn = _nn - _start
_nn:	jal	W,_docol
; : nn
;   ( n a u -- n' a' u'   if a points to a valid character )
;   ( n a u --            otherwise; returns )
;   -rot  ( u n a )
;   dup c@ '0 - dup 10 u>= 7 and - ( u n a d )
;   dup base @ u>= if 2drop 2drop rdrop exit then
;   rot base @ * + swap ( u n' a )
;   1+ rot 1- ;
	hword	rot, rot
	hword	dup, cfetch, lit16, 48, minus
	hword	dup, lit16, 10, is_geu, lit16, 7, _and, minus
	hword	dup, base, fetch, is_geu, zgo, _nn_0
	hword	twodrop, twodrop, rdrop, exit
_nn_0:	hword	rot, base, fetch, mult, plus, swap
	hword	_1plus, rot, _1minus, exit

	align	4
not_num = _not_num - _start
_not_num:
	jal	W,_docol
; : -num
;   ( a u -- n     if au is a number; returns )
;   ( a u -- a u   otherwise )
;   sign off
;   2dup over c@ '- = if sign on 1- swap 1+ swap then
;   0 -rot   ( n a u )
;   begin dup while nn repeat
;   2drop sign @ if negate then nip nip rdrop ;
	hword	sign, off
	hword	twodup, over, cfetch, lit16, 45, is_eq, zgo, _not_num_0
	hword	sign, on, _1minus, swap, _1plus, swap
_not_num_0:
	hword	lit16, 0, rot, rot
_not_num_1:
	hword	dup, zgo, _not_num_2, nn, go, _not_num_1
_not_num_2:
	hword	twodrop, sign, fetch, zgo, _not_num_3
	hword	negate
_not_num_3:
	hword	nip, nip, rdrop, exit

	align	4
is_num = _is_num - _start
_is_num:
	jal	W,_docol
	hword	not_num, lit16, 0, rdrop, exit

	align	4
_tonumber:
	jal	W,_docol
	hword	is_num, lit16, -1, exit

	align	4
_literal:
	jal	W,_docol
	hword	dup, lit16, -32768, dup, negate, within, zgo, _literal_0
	hword	lit16, lit16, hcomma, hcomma, exit
_literal_0:
	hword	dup, lit32
	align	4
	word	-2147483648
	hword	dup, negate, within, zgo, _literal_1
	hword	lit16, lit32, hcomma, alignw, wcomma, exit
_literal_1:
	hword	lit16, lit64, hcomma, alignd, comma, exit

	align	4
_obey:	jal	W,_docol
	hword	not_eoi1, not_word, tonumber, zgo, _obey_0
	hword	state, fetch, zgo, _obey_1
	hword	literal
_obey_1:
	hword	exit
_obey_0:
	hword	err, exit

	align	4
_interpret:
	jal	W,_docol
_interpret_0:
	hword	name, obey, go, _interpret_0

	align	4
_srctor:
	jal	W,_docol
	hword	rfrom
	hword	toin, fetch, tor
	hword	source, twotor
	hword	source_id, tor
	hword	blk, fetch, tor
	hword	tor, exit

	align	4
_rtosrc:
	jal	W,_docol
	hword	rfrom
	hword	rfrom, blk, store
	hword	rfrom, srcid, store
	hword	tworfrom, nsrc, store, src, store
	hword	rfrom, toin, store
	hword	tor, exit

	align	4
_evaluate:
	jal	W,_docol
	hword	srctor
	hword	lit16, -1, srcid, store
	hword	lit16, 0, toin, store
	hword	nsrc, store, src, store
	hword	interpret
	hword	rtosrc, exit

	align	4
_load:	jal	W,_docol
	hword	srctor
	hword	blk, store, toin, off, interpret
	hword	rtosrc, exit

	align	4
rep = _rep - _start
_rep:	jal	W,_docol
	hword	tib, lit16, 256				; read
;	hword	curson
	hword	accept
;	hword   cursoff
	hword	ntib, store
	hword	space, space
	hword	tib, ntib, fetch, evaluate		; eval
	hword	squote					; print
	byte	4, "  OK"
	align	2
	hword	type, cr, exit

	align	4
_quit:	lui	R,$14000		; Hard reset of return stack.
	jal	W,_docol
	hword	blk, off, state, off
	hword	cr
_quit_0:
	hword	rep, go, _quit_0

; ====== BEGIN BLOCKS ======
;
; I think this is where I had it last.  TODO: Fix this later.

	align	4
_first:	jal	W,_docon
	align	8
	dword	DXFORTH_TOP	; First of four 1KiB blocks

; ====== END BLOCKS ======

; ====== COMPILER ======
;
; We start the compiler off with something very simple.
; All we are supporting at this time is the ability to
; instantiate a buffer or a variable.  I would also include
; constants, but I want to remain focused on minimizing the
; number of moving parts.
;
; Since a variable is just a buffer of a single integer,
; we start by considering how to add a buffer.  The word
; CREATE will be used for this purpose.
;
; CREATE must perform two steps, basically.  First, it must
; create a new dictionary registration, so that future
; dictionary searches will be able to find the new word.
; Secondly, it must place code and data into the dictionary
; space itself, so that we have some place to fetch and store.
; Similarly, the CFA of the word must properly refer to the
; _dovar procedure, so that when the buffer's name is
; executed, its address appears on the top of the data stack.
;
; In essence:
;
; VARIABLE H
;
; : HERE
;   H @ ;
;
; : ALLOT
;   H +! ;
;
; : ALIGNW
;   H @ 3 + -4 AND H ! ;
;
; : ALIGN
;   H @ 7 + -8 AND H ! ;
;
; : W,
;   HERE W!  4 ALLOT ;
;
; : ,
;   HERE !  8 ALLOT ;
;
; : CREATE
;   ALIGNW		( Align HERE to 32-bit boundary )
;   NAME K! record	( records the name of the new word )
;   ['] dovar >JAL W,	( place JAL X0,_dovar instruction )
;   ALIGN ;		( Align to 64-bit boundary. )
;
; Like handler, record must take its name argument in the K
; variable.  It will also default to a non-immediate word
; that can be invoked from the OK prompt, and as well, whose
; definition starts at the current value of HERE.
;
; If record has no place to record the dictionary entry, then
; it prints an error message and invokes QUIT, thus aborting
; whatever compiler or interpreter action was in-progress.
; This will not restore the dictionary space, however; be sure
; to use marker words if you want to reclaim dictionary space
; after a failed load.

; ========================

	align	4
_hh:	jal	W,_dovar
	align	8
	dword	0

	align	4
_here:	jal	W,_docol
	hword	hh, fetch, exit

	align	4
_avail:	jal	W,_docol	; ( - freeBytes freeWords )
	hword	first, here, minus
	hword	nwords, last, _8slash, _1plus, minus
	hword	exit

	align	4
_allot:	jal	W,_docol
	hword	hh, plussto, exit

	align	4
_alignh:
	jal	W,_docol
	hword	hh, fetch, lit16, 1, plus, lit16, -2, _and
	hword	hh, store, exit

	align	4
_alignw:
	jal	W,_docol
	hword	hh, fetch, lit16, 3, plus, lit16, -4, _and
	hword	hh, store, exit

	align	4
_alignd:
	jal	W,_docol
	hword	hh, fetch, lit16, 7, plus, lit16, -8, _and
	hword	hh, store, exit

	align	4
_ccomma:
	jal	W,_docol
	hword	hh, fetch, cstore, lit16, 1, allot, exit

	align	4
_hcomma:
	jal	W,_docol
	hword	alignh, hh, fetch, hstore, lit16, 2, allot, exit

	align	4
_wcomma:
	jal	W,_docol
	hword	alignw, hh, fetch, wstore, lit16, 4, allot, exit

	align	4
_comma:
	jal	W,_docol
	hword	alignd, hh, fetch, store, lit16, 8, allot, exit

	align	4
_record:
	jal	W,_docol
	hword	kstore
	hword	tlast, fetch, lit16, 8, plus, nfaok, tlast, store
	hword	setnfa, setcfa, exit

	align	4
_nfaok:	jal	W,_docol
	hword	dup, lit16, (eval(defctr)+256)*8, is_ge, zgo, _nfaok_1
	hword	_squote
	byte	25,"?? TOO MANY DEFINITIONS",13,10
	align	2
	hword	type, cr, quit, exit
_nfaok_1:
	hword	exit

	align	4
_setnfa:
	jal	W,_docol
	hword	k, fetch, namtab, last, plus, store, exit

	align	4
_tooff:	jal	W,_docol
	hword	lit32
	align	4
	word	DXFORTH_BASE
	hword	minus, exit

	align	4
_setcfa:
	jal	W,_docol
	hword	alignw, here, tooff, cfatab, last, _4slash
	hword	plus, hstore, exit

	align	4
_tojal:	jal	W,_docol	; ( offset - instruction )
	hword	lit16, $2EF
	; place bit 20
	hword	over, lit32
	align	4
	word	$00100000
	hword	_and, lit16, 11, lshift, _or
	; place bits 10:1
	hword	over, lit16
	hword	$07FE
	hword	_and, lit16, 20, lshift, _or
	; place bit 11
	hword	over, lit16
	hword	$0800
	hword	_and, lit16, 9, lshift, _or
	; place bits 19:12
	hword	over, lit32
	align	4
	word	$000FF000
	hword	_and, _or
	hword	nip, exit

	align	4
_torel:	jal	W,_docol
	hword	lit32
	align	4
	word	DXFORTH_BASE
	hword	plus, here, minus, exit

	align	4
_pcreatep:
	jal	W,_docol
	hword	name, record, torel, tojal, wcomma, exit

	align	4
_create:
	jal	W,_docol
	hword	lit16, _dovar, pcreatep, alignd, exit

	align	4
_immediate:
	jal	W,_docol
	hword	lit16, 1, last, _8slash
	hword	flgtab, plus, bset, exit

	align	4
_variable:
	jal	W,_docol
	hword	create, lit16, 0, comma, exit

	align	4
_constant:
	jal	W,_docol
	hword	lit16, _docon, pcreatep, alignd, comma, exit

	align	4
_state:	jal	W,_dovar
	align	8
	dword	0

	align	4
_interp:
	jal	W,_docol
	hword	state, off, exit

	align	4
_compil:
	jal	W,_docol
	hword	state, on, exit

	align	4
_colon:	jal	W,_docol
	hword	lit16, _docol, pcreatep, alignh, compil, exit

	align	4
_semi:	jal	W,_docol
	hword	interp, lit16, exit, hcomma, exit

	align	4
_sq:	jal	W,_docol
	hword	lit16, 34, parse
	hword	state, fetch, zgo, _sq_0
	hword	lit16, squote, hcomma		; (S")
	hword	dup, ccomma			; length byte
	hword	here, swap, dup, allot, cmove	; string body
	hword	alignh
_sq_0:	hword	exit

	align	4
_dq:	jal	W,_docol
	hword	sq, state, fetch, zgo, _dq_0
	hword	lit16, type, hcomma, exit
_dq_0:	hword	type, exit

	align	4
_hi:	jal	W,_docol
	hword	_squote
	byte	32,"**** Kestrel-2DX Forth V1.0 ****"
	align	2
	hword	type, cr, avail, dot, _squote
	byte	14," words free.  "
	align	2
	hword	type, dot, _squote
	byte	12," bytes free."
	align	2
	hword	type, cr, exit

	align	4
__if:	jal	W,_docol
	hword	lit16, zgo, hcomma
	hword	here, lit16, 0, hcomma, exit

	align	4
__then:	jal	W,_docol
	hword	here, tooff, swap, hstore, exit

	align	4
__bgn:	jal	W,_docol
	hword	here, tooff, exit

	align	4
__agn:	jal	W,_docol
	hword	lit16, go, hcomma, hcomma, exit

	align	4
__cm:	jal	W,_docol
	hword	lit16, 41, parse, twodrop, exit


; ========
; The end of the DX-Forth image.  This MUST be the final symbol
; defined, or else HERE will point somewhere inside the Forth
; kernel.  We do not want that, for hopefully obvious reasons.

	align	8
_dxforth_end:
_end:
