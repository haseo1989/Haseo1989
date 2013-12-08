	   title     "assignment_3"
	   list      p=16f877a
	   include   "p16f877a.inc"

	__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_OFF & _LVP_OFF & _CPD_OFF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;DEFINITION OF THE REGISTERS AND VARIABLES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
del1		equ 	h'21'
del2		equ 	h'22'
del3		equ		h'23'
del4		equ		h'24'
data_hi		equ		h'25'
data_lo		equ		h'26'
key_input	equ		h'27'
display1	equ		h'28'
display0	equ		h'29'
count_flag	equ		h'2A'
key			equ		h'2B'
reg			equ		h'2C'
way			equ		h'2D'
max			equ		h'2F'
start_stop	equ		h'30'
W_save		equ		h'31'
S_save		equ		h'32'
_stop		equ		h'33'

number		equ		d'48'



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;START ADDRESS, INTERRUPT ADDRESS AND TINY BOOTLOADER SETTINGS;;;;;;;;;;;;;;
		org     h'00'                   ; initialise system restart vector
		clrf 	STATUS
		clrf 	PCLATH			; needed for TinyBootloader functionality
		goto    start

		org		H'0004'	;address of the interrupt function
		goto	int_routine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;REGISTER, INPUTS/OUTPUTS AND VARIABLE INITIALISATION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init
		bsf		STATUS,RP0

		movlw	B'11111111'	;B set as inputs (4needed)
		movwf	TRISB

		movlw	B'00000000'	;C set as outputs (2 needed)
		movwf	TRISC

		bcf		STATUS,RP0
		bcf		PORTC,0	;alarm + morse code
		bcf		PORTC,2	;to see the way

		movlw	b'00000000'	;for the count way
		movwf	way

		movlw	b'00000000'	;flag for the stop function
		movwf	_stop

		movlw	b'00000000'	;flag to start the start/stop function
		movwf	start_stop

		movlw	b'00000000'	;usefull to count in the other way
		movwf	max

		movlw	B'11000000'	;pull up disabled, interrupt on ridsing edge
		movwf	OPTION_REG

		bsf		INTCON,GIE	;registers for the interrupt
		bsf		INTCON,PEIE
		bsf		INTCON,INTE
		bcf		INTCON,INTF
		bcf		INTCON,TMR0IF

		call	INIT_SWITCH

		call	INIT_LCD

		return	;go back to the main function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INTERRUPT FUNCTION (START/STOP BUTTON);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int_routine
		bcf		INTCON,GIE	;clear all flags
		bcf		INTCON,PEIE
		bcf		INTCON,INTE
	
		movwf 	W_save ; save W register
		swapf 	STATUS,w ; move without status change
		movwf 	S_save ; save status

		bsf		start_stop,0	;flag for the stop/start function
		
		btfsc	_stop,0	;flag for the stop function
		call	stop


		swapf 	S_save,w ;
		movwf 	STATUS ; restore status
		swapf 	W_save,f ; MUST NOT CHANGE STATUS
		swapf 	W_save,w
		
		bsf		INTCON,GIE	;set all flags
		bsf		INTCON,PEIE
		bsf		INTCON,INTE
		bcf		INTCON,INTF
		bcf		INTCON,TMR0IF

		retfie

go		
		btfss	way,0	;the way is checked
		goto	go1_1	;straight way
		goto	go2	;reverse way
		return

go2
		movfw	key_input
		movwf	max	;the key_input is copied in max register
		clrf	key_input

go2_1	incf	max	;Here we check if max is 0
		decfsz	max
		goto	go2_2
		call	alarm	;the number is reached, so the alarm is called
		return

go2_2	call	test_key	;display of the count ont he 7 segment
		bsf		_stop,0	;the flag of the stop function is set
		call	wait1430ms
		incf	key_input	;the number which is display is incremented
		decf	max	;max is decremented
		goto	go2_1	;come back to the previous function

go1_1	incf	key_input	;We check if the number is reached
		decfsz	key_input
		goto	go1_2
		call	alarm	;once the count is over, the alarm is called
		return

go1_2	call	test_key	;display of the count
		bsf		_stop,0	;flag of the stop function set
		call	wait1430ms
		decf	key_input
		goto	go1_1

stop	call	morse	;morse code called
stop2	btfsc	PORTB,1	;RESET
		goto	start
		btfss	PORTB,0
		goto	stop2
		bcf		_stop,0	;flag is cleared
		return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ALARM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay500us
		
		movlw	d'42'
		movwf	del1
delay1
		decfsz	del1
		goto	delay1

	return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alarm

		call	test_key
		movlw	d'59'
		movwf	del2
		movlw	d'255'
		movwf	del3

delay2
		bsf		PORTC,0	;a square function is needed for the speaker
		call	delay500us	;High frequency
		bcf		PORTC,0
		call	delay500us
		bsf		PORTC,0

		decfsz	del3
		goto	delay2
		decfsz	del2
		goto	delay2

		goto	start	;once the alarm is over, we start the program from the beginning
		return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MORSE CODE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay500us2
		
		movlw	d'42'
		movwf	del1
delay1_2
		decfsz	del1
		goto	delay1_2

	return

morse
		movfw	display1
		movwf	reg	;reg take the value of the first number

		call	_reg	;call the binary tree which will find which signal have to be transmitted for the first number

		movfw	display0
		movwf	reg
	
		call	_reg	;reg take the value of the second number

		return

short_wait	;Short way between 2 signals
		
		movlw	d'200'
		movwf	del3
mcs2
		nop
		call	delay500us2
		nop
		call	delay500us2

		decfsz	del3
		goto	mcs2

		return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
long_wait	;Long wait between two numbers
		
		movlw	d'10'
		movwf	del4
mcl2
		call	short_wait
		decfsz	del4
		goto	mcl2

		return

_reg
		btfsc	reg,2	;if 1xx
		goto	t0		;go to t0 function

		goto	t1

t0
		btfsc	reg,1	;if 11x
		goto	_6		;goto _6 (max number we can have)

		goto	t3

t1
		btfsc	reg,1	;if 01x
		goto	t4		;go to t4

		goto	t5

t3
		btfsc	reg,0	;if 101
		goto	_5		;the number is 5

		goto	_4		;else the number is 4

t4
		btfsc	reg,0	;if 011
		goto	_3		;the number is 3

		goto	_2		;else the number is 2

t5
		btfsc	reg,0	;if 001
		goto	_1		;the number is 1

		goto	_0		;else the number is 0

		return

_0
		call	long	;morse code for 0
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	long_wait
	
		return

_1
		call	short	;morse code for 1
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	long_wait
		

		return

_2
		call	short	;morse code for 2
		call	short_wait
		call	short
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	long_wait

		return

_3
		call	short	;morse code for 3
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	short_wait
		call	long
		call	short_wait
		call	long
		call	long_wait

		return

_4
		call	short	;morse code for 4
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	short_wait
		call	long
		call	long_wait

		return

_5
		call	short	;morse code for 5
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	long_wait

		return

_6
		call	long	;morse code for 6
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	short_wait
		call	short
		call	long_wait

		return

short	;short are for the dots
		
		movlw	d'200'
		movwf	del3
mcs
		bsf		PORTC,0
		call	delay500us2
		bcf		PORTC,0
		call	delay500us2

		decfsz	del3
		goto	mcs

		return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
long	;long are for the bars
		
		movlw	d'5'
		movwf	del4
mcl
		call	short
		decfsz	del4
		goto	mcl

		return


wait1430ms				;delay1.43s


		movlw	d'143'
		movwf	del1

wait1	
		movlw	d'13'
		movwf	del4

		btfsc	PORTB,1
		goto	start



wait1_2	
		movlw	d'255'
		movwf	del3

wait1_1	
		decfsz	del3
		goto	wait1_1

	
		decfsz	del4
		goto	wait1_2

		decfsz	del1
		goto	wait1

		return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SWITCHES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switches
		movf 	PORTD,W
		movwf	key_input	;the value of the portD is put in the key_input register

		call	test_key	;The result is printed on the 7 segments

		return

INIT_SWITCH
	
		
		bsf     STATUS, RP0        ; enable page 1 register set
	
	
		movlw	b'11111111'
		movwf	TRISD	;D set as input
	
		bcf		STATUS,RP0
	
		call	SET_SPI_REG
	
		return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DISPLAY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
bi2sep									;input invariable is key_input 
		movfw	key_input
		movwf	key	;copy the key in an other register to save it
		movlw	b'00000111'	;7 in base 10
		
flag3
		subwf	key_input,1					;f-w -> f
		incf	display1,1	;first number
								;display0 units
		btfss	key_input,7	;if key_input is overflow, skip the next instruction
		goto	flag3
		
		decf	display1,1	;There was an overflow, so here we decrement the first number
		addwf	key_input,1	
	
		movfw	key_input	;The register contain now the unit number
		movwf	display0
		
		movfw	key		;The key is restore
		movwf	key_input
	
		return	
	
show_number	
		clrf	display1	;clear the 2 numbers
		clrf	display0

		call	bi2sep	;convert from base 2 to 7

		movlw	b'0000001'
		movwf	data_hi		;settings of the max7219

		movfw	display0
		movwf	data_lo	;number we want to display

		call	send_data	;the datas are sent
	
		movlw	b'00000010'
		movwf	data_hi

		movfw	display1	;units
		movwf	data_lo

		call	send_data
	
		return
	
show_max	;if the number we get is over than 66 or equal, we print 66
	
		movlw	b'00000010'
		movwf	data_hi

		movlw	b'00000110'
		movwf	data_lo

		call	send_data
		
		movlw	b'00000001'
		movwf	data_hi

		movlw	b'00000110'
		movwf	data_lo

		call	send_data
		return
		
test_key
	
		movfw	key_input			;test whether the number input is over 66,key_input - number
		movwf	count_flag			;if it does, it will also display 66
							
		movlw	number
		subwf	count_flag			;F-W->F
	
		btfss	count_flag,7
		call	show_max
	
		btfsc	count_flag,7
		call	show_number
	
		return
	
	
SET_SPI_REG					;;initial SPI
	
		movlw	 b'00000010'	
		movwf	 SSPCON
	
		bsf      STATUS, RP0        ; enable page 1 register set
		bcf		 STATUS, RP1
	
		movlw	b'01000000'		
		movwf	SSPSTAT
	
		movlw   b'00010000'
		movwf 	TRISC
		
		movlw	H'06'
		movwf	ADCON1				;PORTA-5 will be digital output
	
									;set RA5 to output as CS bit. output
		movlw	b'11011111'
		movwf	TRISA
	
		bcf     STATUS, RP0        ; back to page 0 register set
		clrf	PORTC
		clrf	SSPBUF				;
	
		MOVLW   B'00100010'
		MOVWF	SSPCON
	
		return
		
send_data						;function. send 16 bits data
	
		bcf		PORTA,5				;;enable maxism
	
		bcf		PIR1,3					;;clear	interruption flag
	
		movf	 data_hi,W			;;send hi 8-bit data
		movwf	 SSPBUF
	
flag1
		btfss	 PIR1,3			;waitting for transmitting
		goto     flag1
	
		bcf		PIR1,3			;;after finished, clear interruption flag
	
		movf	 data_lo,W
		movwf	 SSPBUF
	
flag2
	
		btfss	 PIR1,3			;send low 8-bit data
		goto     flag2
	
		bcf		PIR1,3			;;;important
	
		bsf		PORTA,5			;;disable maxsim
	
		return
	
INIT_LCD
		
		movlw	b'00001100'			;0c
		movwf	data_hi

		movlw	b'00000000'			;00
		movwf	data_lo

		call    send_data
	
		nop
		nop
	
		movlw	b'00001001'			;09
		movwf	data_hi

		movlw	b'11111111'			;ff
		movwf	data_lo

		call	send_data
	
		nop
		nop
	
		movlw	b'00001011'			;0b
		movwf	data_hi

		movlw	b'00000001'			;01
		movwf	data_lo

		call	send_data
	
		nop
		nop
	
		movlw	b'00001010'			;0a
		movwf	data_hi

		movlw	b'00001110'			;0e
		movwf	data_lo

		call	send_data
	
		nop
		nop
	
		movlw	b'00001100'			;0c
		movwf	data_hi

		movlw	b'00000001'			;01
		movwf	data_lo

		call	send_data

		movlw	b'00000001'		;add for display 00
		movwf	data_hi

		movlw	b'00000000'
		movwf	data_lo

		call	send_data

		movlw	b'00000010'
		movwf	data_hi

		movlw	b'00000000'
		movwf	data_lo

		call	send_data

		call	wait1430ms
	
		return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WAY;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_way	
		btfss	way,0	;if the flag way is clear, we set it
		goto	reverse

		goto	straight	;else we clear it

straight
		bcf		PORTC,2
		bcf		way,0
		goto	_wait

reverse	bsf		PORTC,2
		bsf		way,0
_wait	btfsc	PORTB,2
		goto	_wait

		return
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAIN FUNCTION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start	
		call	init
next	
		call	switches

		btfsc	PORTB,1	;RESET
		goto	start

		btfsc	PORTB,2	;Set the way
		call	_way

		btfss	start_stop,0	;if the start/stop flag is set, the count will begin
		goto	next	;else we come back to the switches function

		bcf		start_stop,0
		call	go
		goto	start
		end