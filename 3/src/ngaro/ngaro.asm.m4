define(`vmiget', `ori	$1, vip, 0
		slli	$1, $1, 2
		add	$1, $1, vbase
		lw	$1, 0($1)')dnl
define(`vmprim', `divert(1)dnl
		jal	x0, vm_$1
divert(0)dnl
vm_$1:
		$2
		jalr	x0, 0(ra)')dnl
define(`vmbinop', `vmprim(`$1', `lw	t0, 0(dp)
		$1	dt, t0, dt
		add	dp, dp, 4')')dnl
define(`vmjump', `vmiget(t0)
		addi	vip, t0, -1')dnl
define(`vmdup', `addi	dp, dp, -4
		sw	dt, 0(dp)')dnl
define(`vm2drop', `lw	dt, 4(dp)
		addi	dp, dp, 8')dnl
define(`vmdrop', `lw	dt, 0(dp)
		addi	dp, dp, 4')dnl

initial_vbase	= 1048576
initial_vport	= initial_vbase-1024
initial_ap	= initial_vport
initial_dp	= initial_ap-4096
initial_sp	= initial_dp-4096

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
		addi	vip, x0, -4

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


; Virtual Instruction Pump
;
; vbase must point to offset 0 of the virtual machine image in RAM.
; vport must point to virtual I/O port 0.
; ap must point to th top of the VM's return/address stack.
; dp must point to the top of the VM's data stack.
; vip must contain an offset in the range [0, n) as word offset into vbase.
; sp must point to the top of the interpreter's stack.

		align	8
vm_op_tbl_ptr:	dword	b+vm_op_table
vm_cycle:	addi	sp, sp, -8
		sd	ra, 0(sp)
		auipc	gp, 0
vmc0:		addi	vip, vip, 1
		vmiget(t0)
		addi	t1, x0, 31
		bge	t0, t1, vm_call
		slli	t0, t0, 3
		ld	t1, vm_op_tbl_ptr-vmc0(gp)
		add	t0, t0, t1
		jalr	ra, 0(t0)
		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)

vm_call:	addi	ap, ap, -4
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
vmprim(`fetch', `add	dt, dt, vbase
		lw	dt, 0(dt)')
vmprim(`store', `add	dt, dt, vbase
		lw	t0, 0(dp)
		sw	t0, 0(dt)
		vm2drop')

vmbinop(`add')
vmbinop(`sub')
vmprim(`multiply', `ebreak')
vmprim(`divmod', `ecall')
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
vmprim(`in', `add	dt, dt, vport
		lw	dt, 0(dt)')
vmprim(`out', `add	dt, dt, vport
		lw	t0, 0(dp)
		sw	t0, 0(dt)
		vm2drop')

vm_wait:	jal	x0, *

		align	8
vm_op_table:
undivert(1)dnl
		jal	x0, vm_wait

