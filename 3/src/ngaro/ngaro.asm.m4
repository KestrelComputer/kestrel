dnl
dnl This macro expands to code that fetches the next instruction word from the
dnl Ngaro virtual memory image.
dnl
define(`vmiget', `ori	$1, vip, 0
		slli	$1, $1, 2
		add	$1, $1, vbase
		lw	$1, 0($1)')dnl
dnl
dnl This macro builds the jump table for primitive dispatch, as well as declares
dnl the primitive at the point of instantiation.
dnl
define(`vmprim', `divert(1)dnl
		jal	x0, vm_$1
divert(0)dnl
vm_$1:
		$2
		jalr	x0, 0(ra)')dnl
dnl
dnl A binary operator is any primitive wrapping a two-operand arithmetic or
dnl logical operation that possesses the commutative property, and as a special
dnl case, subtraction.
dnl
define(`vmbinop', `vmprim(`$1', `lw	t0, 0(dp)
		$1	dt, t0, dt
		addi	dp, dp, 4')')dnl
dnl
dnl This code implements a Ngaro virtual machine jump operation.
dnl
define(`vmjump', `vmiget(t0)
		addi	vip, t0, -1')dnl
dnl
dnl This code duplicates the top of stack.
dnl
define(`vmdup', `addi	dp, dp, -4
		sw	dt, 0(dp)')dnl
dnl
dnl This code drops two items from the stack.
dnl
define(`vm2drop', `lw	dt, 4(dp)
		addi	dp, dp, 8')dnl
dnl
dnl This code drops one item from the stack.
dnl
define(`vmdrop', `lw	dt, 0(dp)
		addi	dp, dp, 4')dnl

initial_vbase	= 1048576
initial_vport	= initial_vbase-1024
initial_ap	= initial_vport
initial_dp	= initial_ap-65536
initial_sp	= initial_dp-65536

; Virtual Machine Cold(ish) Boot
		align	8
vm_start:	or	x0, x0, x0
		jal	ra, vm_start0
		dword	initial_vbase
		dword	initial_vport
		dword	initial_ap
		dword	initial_dp
		dword	initial_sp
		dword	b+retroImage
		dword	b+retroImageEnd
vm_start0:	ld	vbase, 0(ra)
		ld	vport, 8(ra)
		ld	ap, 16(ra)
		ld	dp, 24(ra)
		ld	sp, 32(ra)
		addi	vip, x0, -1
		ori	abase, ap, 0
		ori	dbase, dp, 0

	; copy VM image to its final resting place in RAM

		ld	t0, 40(ra)
		ori	t1, vbase, 0
		ld	t3, 48(ra)

vm_copyimg:	lb	t2, 0(t0)
		sb	t2, 0(t1)
		addi	t0, t0, 1
		addi	t1, t1, 1
		bne	t0, t3, vm_copyimg

vm_mainloop:	jal	ra, vm_cycle
		jal	x0, vm_mainloop


; I/O handling.

vm_do_io:	addi	sp, sp, -8
		sd	ra, 0(sp)

		lw	t0, 0(vport)
		bne	t0, x0, vmdoio0

		; console input

		lw	t0, 4(vport)
		beq	t0, x0, vmdoio1
		jal	ra, biosChkChar
		beq	a0, x0, *+8
		jal	ra, biosGetChar
		sw	a0, 4(vport)

		; console output

vmdoio1:	lw	t0, 8(vport)
		beq	t0, x0, vmdoio2
		sw	x0, 8(vport)
		ori	a0, dt, 0
		jal	ra, biosPutChar
		vmdrop

		; VM queries

vmdoio2:	lw	t0, 20(vport)
		beq	t0, x0, vmdoio3

		addi	t1, x0, -1	; How much VM memory, in cells?
		bne	t0, t1, vmdoio2a
		addi	t0, x0, 1
		slli	t0, t0, 18
		sw	t0, 20(vport)
		jal	x0, vmdoio3

vmdoio2a:	addi	t1, x0, -5	; How big is your data stack?
		bne	t0, t1, vmdoio2b
		sub	t0, dbase, dp
		srai	t0, t0, 2
		sw	t0, 20(vport)
		jal	x0, vmdoio3

vmdoio2b:	addi	t1, x0, -6	; How big is your return/address stack?
		bne	t0, t1, vmdoio2c
		sub	t0, abase, ap
		srai	t0, t0, 2
		sw	t0, 20(vport)
		jal	x0, vmdoio3

vmdoio2c:	addi	t0, x0, -13	; How big is a cell, in bits?
		bne	t0, t1, vmdoio2d
		addi	t0, x0, 32	; Even on a 64-bit machine like Kestrel-3
		sw	t0, 20(vport)
		jal	x0, vmdoio3

vmdoio2d:	addi	t0, x0, -16	; What capacity is the data stack?
		bne	t0, t1, vmdoio2e
		addi	t0, x0, 1024
		sw	t0, 20(vport)
		jal	x0, vmdoio3

vmdoio2e:	addi	t0, x0, -17	; What capacity is the return stack?
		bne	t0, t1, vmdoio2f
		addi	t0, x0, 1024
		sw	t0, 20(vport)
		jal	x0, vmdoio3

vmdoio2f:	sw	x0, 20(vport)

vmdoio3:
vmdoio0:	ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)


; Virtual Instruction Pump
;
; vbase must point to offset 0 of the virtual machine image in RAM.
; vport must point to virtual I/O port 0.
; ap must point to th top of the VM's return/address stack.
; dp must point to the top of the VM's data stack.
; vip must contain an offset in the range [0, n) as word offset into vbase.
; sp must point to the top of the interpreter's stack.

_dbg1:		addi	sp, sp, -32
		sd	ra, 0(sp)
		sd	t0, 8(sp)
		sd	gp, 16(sp)
		sd	t6, 24(sp)
		auipc	gp, 0

_dbg10:		ori	a0, x0, 32
		jal	ra, biosPutChar
		jal	ra, biosPutChar
		jal	ra, biosPutChar
		jal	ra, biosPutChar
		jal	ra, biosPutChar
		jal	ra, biosPutChar
		jal	ra, biosPutChar
		jal	ra, biosPutChar
		ori	a0, vip, 0
		jal	ra, puthex32
		ori	a0, x0, 32
		jal	ra, biosPutChar

		sub	a0, dbase, dp
		srai	a0, a0, 2
		jal	ra, puthex32
		ori	a0, x0, 32
		jal	ra, biosPutChar
		jal	ra, biosPutChar

		ld	t0, 8(sp)
		slli	t0, t0, 3
		add	a0, t0, gp
		addi	a0, a0, vm_nm_tbl-_dbg10
		addi	a1, x0, 8
		jal	ra, biosPutStrC
		addi	a0, x0, 10
		jal	ra, biosPutChar

		ld	t6, 24(sp)
		ld	gp, 16(sp)
		ld	t0, 8(sp)
		ld	ra, 0(sp)
		addi	sp, sp, 32
		jalr	x0, 0(ra)

_dbg2:		addi	sp, sp, -16
		sd	t0, 0(sp)
		sd	ra, 8(sp)
		ori	t0, x0, 31
		jal	ra, _dbg1
		ld	ra, 8(sp)
		ld	t0, 0(sp)
		addi	sp, sp, 16
		jalr	x0, 0(ra)

vm_nm_tbl:	byte	"NOP....."
		byte	"LIT....."
		byte	"DUP....."
		byte	"DROP...."
		byte	"SWAP...."
		byte	"PUSH...."
		byte	"POP....."
		byte	"LOOP...."
		byte	"JUMP...."
		byte	"RETURN.."
		byte	"GT_JUMP."
		byte	"LT_JUMP."
		byte	"NE_JUMP."
		byte	"EQ_JUMP."
		byte	"FETCH..."
		byte	"STORE..."
		byte	"ADD....."
		byte	"SUB....."
		byte	"MULTIPLY"
		byte	"DIVMOD.."
		byte	"AND....."
		byte	"OR......"
		byte	"XOR....."
		byte	"SLL....."
		byte	"SRA....."
		byte	"ZEROEXIT"
		byte	"INC....."
		byte	"DEC....."
		byte	"IN......"
		byte	"OUT....."
		byte	"WAIT...."
		byte	"  CALL  "

		align	8
vm_op_tbl_ptr:	dword	b+vm_op_table
vm_cycle:	addi	sp, sp, -8
		sd	ra, 0(sp)
		auipc	gp, 0
vmc0:		addi	vip, vip, 1
		vmiget(t0)
		addi	t1, x0, 31
		bge	t0, t1, vm_call
		;jal	ra, _dbg1
		slli	t0, t0, 2
		ld	t1, vm_op_tbl_ptr-vmc0(gp)
		add	t0, t0, t1
		jalr	ra, 0(t0)
		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)

vm_call:	;jal	ra, _dbg2
		addi	ap, ap, -4
		sw	vip, 0(ap)
		addi	vip, t0, -1
		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)

; Virtual Instruction Handlers
vmprim(`nop', `')
vmprim(`lit', `vmdup
		addi	vip, vip, 1
		vmiget(dt)')
vmprim(`dup', `vmdup')
vmprim(`drop', `vmdrop')
vmprim(`swap', `ori	t0, dt, 0
		lw	dt, 0(dp)
		sw	t0, 0(dp)')
vmprim(`push', `addi	ap, ap, -4
		sw	dt, 0(ap)
		vmdrop')
vmprim(`pop', `vmdup
		lw	dt, 0(ap)
		addi	ap, ap, 4')
vmprim(`loop', `addi	dt, dt, -1
		addi	vip, vip, 1
		addi	t0, x0, 1
		blt	dt, t0, vmlF
		vmjump
		jalr	x0, 0(ra)
vmlF:		vmdrop')
vmprim(`jump', `addi	vip, vip, 1
		vmjump')
vmprim(`return', `lw	vip, 0(ap)
		addi	ap, ap, 4')
vmprim(`gt_jump', `addi	vip, vip, 1
		addi	t1, dt, 1
		lw	t0, 0(dp)
		vm2drop
		blt	t0, t1, vmgtjF
		vmjump
vmgtjF:')
vmprim(`lt_jump', `addi	vip, vip, 1
		addi	t1, dt, 0
		lw	t0, 0(dp)
		vm2drop
		bge	t0, t1, vmltF
		vmjump
vmltF:')
vmprim(`ne_jump', `addi	vip, vip, 1
		addi	t1, dt, 0
		lw	t0, 0(dp)
		vm2drop
		beq	t0, t1, vmneF
		vmjump
vmneF:')
vmprim(`eq_jump', `addi vip, vip, 1
		addi	t1, dt, 0
		lw	t0, 0(dp)
		vm2drop
		bne	t0, t1, vmeqF
		vmjump
vmeqF:')
vmprim(`fetch', `slli	dt, dt, 2
		add	dt, dt, vbase
		lw	dt, 0(dt)')
vmprim(`store', `slli	dt, dt, 2
		add	dt, dt, vbase
		lw	t0, 0(dp)
		sw	t0, 0(dt)
		vm2drop')

vmbinop(`add')
vmbinop(`sub')
vmprim(`multiply', `addi	sp, sp, -8
		sd	ra, 0(sp)
		ori	a1, dt, 0
		lw	a0, 0(dp)
		jal	ra, mathMultiply
		ori	dt, a0, 0
		addi	dp, dp, 4
		ld	ra, 0(sp)
		addi	sp, sp, 8')
vmprim(`divmod', `addi	sp, sp, -8
		sd	ra, 0(sp)
		ori	a2, dt, 0
		lw	a0, 0(dp)
		ori	a1, x0, 0
		bge	a0, x0, *+8
		ori	a1, a1, -1
		jal	ra, mathSDivMod
		sw	a1, 0(dp)
		ori	dt, a0, 0
		ld	ra, 0(sp)
		addi	sp, sp, 8')
vmbinop(`and')
vmbinop(`or')
vmbinop(`xor')
vmbinop(`sll')
vmbinop(`sra')
vmprim(`zero_exit', `bne	dt, x0, vmzeF
		vmdrop
		jal	x0, vm_return
vmzeF:')
vmprim(`inc', `addi	dt, dt, 1')
vmprim(`dec', `addi	dt, dt, -1')
vmprim(`in', `slli	dt, dt, 2
		add	dt, dt, vport
		lw	dt, 0(dt)')
vmprim(`out', `slli	dt, dt, 2
		add	dt, dt, vport
		lw	t0, 0(dp)
		sw	t0, 0(dt)
		vm2drop')

vm_wait:	addi	sp, sp, -8
		sd	ra, 0(sp)
		jal	ra, vm_do_io
		addi	t0, x0, 1
		sw	t0, 0(vport)
		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)

		align	8
vm_op_table:
undivert(1)dnl
		jal	x0, vm_wait

