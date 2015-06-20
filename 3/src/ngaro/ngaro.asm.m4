; Virtual Instruction Handlers
define(`vmprim', `vm_$1:
		$2
		jalr	x0, 0(ra)')dnl
define(`vmbinop', `vmprim(`$1', `lw	t0, 0(dp)
		$1	dt, t0, dt
		add	dp, dp, 4')')dnl
define(`vmjump', `lw	vip, 0(vip)
		addi	vip, vip, -1
		slli	vip, vip, 2')dnl
define(`vmdup', `addi	dp, dp, -4
		sw	dt, 0(dp)')dnl
define(`vm2drop', `lw	dt, 4(dp)
		addi	dp, dp, 8')dnl
define(`vmdrop', `lw	dt, 0(dp)
		addi	dp, dp, 4')dnl
vmprim(`nop', `')
vmprim(`lit', `vmdup
		addi	vip, vip, 4
		lw	dt, 0(vip)')
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
		addi	vip, vip, 4
		addi	t0, x0, 1
		blt	dt, t0, vmlF
		vmjump
vmlF:')
vmprim(`jump', `addi	vip, vip, 4
		vmjump')
vmprim(`return', `lw	vip, 0(ap)
		addi	ap, ap, 4')
vmprim(`gt_jump', `addi	vip, vip, 4
		addi	t1, dt, 1
		lw	t0, 0(dp)
		vm2drop
		blt	t0, t1, vmgtjF
		vmjump
vmgtjF:')
vmprim(`lt_jump', `addi	vip, vip, 4
		addi	t1, dt, 0
		lw	t0, 0(dp)
		vm2drop
		slt	t0, t0, t1
		beq	t0, x0, vmltF
		vmjump
vmltF:')
vmprim(`ne_jump', `addi	vip, vip, 4
		addi	t1, dt, 0
		lw	t0, 0(dp)
		vm2drop
		beq	t0, t1, vmneF
		vmjump
vmneF:')
vmprim(`eq_jump', `addi vip, vip, 4
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

