#####################################################################
#
# CSC258H Winter 2021 Assembly Final Project 
# University of Toronto, St. George
#
# Student: Affanullah Siddiqui,
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256 
# - Base Address for Display: 0x10008000 ($gp) 
# 
# Which milestone is reached in this submission? 
# (See the project handout for descriptions of the milestones) 
# - Milestone 4
#  - Multiple lives
#  - 4 hit mushroom
# 
# Any additional information that the TA needs to know: 
#
# 
##################################################################### 

.data
	displayAddress:	.word 0x10008000
	bugLocation: .word 1007
	centipedeLocation: .space 40
	centipedeDirection: .space 40
	heart1: .word 34
	heart2: .word 36
	heart3: .word 38
	lives: .word 3
	mushrooms: .space 120
	mushroomHits: .space 120
	blackColour: .word 0x000000
	centipedeBodyColour: .word 0x087218
	centipedeHeadColour: .word 0x00ff2b
	bugBlasterColour: .word 0x21a7b4
	heartColour: .word 0xbd1fbe
	mushroomColour: .word 0xbd8f1f
	dartColour: .word 0xffa000
	canShoot: .word 0
	dartLocation: .word 975
	flea: .word 465
	fleaColour: .word 0x969696
	hitCount: .word 0
	
.text 

Start:
	jal clear_screen
	addi $t0, $zero, 3
	sw $t0, lives
	jal print_start
	li $v0, 32
 	li $a0, 50
 	syscall
Start_loop:	
	lw $t8, 0xffff0000
	beq $t8, 1, check_s
	
	li $v0, 32
 	li $a0, 100
 	syscall
	
	j Start_loop
	

check_s:
	lw $t2, 0xffff0004
	beq $t2, 0x73, respond_to_s
	j Start_loop

respond_to_s:
	jal clear_screen
	

	jal generate_mushrooms
Initialize:
	sw $zero, hitCount
	addi $t0, $zero, 465
	sw $t0, flea
	jal clear_screen
	jal reset_centipede_location
	jal disp_centipede
	jal draw_bug
	jal draw_hearts
	jal draw_mushrooms
	jal draw_flea
Loop:
    	jal draw_mushrooms
	jal move_centipede
	jal disp_centipede
	jal check_keystroke
	jal move_dart
	jal draw_dart
	jal draw_bug
	jal move_flea
	jal draw_flea
	
	li $v0, 32
 	li $a0, 35
 	syscall
 

	j Loop	

Exit:
	li $v0, 10			# terminate the program gracefully
	syscall


# function to display a static centiped	
disp_centipede:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t0, hitCount		# store the number of times the centipede has been hit into $t0
	beq $t0, 3, disp_cent_return	# if max hits is reached, return
	
	addi $a3, $zero, 10	 	# load a3 with the loop count (10)
	la $a1, centipedeLocation 	# load the address of the array into $a1
	la $a2, centipedeDirection 	# load the address of the array into $a2
	lw $t2, displayAddress  	# $t2 stores the base address for display
	addi $t8, $zero, 1		# $t8 stores 1 (check for head)

arr_loop:				#iterate over the loops elements to draw each body in the centiped
	lw $t1, 0($a1)		 	# load a word from the centipedLocation array into $t1
	lw $t5, 0($a2)		 	# load a word from the centipedDirection  array into $t5
	#####
	beq $a3, $t8, paint_head	# if statement to see if we're at the last element so we can paint the head a different colour
	lw $t3, centipedeBodyColour	# $t3 stores the centipede colour code (green)
	
	sll $t4,$t1, 2			# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4		# $t4 is the address of the old bug location
	sw $t3, 0($t4)			# paint the body with green
	b decrement
paint_head:
	lw $t3, centipedeHeadColour	# $t3 stores the head colour code (light green)
	
	sll $t4,$t1, 2			# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4		# $t4 is the address of the old bug location
	sw $t3, 0($t4)			# paint the head with light_green
decrement:	
	addi $a1, $a1, 4	 	# increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 	# decrement $a3 by 1
	bne $a3, $zero, arr_loop
	
disp_cent_return:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4	
	jr $ra

# function to reset centipede location to initial location
reset_centipede_location:
	la $a1, centipedeLocation	# load the address of the array centipedeLocation into $a1
	la $a2, centipedeDirection
	addi $t0, $zero, 10		# store loop count in $t0
	addi $t1, $zero, 40		# store first position of array in $t1
	addi $t2, $zero, 1		# store the value 1 in $t2
reset_loop:
	sw $t1, 0($a1)			# centipedeLocation[i] = position
	sw $t2, 0($a2)			# centipedeDirection[i] = 1
dec:
	addi $a1, $a1, 4		# increment $a1 by one to point to next element in array
	addi $a2, $a2, 4		# increment $a2 by one to point to next element in array
	addi $t0, $t0, -1		# decrement loop count by 1
	addi $t1, $t1, 1		# increment position by 1
	bne $t0, $zero, reset_loop	# loop until $t0 = 0
	
	jr $ra

# function to move the centipede
move_centipede:
	lw $t0, hitCount		# store the number of times the centipede has been hit into $t0
	beq $t0, 3, term		# if max hits is reached, return
	
	addi $a3, $zero, 10	 	# load a3 with the loop count (10)
	la $a1, centipedeLocation 	# load the address of the array into $a1
	la $a2, centipedeDirection 	# load the address of the array into $a2
	# paint old tail black:
	lw $t2, displayAddress  	# $t2 stores the base address for display
	lw $t1, 0($a1)		 	# load a word from the centipedLocation array into $t1
	lw $t3, blackColour		# $t3 stores the black colour code
	sll $t4, $t1, 2			# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4		# $t4 is the address of the old tail
	sw $t3, 0($t4)			# paint old tail black
	
	
move_loop:
	# initialize variables
	addi $t2, $zero, 32		# store 32 in $t2 for division
	addi $t3, $zero, 31		# store 31 in $t3 for remainder check
	addi $t4, $zero, 1		# store 1 in $t4 for direction check (right)
	addi $t6, $zero, -1		# store -1 in $t6 for direction check (left)
	
	lw $t1, 0($a1)		 	# load a word from the centipedLocation array into $t1 ($t1 = location[i])
	lw $t5, 0($a2)		 	# load a word from the centipedDirection array into $t5 ($t5 = direction[i])
	div $t1, $t2			# divide location[i] by 32
	mfhi $t7			# store remainder of division in $t7

	bne $t7, $t3, check_left	# if statement to first check if on right edge
	beq $t5, $t4, dir_right		# if statement to check if direction[i] is 1
	add $t8, $t1, $t5		# store location[i] + direction[i] into $t8
	sw $t8, 0($a1)			# location[i] = $t8
	b increment
dir_right:
	addi $t2, $zero, 32		# store 32 in $t2 for division
	add $t8, $t1, $t2		# $t8 = location[i] + 32
	sw $t8, 0($a1)			# location[i] = $t8
	sw $t6, 0($a2)			# direction[i] = $t6 (-1)
	b increment
check_left:
	bne $t7, $zero, in_middle
	beq $t5, $t6, dir_left		# if statement to check if direction[i] is -1
	add $t8, $t1, $t5		# store location[i] + direction[i] into $t8
	sw $t8, 0($a1)			# location[i] = $t8
	b increment
dir_left:
	addi $t2, $zero, 32		# store 32 in $t2 for division
	add $t8, $t1, $t2		# $t8 = location[i] + 32
	sw $t8, 0($a1)			# location[i] = $t8
	sw $t4, 0($a2)			# direction[i] = $t6 (1)
	b increment
in_middle:
	add $t8, $t1, $t5		# store location[i] + direction[i] into $t8
	
check_mushroom_collison:
	lw $t2, displayAddress  	# $t2 stores the base address for display
	sll $t3, $t8, 2			# store bias of potential new body location in memory
	add $t3, $t3, $t2		# location of potential new body part on bitmap
	lw $t2, 0($t3)			# store the colour of the potential new location in $t2
	li $t9, 0xbd8f1f		# store the colour of a mushroom
	lw $t3, bugBlasterColour	# store colour of bug blaster
	beq $t2, $t9, check_dir
	beq $t2, $t3, bug_hit	
	sw $t8, 0($a1)			# location[i] = $t8
	b increment

check_dir:
	beq $t5, $t4, dir_right		# if direction[i] == 1, go to the code that handles right direction
	beq $t5, $t6, dir_left		# if direction[i] == -1, go to code that handles left direction
	

bug_hit:
	lw $t5, lives			# store num lives in $t5
	addi $t5, $t5, -1		# decrement life count
	sw $t5, lives			# update life count
	j Initialize
	div 
increment:	
	addi $a1, $a1, 4	 	# increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 	# decrement $a3 by 1
	bne $a3, $zero, move_loop
	b move_cent_return
	
term:
	lw $t5, lives			# store num lives in $t5
	addi $t5, $t5, -1		# decrement life count
	sw $t5, lives			# update life count
	j Initialize

move_cent_return:
	jr $ra	
	
# function to draw bug blaster

draw_bug:
	la $t0, bugLocation		# load the address of buglocation from memory
	lw $t1, 0($t0)			# load the bug location itself in t1
	
	lw $t2, displayAddress  	# $t2 stores the base address for display
	
	sll $t4,$t1, 2			# $t4 the bias of the old buglocation
	add $t4, $t2, $t4		# $t4 is the address of the old bug location

	lw $t3, bugBlasterColour	# $t3 stores the bug colour code (blue)
	
	sw $t3, 0($t4)			# paint the first (top-left) unit blue.
	jr $ra
	
# function to draw hearts:
draw_hearts:
	
	lw $t1, lives			# load the address of lives from memory
	#lw $t1, 0($t0)			# load the number of lives into $t1
	
	beq $t1, $zero, Start		# if no more lives, end game
	
	lw $t2, heartColour		# store the colour of the heart (pink) in $t2
	lw $t3, displayAddress  	# $t2 stores the base address for display
	la $t4, heart1			# load the address of heart1 from memory
	lw $t5, 0($t4)			# load the heart1 location itself into $t5
	sll $t6, $t5, 2			# $t6 the bias of heart1
	add $t7, $t3, $t6		# $t7 is the address of heart1
	sw $t2, 0($t7)			# paint the heart location pink
	addi $t8, $zero, 2		# $t8 holds the value 2 to check if more than 1 heart needs to be drawn
	
	blt $t1, $t8, end_hearts	# check to see if more than 1 heart needs to be drawn
	la $t4, heart2			# load the address of heart2 from memory
	lw $t5, 0($t4)			# load the heart2 location itself into $t5
	sll $t6, $t5, 2			# $t6 the bias of heart2
	add $t7, $t3, $t6		# $t7 is the address of heart2
	sw $t2, 0($t7)			# paint the heart location pink
	addi $t8, $zero, 3		# $t8 holds the value 3 to check if more than 2 hearts need to be drawn
	
	blt $t1, $t8, end_hearts	# check to see if more than 2 hearts need to be drawn
	la $t4, heart3			# load the address of heart3 from memory
	lw $t5, 0($t4)			# load the heart3 location itself into $t5
	sll $t6, $t5, 2			# $t6 the bias of heart2
	add $t7, $t3, $t6		# $t7 is the address of heart2
	sw $t2, 0($t7)			# paint the heart location pink
	
end_hearts:
	jr $ra
	
# function to generate random mushrooms:

generate_mushrooms:

	la $t0, mushrooms		# load the address of mushrooms into $t0
	la $t9, mushroomHits		# load the address of mushroom hits into $t9
	addi $t1, $zero, 0		# $t1 holds i = 0
	addi $t2, $zero, 20		# $t2 holds 20
gen_shroom_loop:
	beq $t1, $t2, end_generate	# exit loop when i = 20
	sll $t3, $t1, 2			# $t3 = $t1 * 4 = i * 4 = offset
	add $t4, $t0, $t3		# $t4 = addr(mushrooms) + i*4 = addr(mushrooms[i])
	add $s0, $t9, $t3		# $t9 = addr(mushroomHits) + i*4 = addr(mushroomHits[i])
gen_rand:
	li $v0, 42			# invoke random_num generator
 	li $a0, 0			# put id = 0 into $a0
 	li $a1, 669			# set max to 669
 	syscall				# intiate syscall
 	addi $t5, $a0, 161		# place random num + 129 (to get proper range) into $t5
 	addi $t6, $zero, 32		# store 32 in $t6 (for division and edge checking)
 	addi $t7, $zero, 31		# store 31 in $t7 (for remainder edge checking)
 	div $t5, $t6			# divide $t5 (rand_num) by $t6 (32)
 	mfhi $t8			# store remainder of division in $t8
 	beq $t8, $t7, gen_rand		# random number is on right_edge so generate new number (remainder == 31)
 	beqz $t8, gen_rand		# random number is on left_edge so generate new number (remainder == 0)
 	sw $t5, 0($t4)			# store random number in mushrooms[i]
 	sw $zero, 0($s0)		# mushroomHits[i] = 0
 gen_shroom_increment:
 	addi, $t1, $t1, 1		# i++
 	j gen_shroom_loop		# jump to loop condition check
 end_generate:
 	jr $ra				# return to caller
		
# function to draw mushrooms:

draw_mushrooms:
	
	addi $a3, $zero, 20	 	# load a3 with the loop count (20)
	la $a1, mushrooms	 	# load the address of the array into $a1
	la $a2, mushroomHits		# load the address of the array mushroomHits into $a2
	lw $t2, displayAddress  	# $t2 stores the base address for display

draw_mush_loop:				# iterate over the loops elements to draw each mushroom in the array
	lw $t1, 0($a1)		 	# load a word from the mushroom array into $t1
	lw $t9, 0($a2)			# load a word from the mushroomHits array into $t9
	#####
	bge $t9, 4, paint_black		# if max hits have been reached for this mushroom, paint it black
	lw $t3, mushroomColour		# $t3 stores the mushroom colour code (yellow)
	b paint
paint_black:
	lw $t3, blackColour		# $t3 stores the black colour code
paint:	
	sll $t4,$t1, 2			# $t4 is the bias of the mushroom location in memory (offset*4)
	add $t4, $t2, $t4		# $t4 is the address of the mushroom location
	sw $t3, 0($t4)			# paint the mushroom yellow
	
draw_shroom_decrement:	
	addi $a1, $a1, 4	 	# increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4		# increment $a2 by one, to point to next element in the array
	addi $a3, $a3, -1	 	# decrement $a3 by 1
	bne $a3, $zero, draw_mush_loop	# jump to loop condition check
	
draw_mushroom_return:
	jr $ra
						

# function to draw dart:

draw_dart:
	la $t6, canShoot		# load the address of flag_variable in $t6
	lw $t5, 0($t6)			# load the value of the flag_variable for shooting darts into $t5
	beqz $t5, end_draw_dart		# if flag is 0, don't draw
	la $t0, dartLocation		# load the address of dartLocation from memory
	lw $t1, 0($t0)			# load the dart location itself in t1
	
	lw $t2, displayAddress  	# $t2 stores the base address for display
	
	sll $t4,$t1, 2			# $t4 the bias of the old dart location
	add $t4, $t2, $t4		# $t4 is the address of the old dart location

	lw $t3, dartColour		# $t3 stores the dart colour code (orange)
	
	sw $t3, 0($t4)			# paint the unit orange.
end_draw_dart:
	jr $ra	


# function to move the dart:

move_dart:
	lw $t5, canShoot		# load the value of the flag_variable for shooting darts into $t5
	lw $t1, dartLocation		# load the dart location itself in t1	
	addi $t3, $zero, 128		# store 128 in $t3
	beqz $t5, end_move_dart		# if flag is 0, don't move
	
	lw $t2, displayAddress  	# $t2 stores the base address for display
	
	sll $t4,$t1, 2			# $t4 the bias of the old dart location
	add $t4, $t2, $t4		# $t4 is the address of the old dart location
	lw $t7, blackColour		# $t3 stores black
	sw $t7, 0($t4)
	
	
	blt $t1, $t3, reached_top	# if location < 128, we are at the max allowed
	
	addi $t1, $t1, -32		# incrmement the location by 32 (go one row up)
	sll $t9, $t1, 2			# get bias of potential new location and store in $t9
	add $t9, $t9, $t2		# get address of potential new location
	lw $t8, 0($t9)			# store the colour of the new location
	lw $t4, centipedeHeadColour	# store colour code of centipede head
	lw $t6, centipedeBodyColour	# store colour code of centipede body
	lw $t7, mushroomColour		# store colour code of mushrooms
	
	beq $t8, $t4, centipede_collision
	beq $t8, $t6, centipede_collision
	beq $t8, $t7, mushroom_collision
	
	#addi $t1, $t1, -32		# incrmement the location by 32 (go one row up)
	sw $t1, dartLocation			# update loaction of dart
	b end_move_dart
	
reached_top:
	sw $zero, canShoot		# set flag_variable to 0
	b end_move_dart

centipede_collision:
	lw $t9, hitCount		# store number of hits to centipede
	addi $t9, $t9, 1		# increment hit count by 1
	sw $t9, hitCount
	
	sw $zero, canShoot		# set flag_variable to 0
	b end_move_dart

mushroom_collision:
	la $t4, mushrooms		# store address of mushroom array
	la $t5, mushroomHits		# store address of mushroomHits array
find_shroom_loop:	
	lw $t6, 0($t4)			# load a word from the mushroom array
	beq $t6, $t1, found_shroom	# found the mushroom we just hit
	addi $t4, $t4, 4		# increment $t4 by one to point to next element in array
	addi $t5, $t5, 4		# increment $t5 by one to point to next element in array
	j find_shroom_loop		# loop
found_shroom:
	lw $t7, 0($t5)			# load a word from the mushroom_hit array
	addi $t7, $t7, 1		# increment num_hits for this mushroom
	sw $t7, 0($t5)			# update num_hits for this mushrooom
	
	sw $zero, canShoot		# set flag_variable to 0
	b end_move_dart

end_move_dart:
	jr $ra


# function to draw flea:
draw_flea:
	lw $t0, flea			# load the location of the flea into $t0
	lw $t1, displayAddress		# load the displayAddress into $t1
	lw $t2, fleaColour		# $t2 stores the colour of the flea
	sll $t3, $t0, 2			# $t3 stores the bias of the flea location
	add $t3, $t3, $t1		# $t3 stores the address of the flea location
	sw $t2, 0($t3)			# paint flea location
	jr $ra


# function to move the flea:
move_flea:
	lw $t0, flea			# load the location of the flea into $t0
	lw $t2, displayAddress		# load the displayAddress into $t2
	addi $t7, $zero, 1023		# store 1023 in $t7 to check if flea is going below the bottom of the screen
	addi $t8, $zero, 64		# store 64 in $t8 to check if flea is going above heart row
	lw $t9, blackColour		# store the black colour code in $t9
	lw $t6, bugBlasterColour	# store the bug blaster colour code in $t6
	
gen_rand_num:	
	#random number call
	li $v0, 42			# invoke random_num generator
 	li $a0, 0			# put id = 0 into $a0
 	li $a1, 3			# set max to 7
 	syscall				# intiate syscall
	
	#random num = 0:
	bne $a0, $zero, num_one		# check if random number is 0
	addi $t1, $t0, -32		# move up so -32 from location
	blt $t1, $t8, gen_rand_num	# check if flea is at max top location and generate new move if so
	sll $t3, $t1, 2			# get bias of new potential location
	add $t3, $t2, $t3		# get address of new potential location
	lw $t4, 0($t3)			# get the colour of potential new location
	beq $t4, $t6, terminate		# if new location is the location of the bug blaster, terminate game
	bne $t4, $t9, gen_rand_num	# check to see if potential new location is available (black) otherwise generate new move
	sw $t1, flea			# store new location of flea
	b move_flea_return		

num_one:
	#random num = 1:
	bne $a0, 1, num_two		# check if random number is 1
	addi $t1, $t0, 32		# move down so +32 from location
	bgt $t1, $t7, gen_rand_num	# check if flea is at max bottom location and generate new move if so
	sll $t3, $t1, 2			# get bias of new potential location
	add $t3, $t2, $t3		# get address of new potential location
	lw $t4, 0($t3)			# get the colour of potential new location
	beq $t4, $t6, terminate		# if new location is the location of the bug blaster, terminate game
	bne $t4, $t9, gen_rand_num	# check to see if potential new location is available (black) otherwise generate new move
	sw $t1, flea			# store new location of flea
	b move_flea_return

num_two:
	#random num = 2:
	bne $a0, 2, num_three	# check if random number is 2
	addi $t1, $t0, -1		# move left so -1 from location
	sll $t3, $t1, 2			# get bias of new potential location
	add $t3, $t2, $t3		# get address of new potential location
	lw $t4, 0($t3)			# get the colour of potential new location
	beq $t4, $t6, terminate		# if new location is the location of the bug blaster, terminate game
	bne $t4, $t9, gen_rand_num	# check to see if potential new location is available (black) otherwise generate new move
	sw $t1, flea			# store new location of flea
	b move_flea_return		

num_three:
	#random num = 3:
	bne $a0, 3, num_four		# check if random number is 3
	addi $t1, $t0, 1		# move right so 1 from location
	sll $t3, $t1, 2			# get bias of new potential location
	add $t3, $t2, $t3		# get address of new potential location
	lw $t4, 0($t3)			# get the colour of potential new location
	beq $t4, $t6, terminate		# if new location is the location of the bug blaster, terminate game
	bne $t4, $t9, gen_rand_num	# check to see if potential new location is available (black) otherwise generate new move
	sw $t1, flea			# store new location of flea
	b move_flea_return	

num_four:
	#random num = 4:
	bne $a0, 4, num_five		# check if random number is 4
	addi $t1, $t0, -31		# move diag up right so -31 from location
	blt $t1, $t8, gen_rand_num	# check if flea is at max top location and generate new move if so
	sll $t3, $t1, 2			# get bias of new potential location
	add $t3, $t2, $t3		# get address of new potential location
	lw $t4, 0($t3)			# get the colour of potential new location
	beq $t4, $t6, terminate		# if new location is the location of the bug blaster, terminate game
	bne $t4, $t9, gen_rand_num	# check to see if potential new location is available (black) otherwise generate new move
	sw $t1, flea			# store new location of flea
	b move_flea_return	

num_five:
	#random num = 5:
	bne $a0, 5, num_six		# check if random number is 5
	addi $t1, $t0, -33		# move diag up left so -33 from location
	blt $t1, $t8, gen_rand_num	# check if flea is at max top location and generate new move if so
	sll $t3, $t1, 2			# get bias of new potential location
	add $t3, $t2, $t3		# get address of new potential location
	lw $t4, 0($t3)			# get the colour of potential new location
	beq $t4, $t6, terminate		# if new location is the location of the bug blaster, terminate game
	bne $t4, $t9, gen_rand_num	# check to see if potential new location is available (black) otherwise generate new move
	sw $t1, flea			# store new location of flea
	b move_flea_return	

num_six:
	#random num = 6:
	bne $a0, 6, num_seven		# check if random number is 6
	addi $t1, $t0, 33		# move diag down right so +33 from location
	bgt $t1, $t7, gen_rand_num	# check if flea is at max bottom location and generate new move if so
	sll $t3, $t1, 2			# get bias of new potential location
	add $t3, $t2, $t3		# get address of new potential location
	lw $t4, 0($t3)			# get the colour of potential new location
	beq $t4, $t6, terminate		# if new location is the location of the bug blaster, terminate game
	bne $t4, $t9, gen_rand_num	# check to see if potential new location is available (black) otherwise generate new move
	sw $t1, flea			# store new location of flea
	b move_flea_return	

num_seven:
	#random num = 7:
	bne $a0, 7, num_one		# check if random number is 7
	addi $t1, $t0, 31		# move diag down left so +31 from location
	bgt $t1, $t7, gen_rand_num	# check if flea is at max bottom location and generate new move if so
	sll $t3, $t1, 2			# get bias of new potential location
	add $t3, $t2, $t3		# get address of new potential location
	lw $t4, 0($t3)			# get the colour of potential new location
	beq $t4, $t6, terminate		# if new location is the location of the bug blaster, terminate game
	bne $t4, $t9, gen_rand_num	# check to see if potential new location is available (black) otherwise generate new move
	sw $t1, flea			# store new location of flea
	b move_flea_return	

terminate:
	sll $t5, $t0, 2			# get bias of old flea location
	add $t5, $t5, $t2		# get address of old flea location
	sw $t9, 0($t5)			# paint old location black

	lw $t5, lives			# store num lives in $t5
	addi $t5, $t5, -1		# decrement life count
	sw $t5, lives			# update life count
	j Initialize

move_flea_return:
	sll $t5, $t0, 2			# get bias of old flea location
	add $t5, $t5, $t2		# get address of old flea location
	sw $t9, 0($t5)			# paint old location black
	
	jr $ra

# function to detect any keystroke
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input 	# if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0		#default case
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	#beq $t2, 0x73, respond_to_s
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation		# load the address of buglocation from memory
	lw $t1, 0($t0)			# load the bug location itself in t1
	
	lw $t2, displayAddress  	# $t2 stores the base address for display
	lw $t3, blackColour		# $t3 stores the black colour code
	
	sll $t4,$t1, 2			# $t4 the bias of the old buglocation
	add $t4, $t2, $t4		# $t4 is the address of the old bug location
	sw $t3, 0($t4)			# paint the first (top-left) unit white.
	
	beq $t1, 992, skip_movement 	# prevent the bug from getting out of the canvas
	addi $t1, $t1, -1		# move the bug one location to the right
skip_movement:
	sw $t1, 0($t0)			# save the bug location

	lw $t3, bugBlasterColour	# $t3 stores the bug colour code (blue)
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)			# paint the first (top-left) unit blue.
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation		# load the address of buglocation from memory
	lw $t1, 0($t0)			# load the bug location itself in t1
	
	lw $t2, displayAddress  	# $t2 stores the base address for display
	lw $t3, blackColour		# $t3 stores the black colour code
	
	sll $t4,$t1, 2			# $t4 the bias of the old buglocation
	add $t4, $t2, $t4		# $t4 is the address of the old bug location
	sw $t3, 0($t4)			# paint the block with black
	
	beq $t1, 1023, skip_movement2 	#prevent the bug from getting out of the canvas
	addi $t1, $t1, 1		# move the bug one location to the right
skip_movement2:
	sw $t1, 0($t0)			# save the bug location

	lw $t3, bugBlasterColour	# $t3 stores the bug colour code (blue)
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)			# paint the block with blue
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t3, canShoot		# load the address of the flag variable
	lw $t0, 0($t3)			# load the value of the flag variable canShoot into $t0
	bnez $t0, end_respond_x		# if flag is not 0 then we are currently shooting so don't do anything
	addi $t0, $zero, 1		# set flag to 1
	sw $t0, 0($t3)			# update flag to 1
	lw $t1, bugLocation		# load location of bug into $t1
	addi $t1, $t1, -32		# set location of dart to exactly one row above blaster
	la $t2, dartLocation		# load the address of dart into $t2
	sw $t1, 0($t2)			# store the new location of the dart into its memory location
	
	jal draw_dart
	

end_respond_x:	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
#respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 4
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

delay:
	# move stack pointer a work and push ra onto it
	#addi $sp, $sp, -4
	#sw $ra, 0($sp)
	
	li $a2, 10000
	addi $a2, $a2, -1
	bgtz $a2, delay
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# function to clear screen:

clear_screen:
	lw $t0, blackColour		# store black in $t0
	lw $t1, displayAddress		# store the bitmap address
	addi $t2, $zero, 0		# i = 0
	addi $t3, $zero, 1024		# store 1024
loop_clear:
	beq $t2, $t3, end_clear		# start of loop
	sll $t4, $t2, 2			# $t4 = i*4 (offset)
	add $t4, $t4, $t1		# location to paint
	sw $t0, 0($t4)			# paint location black
increment_clear:
	addi $t2, $t2, 1		# i += 1
	j loop_clear
end_clear:
	jr $ra
	



#function to print start screen

print_start:

	lw $t0, displayAddress			# stores the bitmap display
	
 	lw $t2, bugBlasterColour		# loads the colors (start?)

 	lw $t1, centipedeBodyColour		# loads the colors (press 's')

 	sw $t2, 1028($t0)

 	sw $t2, 1032($t0)

 	sw $t2, 1036($t0)

 	sw $t2, 1040($t0)

 	sw $t2, 1048($t0)

 	sw $t2, 1052($t0)

 	sw $t2, 1056($t0)

 	sw $t2, 1060($t0)

 	sw $t2, 1064($t0)

 	sw $t2, 1072($t0)

	sw $t2, 1076($t0)

  	sw $t2, 1080($t0)

 	sw $t2, 1084($t0)

 	sw $t2, 1092($t0)

 	sw $t2, 1096($t0)

 	sw $t2, 1100($t0)

 	sw $t2, 1104($t0)

 	sw $t2, 1112($t0)

 	sw $t2, 1116($t0)

 	sw $t2, 1120($t0)

 	sw $t2, 1124($t0)

 	sw $t2, 1128($t0)

 	sw $t2, 1136($t0)

 	sw $t2, 1140($t0)

 	sw $t2, 1144($t0)

 	#sw $t2, 1148($t0)

 	sw $t2, 1156($t0)

 	sw $t2, 1184($t0)

 	sw $t2, 1200($t0)

 	sw $t2, 1212($t0)

 	sw $t2, 1220($t0)

 	sw $t2, 1232($t0)

 	sw $t2, 1248($t0)

 	sw $t2, 1272($t0)

 	#sw $t2, 1272($t0)

 	sw $t2, 1284($t0)

 	sw $t2, 1312($t0)

 	sw $t2, 1328($t0)

 	sw $t2, 1340($t0)

 	sw $t2, 1348($t0)

 	sw $t2, 1360($t0)

 	sw $t2, 1376($t0)

 	sw $t2, 1400($t0)

 	sw $t2, 1412($t0)

 	sw $t2, 1416($t0)

 	sw $t2, 1420($t0)

 	sw $t2, 1424($t0)

 	sw $t2, 1440($t0)

 	sw $t2, 1456($t0)

 	sw $t2, 1460($t0)

 	sw $t2, 1464($t0)

 	sw $t2, 1468($t0)

 	sw $t2, 1476($t0)

 	sw $t2, 1480($t0)

 	sw $t2, 1484($t0)

 	sw $t2, 1504($t0)

 	sw $t2, 1520($t0)

 	sw $t2, 1524($t0)

 	sw $t2, 1528($t0)

 	sw $t2, 1552($t0)

 	sw $t2, 1568($t0)

 	sw $t2, 1584($t0)

 	sw $t2, 1596($t0)

 	sw $t2, 1604($t0)

 	sw $t2, 1616($t0)

 	sw $t2, 1632($t0)

 	sw $t2, 1648($t0)

 	sw $t2, 1680($t0)

 	sw $t2, 1696($t0)

 	sw $t2, 1712($t0)

 	sw $t2, 1724($t0)

 	sw $t2, 1732($t0)

 	sw $t2, 1744($t0)

 	sw $t2, 1760($t0)

 	sw $t2, 1796($t0)

 	sw $t2, 1800($t0)

 	sw $t2, 1804($t0)

 	sw $t2, 1808($t0)

 	sw $t2, 1824($t0)

 	sw $t2, 1840($t0)

 	sw $t2, 1852($t0)

 	sw $t2, 1860($t0)

 	sw $t2, 1872($t0)

 	sw $t2, 1888($t0)

 	sw $t2, 1904($t0)

 	

 	# paints the "press 's'" pixels

 	

 	sw $t1, 2780($t0)

 	sw $t1, 2804($t0)

 	sw $t1, 2824($t0)

 	sw $t1, 2828($t0)

 	sw $t1, 2832($t0)

 	sw $t1, 2840($t0)

 	sw $t1, 2844($t0)

 	sw $t1, 2848($t0)

 	sw $t1, 2856($t0)

 	sw $t1, 2860($t0)

 	sw $t1, 2864($t0)

 	sw $t1, 2872($t0)

 	sw $t1, 2876($t0)

 	sw $t1, 2880($t0)

 	sw $t1, 2888($t0) 	

 	sw $t1, 2892($t0)

 	sw $t1, 2896($t0)

 	sw $t1, 2908($t0)

 	sw $t1, 2916($t0)

 	sw $t1, 2920($t0)

 	sw $t1, 2924($t0)

 	sw $t1, 2932($t0)

 	sw $t1, 2952($t0)

 	sw $t1, 2960($t0)

 	sw $t1, 2968($t0)

 	sw $t1, 2976($t0)

 	sw $t1, 2984($t0)

 	sw $t1, 3000($t0)

 	sw $t1, 3016($t0)

 	sw $t1, 3044($t0)

 	sw $t1, 3080($t0)

 	sw $t1, 3084($t0)

 	sw $t1, 3088($t0)

 	sw $t1, 3096($t0)

 	sw $t1, 3100($t0)

 	sw $t1, 3112($t0)

 	sw $t1, 3116($t0)

 	sw $t1, 3128($t0)

 	sw $t1, 3132($t0)

 	sw $t1, 3136($t0)

 	sw $t1, 3144($t0)

 	sw $t1, 3148($t0)

 	sw $t1, 3152($t0)

 	sw $t1, 3172($t0)

 	sw $t1, 3176($t0)

 	sw $t1, 3180($t0)

 	sw $t1, 3208($t0)

 	sw $t1, 3224($t0)

 	sw $t1, 3232($t0)

 	sw $t1, 3240($t0)

 	sw $t1, 3264($t0)

 	sw $t1, 3280($t0)

 	sw $t1, 3308($t0)

 	sw $t1, 3336($t0)

 	sw $t1, 3352($t0)

 	sw $t1, 3360($t0)

 	sw $t1, 3368($t0)

 	sw $t1, 3372($t0)

 	sw $t1, 3376($t0)

 	sw $t1, 3384($t0)

 	sw $t1, 3388($t0)

 	sw $t1, 3392($t0)

 	sw $t1, 3400($t0)

 	sw $t1, 3404($t0)

 	sw $t1, 3408($t0)

 	sw $t1, 3428($t0)

 	sw $t1, 3432($t0)

 	sw $t1, 3436($t0)
 
 	jr $ra
