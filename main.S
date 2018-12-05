/*
 * main.S - ECE 540 Final project - Audio Effects Generator MIPS FPGA code
 * running on Nexys4 DDR FPGA target board
 *
 * Created By:		Sanika Balkawade, Stephano Cetola, Geoff Wallace
 * Last Modified:	12-3-2018
 * *
 * Description:
 * Reads the slide switches on the FPGA board to determine audio effect to be generated.
 * According to the input effect, corresponding audio effects module is selected, and displayed on 7 segment LEDs
 * The amplitude of output audio is visualied on 16 yellow LEDs and 2 RGB LEDs.
 *
 * Assumes the existance of an AHB-Lite peripheral for the 8 digit 7-segment display and 2 RGB LEDs on the Nexys4 DDR.
 * The 7 segment peripheral has 4 memory mapped I/O registers:
 * PORT_SEVENSEG_EN - (8 bits) Individual enables for each digit. Set bit to 0 to enable digit
 *									Digit7 = bit[7], Digit6 = bit[6], Digit5 = bit[5], Digit4 = bit[4],
 *									Digit3 = bit[3], Digit2 = bit[2], Digit1 = bit[1], Digit0 = bit[0]
 *	PORT_SEVENSEG_HGH = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit7 = bits[31:24], Digit6 = bits[23:16],
 *									Digit5 = bits[15:8] , Digit4 = bits[7:0]
 *	PORT_SEVENSEG_LOW = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit3 = bits[31:24], Digit2 = bits[23:16],
 *									Digit1 = bits[15:8] , Digit0 = bits[7:0]
 *	PORT_SEVENSEG_DP - (8 bits) Individual decimal points for each digit. Set bit to 0 to turn on the decimal point
 *									DP7 = bit[7], DP6 = bit[6], DP5 = bit[5], DP4 = bit[4],
 *									DP3 = bit[3], DP2 = bit[2], DP1 = bit[1], DP0 = bit[0]
 *
 * The RGB LED peripheral has 4 memory mapped I/O registers:
 *
 * PORT_RGB1_DATA = (24 bits)  Value for 8 bit PWM input for R,G,B channel for LED1
 *							    RED_DC = bits[23:16], GREEN_DC = bits[15:8], BLUE_DC = bits[7:0]
 *
 * PORT_RGB2_DATA = (24 bits)  Value for 8 bit PWM input for R,G,B channel for LED2
 *							    RED_DC = bits[23:16], GREEN_DC = bits[15:8], BLUE_DC = bits[7:0]
 *
 * PORT_RGB1_CTRL = (3 bits)   Value for PWM enable input for R, G, B signals of LED1
 *							   Red_EN = bit[2], Green_EN = bit[1], Blue_EN = bit[0]
 *
 * PORT_RGB2_CTRL = (3 bits)   Value for PWM enable input for R, G, B signals of LED2
 *							   Red_EN = bit[2], Green_EN = bit[1], Blue_EN = bit[0]
 *
 */

PORT_SEVENSEG_EN 	= 0xbf700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0xbf700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0xbf700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0xbf70000C		# (o) 7 segment Decimal Point Display
PORT_PUSH_BUTTON 	= 0xbf800008		# (o) Push buttons
PORT_SLIDE_SW		= 0xbf800004		# (i) Slide switch

PORT_RGB1_DATA		= 0xbf900000		#  DATA register for RGB LED1
PORT_RGB1_CTRL		= 0xbf900004		#  Control register for RGB LED1
PORT_RGB2_DATA		= 0xbf900008		#  DATA register for RGB LED2
PORT_RGB2_CTRL		= 0xbf90000C		#  Control register for RGB LED2

PORT_AMP			= 0xbf80000C		#  Audio out amplitude signal

sw_distort1			= 0x00008000		# bit 15
sw_distort2			= 0x00004000		# bit 14
sw_chorus			= 0x00002000		# bit 13
sw_reverb			= 0x00001000		# bit 12

FiveHz				= 0x249F00			# 5 Hz = 10*10^6 cycles / 25 instructions * 6 segments
TenHz				= 0x124F80			# 2x faster than FiveHz
OneHz				= 0x6CFDC9			# 1 Hz = 50*10^6 cycles / 7 (14 instructions per segment / 2 for blinking)

.text
.globl main
main:
    lui   $t4, 0xbf80    				# $t4 = address of LEDs (0xbf800000)
    addiu $s3, $t4, 8    				# $s3 = address of push buttons (0xbf800008)
    lui   $t5, 0xbf90					# $t5 = address of RGB data1
    addiu $t6, $t5, 8					# $t6 = address of RGB data2


# ######################################################################################################################
# init function:
# Enable the lower 4 seven segment display digits
# Lit third decimal point to separate motion indicator and compass
# Reset seven seg display to zero, and turn OFF LEDs
init:
	#enable seven segment digits - 7 to 0 (Active low)
	li    $t3, 0x00						# Enable all 7 segment digits
    sw    $t3, PORT_SEVENSEG_EN($0)

    li    $t3, 0xff						#turn off decimal points
    sw    $t3, PORT_SEVENSEG_DP($0)

    # Reset seven segment display
	li    $t7, 0x1f1f1f1f				# clear 7 seg display
	sw    $t7, PORT_SEVENSEG_HGH($0)
	sw    $t7, PORT_SEVENSEG_LOW($0)

	# Turn OFF all LEDs
	sw    $0,  0($t4)					# $t4 - Address of LED register

	#Turn ON RGB LEDS
	li    $t1, 0x7		     			# valule to be loaded in RGB control register to enable PWM (3'b111)
	sw    $t1, PORT_RGB1_CTRL($0)		# enable RGB LED1 PWM
	sw    $t1, PORT_RGB2_CTRL($0)		# enable RGB LED2 PWM
	li    $t1, 255
	sw    $t1, PORT_RGB1_DATA($0)
	sw    $t1, PORT_RGB1_DATA($0)






# ######################################################################################################################
#readIO function:
#read push buttons, and jump to corresponding function
#refer values from state table for different conditions.
#center button is ignored using mask 0x1D. (U-D-L-C-R )
#
readIO:
	lw   $t2, PORT_SLIDE_SW($0)    	# read side switch value and store in $t2

	li	 $t1, sw_distort1
	and  $s1, $t2, $t1
	beq  $s1, $t1, distor1

	li	 $t1, sw_distort2
	and  $s1, $t2, $t1
	beq  $s1, $t1, distor2

	li	 $t1, sw_chorus
	and  $s1, $t2, $t1
	beq  $s1, $t1, chorus

	li	 $t1, sw_reverb
	and  $s1, $t2, $t1
	beq  $s1, $t1, reverb

	beq  $t2, $0, L1
L1:  li   $t7, 0x1f1f1f1f					# clear 7 seg display
	sw    $t7, PORT_SEVENSEG_HGH($0)
	sw    $t7, PORT_SEVENSEG_LOW($0)

/*
RGB:
	// Read amplitude of signal
	lw    $s2, PORT_AMP($0)				# load current amplitude from memory location

	// Check if the amplitude is less than 255, if yes, then load to Green and Blue registers,
	// else load to Red_Green register

	//SLTIU Set on Less Than Immediate Unsigned
	// set $t1 if amplitude < 255
	SLTIU  $t1, $s2, 255
	beq    $t1, $0, setGB
	sll    $t2, $s2, 8									// i.e. $t1 is not set, dump the amplitude to Red-Green
	sw     $t2, PORT_RGB1_DATA($0)		# RGB LED1 pwm data
	sw     $t2,  PORT_RGB2_DATA($0)		# RGB LED2 pwm data

setGB:													// $t1 is set, ie. amplitude < 255
	sw     $s2, PORT_RGB1_DATA($0)		# RGB LED1 pwm data
	sw     $s2,  PORT_RGB2_DATA($0)		# RGB LED2 pwm data


*/

	j     readIO


distor1:
    li    $t7, 0x1f1f1f1f					# clear 7 seg display
	sw    $t7, PORT_SEVENSEG_HGH($0)
	sw    $t7, PORT_SEVENSEG_LOW($0)
	li    $t1, 0x0d1a1015
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t1, 0x0d1a1516
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t1, 0x0d1a1614
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t1, 0x0d1a1213
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t1, 0x0d1a1313
	sw    $t1, PORT_SEVENSEG_HGH($0)

	li    $t2, 0x001b1501
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x001b1601
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x001b1401
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x001b1301
	sw    $t2, PORT_SEVENSEG_LOW($0)
	j	  readIO


distor2:
    li    $t7, 0x1f1f1f1f					# clear 7 seg display
	sw    $t7, PORT_SEVENSEG_HGH($0)
	sw    $t7, PORT_SEVENSEG_LOW($0)
	li    $t1, 0x0d1a1015
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t1, 0x0d1a1516
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t1, 0x0d1a1614
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t1, 0x0d1a1213
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t1, 0x0d1a1313
	sw    $t1, PORT_SEVENSEG_HGH($0)

	li    $t2, 0x001b1502
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x001b1602
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x001b1402
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x001b1302
	sw    $t2, PORT_SEVENSEG_LOW($0)
	j	readIO


chorus:
	li    $t7, 0x1f1f1f1f					# clear 7 seg display
	sw    $t7, PORT_SEVENSEG_HGH($0)
	sw    $t7, PORT_SEVENSEG_LOW($0)
	li    $t1, 0x0c170019
	sw    $t1, PORT_SEVENSEG_HGH($0)
	li    $t2, 0x15151f1f
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x14101f1f
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x13131f1f
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x12121f1f
	sw    $t2, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x11161f1f
	sw    $t2, PORT_SEVENSEG_LOW($0)

	j     readIO


reverb:
	li    $t7, 0x1f1f1f1f					# clear 7 seg display
	sw    $t7, PORT_SEVENSEG_HGH($0)
	sw    $t7, PORT_SEVENSEG_LOW($0)
	li    $t1, 0x190b1f1f					#RB
	sw    $t1, PORT_SEVENSEG_LOW($0)
	li    $t2, 0x190e150e
	sw    $t2, PORT_SEVENSEG_HGH($0)
	li    $t2, 0x190e140e
	sw    $t2, PORT_SEVENSEG_HGH($0)
	li    $t2, 0x190e130e
	sw    $t2, PORT_SEVENSEG_HGH($0)
	li    $t2, 0x190e120e
	sw    $t2, PORT_SEVENSEG_HGH($0)
	li    $t2, 0x190e110e
	sw    $t2, PORT_SEVENSEG_HGH($0)
	j	 readIO




# #################################################################################################################################
# delay function:
# genearates $a0 cycles delay
# args- $a0 : required MIPS cycle delay
#

delay:
	#save t1 on stack
    addi 	$sp, $sp, -4 				# allocate space for one register on stack
	sw   	$t1, 0($sp) 				# push on stack
	move   	$t1, $a0					# load argument
dec:addi 	$t1, $t1, -1				# decrement by 1
	bne  	$t1, $0, dec				# repeat until 0

	lw   	$t1, 0($sp) 				# restore t1
	addi 	$sp, $sp, 4					# free space from stack
	jr   	$ra							# return






