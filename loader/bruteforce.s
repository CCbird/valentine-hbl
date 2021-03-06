	.text
	.align	2
	.set	nomips16

	.globl	freemem_bruteforce
	.ent	freemem_bruteforce
	.type	freemem_bruteforce, @function
freemem_bruteforce:
	.set	noreorder

	lui	$a3, %hi(sceKernelGetBlockHeadAddr)
	lw	$a2, %lo(sceKernelGetBlockHeadAddr) + 4($a3)

	lui	$a3, %hi($loop) + 0x40000000
	sw	$a2, %lo($loop)($a3)

	lui	$a3, %hi($loop)
	cache	0x14, %lo($loop)($a3)

	addiu	$sp, $sp, -12
	sw	$s0, 0($sp)
	sw	$s1, 4($sp)
	sw	$ra, 8($sp)

	move	$s0, $a0
	move	$s1, $a1

$loop:
	nop
	addiu	$s0, $s0, 1
	bnel	$v0, $s1, $loop
	move	$a0, $s0

	addiu	$a0, $s0, -1

	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$ra, 8($sp)

	j	sceKernelFreePartitionMemory
	addiu	$sp, $sp, 12

	.end	freemem_bruteforce
	.size	freemem_bruteforce, .-freemem_bruteforce
