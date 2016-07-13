
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
		lw	dt, 0(dp)
		addi	dp, dp, 4

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
		bne	t0, t1, vmdoio2g
		sub	t0, abase, ap
		srai	t0, t0, 2
		sw	t0, 20(vport)
		jal	x0, vmdoio3

vmdoio2g:	addi	t1, x0, -9	; Exit the VM?
		bne	t0, t1, vmdoio2c
vmdoio2g0:	auipc	t1, 0
		addi	t1, t1, __exit_cmdblock - vmdoio2g0
		csrrw	x0, t1, $780
		sw	x0, 20(vport)
		jal	x0, vmdoio3
__exit_cmdblock: dword	0

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
_dbg10:		auipc	gp, 0

		ori	a0, x0, 32
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
vmc0:		auipc	gp, 0
		addi	vip, vip, 1
		ori	t0, vip, 0
		slli	t0, t0, 2
		add	t0, t0, vbase
		lw	t0, 0(t0)
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
vm_nop:
		
		jalr	x0, 0(ra)
vm_lit:
		addi	dp, dp, -4
		sw	dt, 0(dp)
		addi	vip, vip, 1
		ori	dt, vip, 0
		slli	dt, dt, 2
		add	dt, dt, vbase
		lw	dt, 0(dt)
		jalr	x0, 0(ra)
vm_dup:
		addi	dp, dp, -4
		sw	dt, 0(dp)
		jalr	x0, 0(ra)
vm_drop:
		lw	dt, 0(dp)
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_swap:
		ori	t0, dt, 0
		lw	dt, 0(dp)
		sw	t0, 0(dp)
		jalr	x0, 0(ra)
vm_push:
		addi	ap, ap, -4
		sw	dt, 0(ap)
		lw	dt, 0(dp)
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_pop:
		addi	dp, dp, -4
		sw	dt, 0(dp)
		lw	dt, 0(ap)
		addi	ap, ap, 4
		jalr	x0, 0(ra)
vm_loop:
		addi	dt, dt, -1
		addi	vip, vip, 1
		addi	t0, x0, 1
		blt	dt, t0, vmlF
		ori	t0, vip, 0
		slli	t0, t0, 2
		add	t0, t0, vbase
		lw	t0, 0(t0)
		addi	vip, t0, -1
		jalr	x0, 0(ra)
vmlF:		lw	dt, 0(dp)
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_jump:
		addi	vip, vip, 1
		ori	t0, vip, 0
		slli	t0, t0, 2
		add	t0, t0, vbase
		lw	t0, 0(t0)
		addi	vip, t0, -1
		jalr	x0, 0(ra)
vm_return:
		lw	vip, 0(ap)
		addi	ap, ap, 4
		jalr	x0, 0(ra)
vm_gt_jump:
		addi	vip, vip, 1
		addi	t1, dt, 1
		lw	t0, 0(dp)
		lw	dt, 4(dp)
		addi	dp, dp, 8
		blt	t0, t1, vmgtjF
		ori	t0, vip, 0
		slli	t0, t0, 2
		add	t0, t0, vbase
		lw	t0, 0(t0)
		addi	vip, t0, -1
vmgtjF:
		jalr	x0, 0(ra)
vm_lt_jump:
		addi	vip, vip, 1
		addi	t1, dt, 0
		lw	t0, 0(dp)
		lw	dt, 4(dp)
		addi	dp, dp, 8
		bge	t0, t1, vmltF
		ori	t0, vip, 0
		slli	t0, t0, 2
		add	t0, t0, vbase
		lw	t0, 0(t0)
		addi	vip, t0, -1
vmltF:
		jalr	x0, 0(ra)
vm_ne_jump:
		addi	vip, vip, 1
		addi	t1, dt, 0
		lw	t0, 0(dp)
		lw	dt, 4(dp)
		addi	dp, dp, 8
		beq	t0, t1, vmneF
		ori	t0, vip, 0
		slli	t0, t0, 2
		add	t0, t0, vbase
		lw	t0, 0(t0)
		addi	vip, t0, -1
vmneF:
		jalr	x0, 0(ra)
vm_eq_jump:
		addi vip, vip, 1
		addi	t1, dt, 0
		lw	t0, 0(dp)
		lw	dt, 4(dp)
		addi	dp, dp, 8
		bne	t0, t1, vmeqF
		ori	t0, vip, 0
		slli	t0, t0, 2
		add	t0, t0, vbase
		lw	t0, 0(t0)
		addi	vip, t0, -1
vmeqF:
		jalr	x0, 0(ra)
vm_fetch:
		slli	dt, dt, 2
		add	dt, dt, vbase
		lw	dt, 0(dt)
		jalr	x0, 0(ra)
vm_store:
		slli	dt, dt, 2
		add	dt, dt, vbase
		lw	t0, 0(dp)
		sw	t0, 0(dt)
		lw	dt, 4(dp)
		addi	dp, dp, 8
		jalr	x0, 0(ra)

vm_add:
		lw	t0, 0(dp)
		add	dt, t0, dt
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_sub:
		lw	t0, 0(dp)
		sub	dt, t0, dt
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_multiply:
		addi	sp, sp, -8
		sd	ra, 0(sp)
		ori	a1, dt, 0
		lw	a0, 0(dp)
		jal	ra, mathMultiply
		ori	dt, a0, 0
		addi	dp, dp, 4
		ld	ra, 0(sp)
		addi	sp, sp, 8
		jalr	x0, 0(ra)
vm_divmod:
		addi	sp, sp, -8
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
		addi	sp, sp, 8
		jalr	x0, 0(ra)
vm_and:
		lw	t0, 0(dp)
		and	dt, t0, dt
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_or:
		lw	t0, 0(dp)
		or	dt, t0, dt
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_xor:
		lw	t0, 0(dp)
		xor	dt, t0, dt
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_sll:
		lw	t0, 0(dp)
		sll	dt, t0, dt
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_sra:
		lw	t0, 0(dp)
		sra	dt, t0, dt
		addi	dp, dp, 4
		jalr	x0, 0(ra)
vm_zero_exit:
		bne	dt, x0, vmzeF
		lw	dt, 0(dp)
		addi	dp, dp, 4
		jal	x0, vm_return
vmzeF:
		jalr	x0, 0(ra)
vm_inc:
		addi	dt, dt, 1
		jalr	x0, 0(ra)
vm_dec:
		addi	dt, dt, -1
		jalr	x0, 0(ra)
vm_in:
		slli	dt, dt, 2
		add	dt, dt, vport
		lw	dt, 0(dt)
		jalr	x0, 0(ra)
vm_out:
		slli	dt, dt, 2
		add	dt, dt, vport
		lw	t0, 0(dp)
		sw	t0, 0(dt)
		lw	dt, 4(dp)
		addi	dp, dp, 8
		jalr	x0, 0(ra)

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
		jal	x0, vm_nop
		jal	x0, vm_lit
		jal	x0, vm_dup
		jal	x0, vm_drop
		jal	x0, vm_swap
		jal	x0, vm_push
		jal	x0, vm_pop
		jal	x0, vm_loop
		jal	x0, vm_jump
		jal	x0, vm_return
		jal	x0, vm_gt_jump
		jal	x0, vm_lt_jump
		jal	x0, vm_ne_jump
		jal	x0, vm_eq_jump
		jal	x0, vm_fetch
		jal	x0, vm_store
		jal	x0, vm_add
		jal	x0, vm_sub
		jal	x0, vm_multiply
		jal	x0, vm_divmod
		jal	x0, vm_and
		jal	x0, vm_or
		jal	x0, vm_xor
		jal	x0, vm_sll
		jal	x0, vm_sra
		jal	x0, vm_zero_exit
		jal	x0, vm_inc
		jal	x0, vm_dec
		jal	x0, vm_in
		jal	x0, vm_out
		jal	x0, vm_wait

