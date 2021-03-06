#  cpuburn-1.4:	 burnBX	  Chipset/DRAM Loading Utility
#  Copyright 2000  Robert J. Redelmeier.  All Right Reserved
#  Licensed under GNU General Public Licence 2.0.  No warrantee.
#  *** USE AT YOUR OWN RISK ***
 
.text
.globl _main
_main:
	movl 	4(%esp),%eax
	movl	$12, %ecx	# default  L = 4 MB
	subl 	$1,%eax		# 1 string -> no paramater
	jz 	no_size
	
	movl 	8(%esp),%eax	# address of strings
	movl 	4(%eax),%eax	# address of first paramater
	movzb 	(%eax),%ecx	# first parameter - a byte
no_size:
	subl	$12, %esp	# stack allocation
	decl	%ecx
	andl	$15, %ecx
	movl	$256, %eax
	shll	%cl, %eax
	movl	%eax, 4(%esp)	# save blocksize
	movl	$256*1024, %eax
	shrl	%cl, %eax
	movl	%eax, 8(%esp)	# save count blks / 512 MB

	movl	4(%esp), %ecx
	shrl	$4, %ecx
	movl	$buffer, %edi
	xorl	%eax, %eax
	notl	%eax
more:				# init fill of 2 cachelines
	movl	%eax, %edx	# qwords F-F-0-F , F-0-F-0 
	notl	%edx
	movl	%eax,  0(%edi)
	movl	%eax,  4(%edi)
	movl	%eax,  8(%edi)
	movl	%eax, 12(%edi)
	movl	%edx, 16(%edi)
	movl	%edx, 20(%edi)
	movl	%eax, 24(%edi)
	movl	%eax, 28(%edi)

	movl	%eax, 32(%edi)
	movl	%eax, 36(%edi)
	movl	%edx, 40(%edi)
	movl	%edx, 44(%edi)
	movl	%eax, 48(%edi)
	movl	%eax, 52(%edi)
	movl	%edx, 56(%edi)
	movl	%edx, 60(%edi)
	rcll	$1, %eax	# walking zero, 33 cycle
	leal	64(%edi), %edi	# odd inst to preserve CF
	decl	%ecx
	jnz	more

	cld
thrash:				# MAIN LOOP
	movl	8(%esp), %edx
mov_again:
	movl	$buffer, %esi
	movl	$buf2, %edi
	movl	4(%esp), %ecx
	rep			# move block up
	movsl

	movl	$buffer + 32, %edi
	movl	$buf2, %esi
	movl	4(%esp), %ecx
	subl	$8, %ecx
	rep			# move block back shifting
	movsl			#   by 1 cacheline

	movl	$buffer, %edi
	movl	$8, %ecx
	rep			# replace last c line
	movsl

	decl	%edx		# do again for 512 MB.
	jnz	mov_again

	movl	$buffer, %edi	# DATA CHECK
	xorl	%ecx, %ecx
.balign 16, 0x90
test:
	mov	0(%edi,%ecx,4), %eax
	cmp	%eax, 4(%edi,%ecx,4)
	jnz	error
	incl	%ecx
	incl	%ecx
	cmpl	4(%esp), %ecx
	jc	test
	jmp	thrash

error:				# error abend
	movl	$1, %eax	
	addl 	$12, %esp	# deallocate stack
	ret
.bss				# Data allocation
.balign 32
.lcomm	buffer,	 32 <<20	# reduce both to 8 <<20 for only
.lcomm	buf2,	 32 <<20	# 16 MB virtual memory available

#
