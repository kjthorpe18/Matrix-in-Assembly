.data
	prompt: .asciiz "Please enter number of columns (1-79): "
	col: .space 80

.text

begin:	
	li $v0, 30
	syscall
	move $t0, $a0	# Gets current time and moves it to $t0
	
	li $v0, 40
	li $a0, 0
	add $a1, $zero, $t0	# Sets seed to current time in $t0
	syscall
	
	la $a0, prompt		# Requests and stores number of columns from user
	li $v0, 4
	syscall
	
	li $v0, 5
	syscall
	move $a0, $v0	
	add $s0, $zero, $a0	# Holds # of columns to display
	
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	jal randomCol		#initializes terminal with number of columns
	lw $s0, 0($sp)
	addi $sp, $sp, 4

	# Interate through array of speeds repeatedly and update columns.
	# When a trail leaves the screen, randomly select a new column with randomCol(1)
	
	li $s6, 0	# Number of times the array was traversed
reset:	addi $s6, $s6, 1
	la $s1, col
	li $s2, 0

animate:
	beq $s2, 80 reset	
	
	lb $s3, 0($s1)	#s3 holds speed
	# If number of iterations is divisible by speed, update column
	beqz $s3, next	#skip division if speed is 0
	divu $s6, $s3
	mfhi $s5
	beq $s5, 0, update
	
next:	
	addi $s1, $s1, 4
	addi $s2, $s2, 1
	
	j animate	
	
update: 	
	add $a0, $zero, $s2	#Column to be update passed as an argument
	
	addi $sp, $sp, -28
	sw $s0, 24($sp)
	sw $s1, 20($sp)
	sw $s2, 16($sp)
	sw $s3, 12($sp)
	sw $s4, 8($sp)
	sw $s5, 4($sp)
	sw $s6, 0($sp)
	jal updateColumn
	lw $s0, 24($sp)
	lw $s1, 20($sp)
	lw $s2, 16($sp)
	lw $s3, 12($sp)
	lw $s4, 8($sp)
	lw $s5, 4($sp)
	lw $s6, 0($sp)
	addi $sp, $sp, 28

	j next
	
	
	j end
	
	
	
#-------------------------------------------------------------------------------------
# Places first trails in random columns with random speeds
# a0: number of columns to be chosen
# a1: 
# v0: 
randomCol:
	move $t0, $a0		# $t0 is # of columns needed	
newRan:	beqz $t0, return
	la $t1, col		# $t1 is array
	li $a0, 0
	li $a1, 79
	li $v0, 42
	syscall		#Chooses random column (0-79)
	move $t2, $a0
	add $t7, $zero, $t2
loop:
	lb $t3, 0($t1)
	beqz $t2, storeSpeed
	
	subu $t2, $t2, 1
	addi $t1, $t1, 4
	j loop
	
	
storeSpeed:
	beqz $t3, store
	j newRan
store:	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal chooseSpeed
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	sb $v0, 0($t1)
	
#Store a random character in top of terminal
	li $s0, 0xffff8000
loop2:	beqz $t7, storeChar
	subu $t7, $t7, 1
	addi $s0, $s0, 4
	j loop2
	
cont:	
	subu $t0, $t0, 1
	j newRan
	
storeChar:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal randomChar
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	sll $v0, $v0, 24
	or $v0, $v0, 0xfa00
	
	sw $v0, 0($s0)
	j cont

return:
	jr $ra
#-----------------------------------------------End of RandomCol-------------------------------------

	
#----------------------------------------------------------------------------------------------------	
# Generates a random character, returns it	
# a0:
# a1:
# v0: Returned character
randomChar:
	li $a0, 0
	li $a1, 94
	li $v0, 42
	syscall
	addi $a0, $a0, 32	#Generates random integer, adds 32 to it to get ascii value range
	move $v0, $a0 
	jr $ra
	

#-----------------------------------------End randomChar---------------------------------------------



# Iterate through column top to bottom, update color, character depending on current color
# a0: Column to be updated
# v0: 
updateColumn:
	add $s6, $zero, $a0	# Holds column
	add $t6, $zero, $a0	# Holds column
	li $t5, 0xffff8000
	
again:	beqz $t6, foundCol
	addi $t6, $t6, -1
	addi $t5, $t5, 4
	j again
	
	
foundCol:
	add $s0, $zero, $t5	# holds address of col iterator
	li $s1, 0		# counter for row. if 40, end	
	
iterate:
	beq $s1, 40, checkFlag
	lw $s2, 0($s0)
	sll $s2, $s2, 8
	srl $s2, $s2, 8
	beq $s2, 0xfa00, top
	bge $s2, 0xa00, decr	#if brightness is greater or equal to 10
n:	
	addi $s0, $s0, 320	#Next Row
	addi $s1, $s1, 1
	j iterate
	
	
	
decr:	li $s5, 1		# Flag to show col was updated
	sub $s2, $s2, 0xa00

	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	jal randomChar	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	
	sll $v0, $v0, 24
	or $v0, $v0, $s2
	sw $v0, 0($s0)
	j n
	
#if character was 250 green value, add new char to next spot if it is not at the end of the terminal
top:
	li $s5, 1		# Flag to show col was updated
	sub $s2, $s2, 0xa00
	
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	jal randomChar	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	
	sll $v0, $v0, 24
	or $v0, $v0, $s2
	sw $v0, 0($s0)
	
	addi $s1, $s1, 1
	beq $s1, 40, checkFlag
	
	addi $s0, $s0, 320	#Next Row
	
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	jal randomChar	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	addi $s1, $s1, 1
	
	sll $v0, $v0, 24
	or $v0, $v0, 0xfa00
	sw $v0, 0($s0)
	
	addi $s0, $s0, 320	#Next Row
	addi $s1, $s1, 1
	
	j return2


# Checks to see if column was updated
checkFlag:
	beq $s5, 0, emptyCol
	j return2
	
	
	
#Column had no characters, turn to 0 in col array and choose a new col randomly
emptyCol:
	la $t5, col
	
again2:	beqz $s6, update2
	
	addi $t5, $t5 4
	subu $s6, $s6, 1
	j again2

update2:
	li $s7, 0
	sw $s7, 0($t5)
	
	addi $sp, $sp, -32
	sw $ra, 28($sp)
	sw $s0, 24($sp)
	sw $s1, 20($sp)
	sw $s2, 16($sp)
	sw $s3, 12($sp)
	sw $s4, 8($sp)
	sw $s5, 4($sp)
	sw $s6, 0($sp)
	li $a0, 1
	jal randomCol
	lw $ra, 28($sp)
	lw $s0, 24($sp)
	lw $s1, 20($sp)
	lw $s2, 16($sp)
	lw $s3, 12($sp)
	lw $s4, 8($sp)
	lw $s5, 4($sp)
	lw $s6, 0($sp)
	addi $sp, $sp, 32
	
	j return2
	
	
return2:
	jr $ra
	

#--------------------------------------End updateColumn--------------------------------------------

#--------------------------------------------------------------------------------------------------
# Choose a random speed (1-5) for column. 
# a0: 
# a1: 
# v0: Returned speed
chooseSpeed:
	li $a0, 0
	li $a1, 10
	li $v0, 42
	syscall
	addi $a0, $a0, 1
	move $v0, $a0
	jr $ra
#---------------------------------------End chooseSpeed---------------------------------------------

end:	# Terminates program
	li $v0, 10
	syscall
	
