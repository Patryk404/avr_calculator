;
; ***********************************
; * Avr Calculator       *
; * Atmega88PA *
; * (C)2022 by Patryk Kurek  *
; ***********************************
;
.nolist
.include "m88padef.inc" ; Define device ATmega88PA
.list
;
; **********************************
;        H A R D W A R E
; **********************************
;
; (F2 adds ASCII pin-out for device here)
;
; **********************************
;  P O R T S   A N D   P I N S
; **********************************
;
; (Add symbols for all ports and port pins with ".equ" here)
; (e.g. .equ pDirD = DDRB ; Define a direction port
;  or
;  .equ bMyPinO = PORTB0 ; Define an output pin)
;
; **********************************
;   A D J U S T A B L E   C O N S T
; **********************************
;
;
.equ fclk=16000000
.equ reset=0b00110000
.equ font_and_lines=0b00111000
.equ display_off=0b00001000
.equ clear_display=0b00000001
.equ entry_mode=0b00000110
.equ display_on_with_cursor_blink=0b00001111
.equ set_position_0=0b10000000
.equ force_cursor_beginning_second_line=$C0
.equ set_cursor_shift_left=$04
.equ set_cursor_shift_right=$06
.equ shift_right=0b00010100
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Numbers -> as a strings
;;;;;;;;;;;;;;;;;;;;;;;;;;;

; **********************************
;  F I X  &  D E R I V.  C O N S T
; **********************************
;
; (Add symbols for fixed and derived constants here)
;
; **********************************
;       R E G I S T E R S
; **********************************
;
; free: R0 to R14
.def rSreg = R15 ; Save/Restore status port
.def temp = R16 ; Define multipurpose register
.def zero = R17 
.def counter = R18
.def temp1 = R19
.def temp2 =R20 
.def temp3 = R21
.def temp4 =R22
; free: R17 to R29
; free: R31:R30 = Z
;
; **********************************
;           S R A M
; **********************************
;
.dseg
.org SRAM_START

calculatorInput1: .BYTE 16
calculatorInput2: .BYTE 16
calculatorSign: .BYTE 1
; calculatorSignIndex: .BYTE 1 ; to remember when we put sign! 
calculatorOutput: .BYTE 16
calculatorInput1Length: .BYTE 1
calculatorInput2Length: .BYTE 1 
calculatorOutputLength: .BYTE 1
calculatorOutputSign: .BYTE 1 ; 1 -> means minus 0-> means plus
calculatorOutputTemp: .BYTE 16
calculatorOutputTempLength: .BYTE 1
calculatorOutputCarryLength: .BYTE 1
calculatorOutputRest: .BYTE 1
; calculatorOutputCarrySpace: .BYTE 16
; (Add labels for SRAM locations here, e.g.
; sLabel1:

;   .byte 16 ; Reserve 16 bytes)
;
; **********************************
;         C O D E
; **********************************
;
.cseg
.org 0
author: 
.db "Patryk Kurek",0x00
calculatorString:  
.db "Avr Calculator",0x00
restString:
.db " rest: ",0x00

divisionByNull:
.db "Don't divide by 0!"
; **********************************
; R E S E T  &  I N T - V E C T O R S
; **********************************
	rjmp Main ; Reset vector
	reti ; INT0
	reti ; INT1
	reti ; PCI0
	reti ; PCI1
	reti ; PCI2
	reti ; WDT
	reti ; OC2A
	reti ; OC2B
	reti ; OVF2
	reti ; ICP1
	reti ; OC1A
	reti ; OC1B
	reti ; OVF1
	reti ; OC0A
	reti ; OC0B
	reti ; OVF0
	reti ; SPI
	reti ; URXC
	reti ; UDRE
	reti ; UTXC
	reti ; ADCC
	reti ; ERDY
	reti ; ACI
	reti ; TWI
	reti ; SPMR
;
; **********************************
;  I N T - S E R V I C E   R O U T .
; **********************************
;
; (Add all interrupt service routines here)
;
; **********************************
;  M A I N   P R O G R A M   I N I T
; **********************************
;

Main:
Start:            ; stack initialization
    ldi temp,low(RAMEND)
    out SPL,temp
    ldi temp,high(RAMEND)
    out SPH,temp
        ;;;;;;;;;;;;;;;;;;;;;;;;;
        ; initialization of pd0->pd7 (DATA BUS) to output mode
        ; initialization of pb0->pb1 (R/W AND ENABLE PIN) to output mode
        ; initialization of pd0->pd4 to output mode
    SBI DDRC,DDC0
    SBI DDRC,DDC1


      ;;;;;;;;;;;; ENABLING FIRST BITS FOR KEYBOARD AS OUTPUT
    SBI DDRD,DDD7
    SBI DDRD,DDD6
    SBI DDRD,DDD5
    SBI DDRD,DDD4
      ;;;;;;;;;;;;;;;;;;;    
     ;;;;;;;;;;;;; ENABLING BITS FOR KEYBOARD AS AN INPUT
    CBI DDRD,DDD3
    CBI DDRD,DDD2
    CBI DDRD,DDD1
    CBI DDRD,DDD0
    ;;;;;;;;;;;;


    ;;; reset pinc2 for reset button
    cbi portc,portc2
    cbi ddrc,ddc2

    SER R16
    OUT DDRB,R16    
    
    ldi temp,0

    sts calculatorSign,temp

	lds temp,calculatorSign
                 ;;;;;;;;;;;;;;;;;;;;;;;;;
                 ;;;;;
Initialization_LCD_HARDWARE:
    ldi zero,0

    ldi temp,200
    rcall delayTx1mS

      ; first part of reset sequence

    ldi temp,reset  ; reset LCD
    out PORTB,temp
    rcall clear_enable
    rcall enable
    ldi temp,10
    rcall delayTx1mS

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ; second part of reset sequence
    ldi temp,reset
    out PORTB,temp
    rcall clear_enable
    rcall enable
    ldi temp,200
    rcall delayTx1uS

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ; Third part of reset sequence
    ldi temp,reset
    out PORTB,temp
    rcall clear_enable
    rcall enable
    ldi temp,200
    rcall delayTx1uS
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


      ; set mode lines and font
    ldi temp,font_and_lines
    rcall send_command
      ;;;;;;;;;;;;;;;;;;;;;;;;;

      ; Display On/Off Control instruction
    ldi temp,display_off        ;; DISPLAY OFF
    rcall send_command


    ldi temp,clear_display ; clear display instruction
    rcall send_command


    ldi temp,entry_mode     ; entry mode
    rcall send_command


    ldi temp,display_on_with_cursor_blink ; turn display on enable cursor and blink ;)
    rcall send_command
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;; WRITING SCREEN!

    ldi temp,set_position_0 ; SET POSITION OF CURSOR
    out PORTB,temp
    rcall clear_enable
    rcall enable
    ldi temp,80
    rcall delayTx1uS

    ldi ZL, low(author)
    ldi ZH, high(author)

    rcall print

    ldi temp,250
    rcall delayTx1mS

    rcall jump_second_line_lcd

    ldi ZL, low(calculatorString<<1) ;  word alignment
    ldi ZH, high(calculatorString<<1)

    rcall print

    ldi temp,250
    rcall delayTx1mS

    rcall reset_calc

    rcall reset_counter
;
; **********************************
;    P R O G R A M   L O O P
; **********************************
;
Loop:
    lds temp,calculatorOutput
    cpi temp,$0
    breq check_instructions
    rcall press_any_key_check
    ldi temp,2
    rcall delayTx1mS
    rjmp Loop
check_instructions:
    rcall check_row1 
    ldi temp,2
    rcall delayTx1mS

	rcall check_row2
    ldi temp,2
    rcall delayTx1mS

    rcall check_row3 
    ldi temp,2
    rcall delayTx1mS

    rcall check_row4
    ldi temp,2
    rcall delayTx1mS

    rcall check_reset

    rjmp Loop
enable:
    sbi PORTC,PORTC1
    rcall delay1uS
    sbi PORTC,PORTC0
    rcall delay1uS
    ret
clear_enable:
    cbi PORTC,PORTC0
    cbi PORTC,PORTC1
    ret
send_command:    
    out PORTB,temp
    rcall clear_enable
    rcall enable
    ldi temp,80
    rcall delayTx1uS
    ret

send_letter:    
    inc counter
    out PORTB,temp
    sbi PORTC,PORTC0
    sbi PORTC,PORTC1
    rcall delay1uS
    cbi PORTC,PORTC1
    rcall delay1uS
    ret

save_number_input_buffer:
	ldi YL,LOW(calculatorInput1)
	ldi YH,HIGH(calculatorInput1)
	add YL,counter
    push temp
    lds temp,calculatorSign
    cpi temp,0
    brne save_number_input2
    pop temp
    st Y,temp
    ret
save_number_input2:
	ldi YL,LOW(calculatorInput2)
	ldi YH,HIGH(calculatorInput2)
	add YL,counter
    pop temp
    st Y,temp
    ret

check_row1:
    sbi PORTD,PORTD7
    rcall delay1mS
    IN temp,PIND
    ANDI temp,$08
    cpi temp,$08
    brne next_key_row1_1
    cpi counter,$10
    breq return_from_row1
    ldi temp,'1'
    rcall save_number_input_buffer
    rcall send_letter
      
next_key_row1_1:
    IN temp,PIND
    ANDI temp,$04
    cpi temp,$04
    brne next_key_row1_2
    cpi counter,$10
    breq return_from_row1
    ldi temp,'2'
    rcall save_number_input_buffer
    rcall send_letter

next_key_row1_2:
    IN temp,PIND
    ANDI temp,$02
    cpi temp,$02
    brne next_key_row1_3
    cpi counter,$10
    breq return_from_row1
    ldi temp,'3'
    rcall save_number_input_buffer
    rcall send_letter
      
next_key_row1_3: 
    IN temp,PIND 
    ANDI temp,$01
    cpi temp,$01
    brne return_from_row1
    cpi counter,$10
    breq return_from_row1
      
	lds temp,calculatorSign

    cpi temp,0
    brne return_from_row1 
save_sign_row1:
	rcall save_counter
    ldi temp,'+'
    sts calculatorSign,temp
    rcall send_letter
    ldi counter,0 ; no erasable sign for now!!!
return_from_row1:
    cbi PORTD,PORTD7
    ret


check_row2:
    sbi PORTD,PORTD6
    rcall delay1mS
    IN temp,PIND
    ANDI temp,$08
    cpi temp,$08
    brne next_key_row2_1
    cpi counter,$10
    breq return_from_row2
    ldi temp,'4'
    rcall save_number_input_buffer
    rcall send_letter
next_key_row2_1:
    IN temp,PIND
    ANDI temp,$04
    CPI temp,$04
    brne next_key_row2_2
    cpi counter,$10
    breq return_from_row2
    ldi temp,'5'
    rcall save_number_input_buffer
    rcall send_letter
next_key_row2_2:
    IN temp,PIND
    ANDI temp,$02
    CPI temp,$02
    brne next_key_row2_3
    cpi counter,$10
    breq return_from_row2
    ldi temp,'6'
    rcall save_number_input_buffer
    rcall send_letter
next_key_row2_3:
    IN temp,PIND
    ANDI temp,$01
    CPI temp,$01
    brne return_from_row2
    cpi counter,$10
    breq return_from_row2

    lds temp,calculatorSign

    cpi temp,0
    brne return_from_row2
save_sign_row2:
	rcall save_counter
    ldi temp,'-'
    sts calculatorSign,temp
    rcall send_letter
    ldi counter,0 ; no erasable sign for now!!!
return_from_row2: 
    CBI PORTD,PORTD6
    ret 

check_row3:
    sbi PORTD,PORTD5
    rcall delay1mS
    in temp,PIND
    ANDI temp,$08
    CPI temp,$08
    brne next_key_row3_1
    cpi counter,$10
    breq return_from_row3
    ldi temp,'7'
    rcall save_number_input_buffer
    rcall send_letter
next_key_row3_1:
    in temp,PIND
    ANDI temp,$04
    CPI temp,$04
    brne next_key_row3_2
    cpi counter,$10
    breq return_from_row3
    ldi temp,'8'
    rcall save_number_input_buffer
    rcall send_letter
next_key_row3_2:
    in temp,PIND
    andi temp,$02
    cpi temp,$02
    brne next_key_row3_3
    cpi counter,$10
    breq return_from_row3
    ldi temp,'9'
    rcall save_number_input_buffer
    rcall send_letter
next_key_row3_3:
    in temp,PIND
    andi temp,$01
    cpi temp,$01
    brne return_from_row3
    cpi counter,$10
    breq return_from_row3

    lds temp,calculatorSign

	cpi temp,0
    brne return_from_row3
save_sign_row3:
	rcall save_counter
    ldi temp,'*'
    sts calculatorSign,temp
    rcall send_letter
    ldi counter,0 ; no erasable sign for now!!!
return_from_row3:
    CBI PORTD,PORTD5
    ret

check_row4:
    sbi PORTD,PORTD4
    rcall delay1mS
    in temp,PIND
    andi temp,$08 ; Clear button 
    cpi temp,$08 ; 
    brne next_key_row4_1 
    rcall undo
next_key_row4_1:
    IN temp,PIND
    andi temp,$04
    cpi temp,$04
    brne next_key_row4_2
    cpi counter,$10
    breq return_from_row4
	cpi counter,0
	breq check_if_division_by_0
place_null:
	ldi temp,'0'
    rcall save_number_input_buffer
    rcall send_letter
	rjmp next_key_row4_2
check_if_division_by_0:
	lds temp,calculatorSign
	cpi temp,0b11111101
	breq next_key_row4_2
	rjmp place_null
next_key_row4_2:
    IN temp,PIND
    andi temp,$02
    cpi temp,$02 ; Equal button
    brne next_key_row4_3
    cpi counter,$10
	rcall save_counter
    rcall calculate
    breq return_from_row4
next_key_row4_3:
    IN temp,PIND
    andi temp,$01
    cpi temp,$01
    brne return_from_row4
    cpi counter,$10
    breq return_from_row4

    lds temp,calculatorSign

    cpi temp,0
    brne return_from_row4
save_sign_row4:	
	rcall save_counter
    ldi temp,0b11111101 ; / division
    sts calculatorSign,temp
    rcall send_letter
    ldi counter,0 ; no erasable sign for now!!!
return_from_row4:
    CBI PORTD,PORTD4
    ret

check_reset:
    IN temp,PINC
    andi temp,$04
	cpi temp,$04 ;enable for debug!!!
    brne return_from_reset ; lol it should be cpi i guess... 
    rcall reset_calc
return_from_reset:
    ret


save_counter: 
	ldi ZL,low(calculatorSign)
	ldi ZH,high(calculatorSign)
	ld temp, Z
	cpi temp,0
	brne save_counter_calc_string2
save_counter_calc_string1: 
	ldi ZL,low(calculatorInput1Length)
	ldi ZH,high(calculatorInput1Length)
    st Z,counter
	rjmp return_save_counter
save_counter_calc_string2:
	ldi ZL,low(calculatorInput2Length)
	ldi ZH,high(calculatorInput2Length)
	st Z,counter 
return_save_counter:
	ret

reset_calc: 
    ldi temp,entry_mode     ; entry mode
    rcall send_command

    ldi temp,clear_display ; clear display instruction
    rcall send_command
    
    rcall reset_memory
  
    ret

reset_memory:
    ldi temp,0
    sts calculatorSign,temp
    sts calculatorInput1Length,temp
    sts calculatorInput2Length,temp
    sts calculatorOutputLength,temp
	rcall reset_memory_output
	rcall reset_memory_input1
	rcall reset_memory_input2
	ldi temp1,0
    ldi temp2,0
    ldi temp3,0
    ldi counter,0
    ret

print:
    lpm temp,Z+
    cp temp,zero
    breq end_print_loop
    rcall send_letter
    ldi temp,10
    rcall delayTx1mS
    rjmp print
end_print_loop:
    ret

reset_counter:
    ldi counter,0
    ret

undo: ;; for deleting numbers
     
    lds temp,calculatorSign
    cpi temp,0
    brne undo_1

undo_1: ; logic for undo button to check if we are in first input or in second input and clear memory values there IT CAUSE A LOT OF ERRORS IN APP
    mov temp,counter
    cpi counter,0
    breq return_undo ;; if counter is 0 ... Beginning of the screen

    dec counter
	
	lds temp,calculatorSign
	cpi temp,0
	breq undo_input1
undo_input2:
	ldi YL,low(calculatorInput2)
	ldi YH,high(calculatorInput2)

	add YL,counter

	ldi temp,0

	st Y,temp

	rjmp undo_from_screen
undo_input1:
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)

	add YL,counter

	ldi temp,0

	st Y,temp
undo_from_screen:
    ldi temp,entry_mode
    rcall send_command

    ldi temp,set_cursor_shift_left
    rcall send_command

    ldi temp,' '
    rcall send_letter 
    rcall send_letter

    ldi temp,2;

    sub counter,temp

    ldi temp,entry_mode
    rcall send_command

    ldi temp,set_cursor_shift_right
    rcall send_command

    ldi temp,shift_right
    rcall send_command
return_undo:
    ret 

jump_multiply:
	rjmp multiply
jump_subtraction:
	rjmp subtraction
jump_division:
	rjmp division
calculate:
    lds temp,calculatorSign
    cpi temp,'+'
    breq addition
    cpi temp,'-'
    breq jump_subtraction
	cpi temp,'*'
	breq jump_multiply
	cpi temp,0b11111101
	breq jump_division
    ret
addition:
	rcall clear_output_sign
    rcall translate_string_to_numbers
	lds temp1,calculatorInput1Length
	lds temp2,calculatorInput2Length
	dec temp1
	dec temp2
	cp temp2,temp1
	breq store_more_input1
	cp temp2,temp1
	brge store_more_input2
store_more_input1:
	sts calculatorOutputLength,temp1
	cp temp1,temp2
	breq same_length_input
	rjmp more_length_input1
store_more_input2:
	sts calculatorOutputLength,temp2
	cp temp1,temp2
	breq same_length_input
	rjmp more_length_input2
more_length_input1:
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
    add YL,temp1
    ld temp,Y
	ldi XL,low(calculatorInput2) 
	ldi XH,high(calculatorInput2)
	add XL,temp2
	ld temp3,X
	clc
	adc temp,temp3
	ldi YL,low(calculatorOutput)
	ldi YH,high(calculatorOutput)
	add YL,temp1
	st Y,temp
	cpi temp2,0
	dec temp1
	breq more_length_input1_1
	dec counter
	dec temp2
	rjmp more_length_input1
more_length_input1_1:
	lds counter,calculatorInput1Length
more_length_input1_1_loop:
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)
	add YL,temp1
	ld temp,Y
	ldi YH,high(calculatorOutput)
	ldi YL,low(calculatorOutput)
	add YL,temp1
	st Y,temp
	cpi temp1,0
	breq exit_addition
	dec temp1
	rjmp more_length_input1_1_loop
same_length_input:
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
    add YL,temp1
    ld temp,Y
	ldi XL,low(calculatorInput2) 
	ldi XH,high(calculatorInput2)
	add XL,temp2
	ld temp3,X
	clc
	adc temp,temp3
	ldi YL,low(calculatorOutput)
	ldi YH,high(calculatorOutput)
	add YL,temp1
	st Y,temp
	cpi temp1,0
	breq exit_addition
	dec temp1
	dec counter
	dec temp2
	rjmp same_length_input
more_length_input2:
	ldi YL,low(calculatorInput2)
    ldi YH,high(calculatorInput2)
    add YL,temp2
    ld temp,Y
	ldi XL,low(calculatorInput1) 
	ldi XH,high(calculatorInput1)
	add XL,temp1
	ld temp3,X
	clc
	adc temp,temp3
	ldi YL,low(calculatorOutput)
	ldi YH,high(calculatorOutput)
	add YL,temp2
	st Y,temp
	cpi temp1,0
	dec temp2
	breq more_length_input2_1
	dec counter
	dec temp1
	rjmp more_length_input2
more_length_input2_1:
	lds counter,calculatorInput2Length
more_length_input2_1_loop:
	ldi YL,low(calculatorInput2)
	ldi YH,high(calculatorInput2)
	add YL,temp2
	ld temp,Y
	ldi YH,high(calculatorOutput)
	ldi YL,low(calculatorOutput)
	add YL,temp2
	st Y,temp
	cpi temp2,0
	breq exit_addition
	dec temp2
	rjmp more_length_input2_1_loop
exit_addition:
	rcall calculate_carry
	rcall translate_numbers_to_string
	rcall print_calculator_output
    ret
subtraction:
    rcall translate_string_to_numbers
	lds temp1,calculatorInput1Length
	lds temp2,calculatorInput2Length
    ldi counter,0
	dec temp1
	dec temp2
    cp temp1,temp2
    breq same_length_subtraction
    cp temp1,temp2
    brsh plus_subtraction
    rjmp minus_subtraction
same_length_subtraction:
    ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
    add YL,counter
    ldi XL,low(calculatorInput2)
    ldi XH,high(calculatorInput2)
    add XL,counter
    ld temp,Y
    ld temp3,X
    cp temp,temp3
    breq same_length
    cp temp,temp3
    brsh plus_subtraction
    rjmp minus_subtraction
jump_output_zero:
	rjmp output_zero
same_length:
    cp counter,temp1
    breq jump_output_zero
    inc counter
    rjmp same_length_subtraction
plus_subtraction: ; here some bugs need to rewrite it
	sts calculatorOutputLength, temp1
	rcall clear_output_sign
plus_subtraction_loop:
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
    add YL,temp1
    ld temp,Y
	ldi XL,low(calculatorInput2) 
	ldi XH,high(calculatorInput2)
	add XL,temp2
	ld temp3,X
	sub temp,temp3
	ldi YL,low(calculatorOutput)
	ldi YH,high(calculatorOutput)
	add YL,temp1
	st Y,temp
	cpi temp2,0
	breq plus_subtraction_1
	dec temp2
	dec temp1
	rjmp plus_subtraction_loop
plus_subtraction_1:
	lds counter,calculatorInput1Length
	cpi temp1,0
	breq exit_subtraction
	dec temp1
plus_subtraction_1_loop:
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)
	add YL,temp1
	ld temp,Y
	ldi YH,high(calculatorOutput)
	ldi YL,low(calculatorOutput)
	add YL,temp1
	st Y,temp
	cpi temp1,0
	breq exit_subtraction
	dec temp1
	rjmp plus_subtraction_1_loop
minus_subtraction: ; the same algorithm but you need to start from second input and add minus after operation!
	sts calculatorOutputLength, temp2
	rcall set_output_sign
minus_subtraction_loop:
	ldi YL,low(calculatorInput2)
    ldi YH,high(calculatorInput2)
    add YL,temp2
    ld temp,Y
	ldi XL,low(calculatorInput1) 
	ldi XH,high(calculatorInput1)
	add XL,temp1
	ld temp3,X
	sub temp,temp3
	ldi YL,low(calculatorOutput)
	ldi YH,high(calculatorOutput)
	add YL,temp2
	st Y,temp
	cpi temp1,0
	breq minus_subtraction_1
	dec temp1
	dec temp2
	rjmp minus_subtraction_loop
minus_subtraction_1:
	lds counter,calculatorInput2Length
	cpi temp2,0
	breq exit_subtraction
	dec temp2
minus_subtraction_1_loop:
	ldi YL,low(calculatorInput2)
	ldi YH,high(calculatorInput2)
	add YL,temp2
	ld temp,Y
	ldi YH,high(calculatorOutput)
	ldi YL,low(calculatorOutput)
	add YL,temp2
	st Y,temp
	cpi temp2,0
	breq exit_subtraction
	dec temp2
	rjmp minus_subtraction_1_loop
output_zero:
	ldi temp,0
	sts calculatorOutputLength,temp
	ldi temp,0
	sts calculatorOutput,temp
	rcall translate_numbers_to_string
	rcall print_calculator_output
	ret
exit_subtraction:
	rcall calculate_borrow
	rcall shift_output_borrow ; not stable! it replace sign memory byte sometimes! keep this in mind
	rcall translate_numbers_to_string
	rcall print_calculator_output
    ret 
multiply:
	rcall clear_output_sign
    rcall translate_string_to_numbers
	;; here logic for multiplication
	lds temp1,calculatorInput1Length
	lds temp2,calculatorInput2Length
	dec temp1
	dec temp2
	ldi temp,15
	ldi counter,0
multiply_loop:
	push temp
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)
	add YL,temp1
	ldi XL,low(calculatorInput2) 
	ldi XH,high(calculatorInput2)
	add XL,temp2
	ld temp,Y
	ld temp3,X
	mul temp,temp3 ; unsigned multiplication IN R0 we have result
	mov temp3,r0
	pop temp
	ldi ZL,low(calculatorOutput)
	ldi ZH,high(calculatorOutput)
	add ZL,temp
	ld temp4,Z
	add temp3,temp4
	st Z,temp3
	cpi temp1,0
	breq next_number
	dec temp
	dec temp1
	inc counter
	rjmp multiply_loop
next_number: 
	cpi temp2,0
	breq exit_multiply	
	lds temp1,calculatorInput1Length
	dec temp1
	dec temp2 
	dec counter
	add temp,counter
	rjmp multiply_loop
exit_multiply:
	rcall count_multiplication_output_carry_length
	rcall calculate_carry_multiplication
	rcall count_output_length
	rcall shift_output_multiplication_left
	rcall translate_numbers_to_string
	rcall print_calculator_output
	ret


jump_output_null:
	rjmp output_null
division:
	rcall translate_string_to_numbers
	ldi temp4,0 ; this will be our kind of counter
	lds temp1,calculatorInput1Length
	lds temp2,calculatorInput2Length
	cp temp1,temp2
    brlo jump_output_null
division_loop:
	cpi temp4,$0A
	brne division_loop_continue
	ldi temp4,0
division_loop_continue:
	rcall calculate_borrow_division
	rcall shift_input1_division
	rcall count_multiplication_output_carry_length
	rcall calculate_carry_multiplication ; i think this will fit well
	rcall count_output_length
	lds temp1,calculatorInput1Length
	lds temp2,calculatorInput2Length
    ldi counter,0
	dec temp1
	dec temp2
	cp temp1,temp2
    breq same_length_division
    cp temp1,temp2
    brsh plus_division
    rjmp same_length_division_2
same_length_division:
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
    add YL,counter
    ldi XL,low(calculatorInput2)
    ldi XH,high(calculatorInput2)
    add XL,counter
    ld temp,Y
    ld temp3,X
    cp temp,temp3
    breq same_length_division_1
    cp temp,temp3
    brsh plus_division
    rjmp same_length_division_2
same_length_division_1:
	cp counter,temp1
    breq same_length_division_2
    inc counter
    rjmp same_length_division
plus_division:
	sts calculatorOutputLength, temp1
	rcall clear_output_sign
plus_division_loop:
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
    add YL,temp1
    ld temp,Y
	ldi XL,low(calculatorInput2) 
	ldi XH,high(calculatorInput2)
	add XL,temp2
	ld temp3,X
	sub temp,temp3
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)
	add YL,temp1
	st Y,temp
	cpi temp2,0
	breq plus_division_1
	dec temp2
	dec temp1
	rjmp plus_division_loop
jump_exit_division:
	rjmp exit_division
plus_division_1:
	lds counter,calculatorInput1Length
	cpi temp1,0
	breq jump_exit_division
	dec temp1
plus_division_1_loop:
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)
	add YL,temp1
	ld temp,Y
	ldi YH,high(calculatorInput1)
	ldi YL,low(calculatorInput1)
	add YL,temp1
	st Y,temp
	cpi temp1,0
	breq jump_exit_division
	dec temp1
	rjmp plus_division_1_loop
same_length_division_2:
	lds temp,calculatorInput1Length
	lds temp1,calculatorInput2Length
	cp temp,temp1
	brlo add_rest
	ldi temp4,0
same_length_division_2_loop:
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)
	add YL,temp4
	ldi XL,low(calculatorInput2) 
	ldi XH,high(calculatorInput2)
	add YL,temp4
	ld temp2,Y
	ld temp3,X
	cp temp2,temp3
	brlo add_rest  
	cp temp,temp1
	breq check_rest
check_rest:
	ldi temp4,0
check_rest_loop:
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)
	ldi XL,low(calculatorInput2) 
	ldi XH,high(calculatorInput2)
	add YL,temp4
	add XL,temp4
	ld temp2,Y
	ld temp3,X
	cp temp2,temp3
	breq check_res_next_pos
	cp temp2,temp3
	brlo add_rest
check_res_next_pos:
	cp temp4,temp
	breq no_rest
	inc temp4
	rjmp check_rest_loop
add_rest:
	ldi temp,1
	sts calculatorOutputRest,temp
	rjmp return_same_length_division_2
no_rest:
	ldi temp,0
	sts calculatorOutputRest,temp
	ldi YL,low(calculatorOutput)
	ldi YH,high(calculatorInput1)
	ldi temp,15
	add YL,temp
	ld temp,Y
	inc temp
	st Y,temp
return_same_length_division_2:
	rcall count_multiplication_output_carry_length
	rcall calculate_carry_multiplication ; i think this will fit well
	rcall count_output_length
	rcall shift_output_multiplication_left
	rcall translate_numbers_to_string
	rcall print_calculator_output
	rcall add_rest_output
	ret	
output_one:
	rcall same_length_subtraction
	ldi temp,0
	sts calculatorOutputLength,temp
	ldi temp,1
	sts calculatorOutput,temp
	rcall translate_numbers_to_string
	rcall print_calculator_output
	ret	
output_null:
	ldi temp,0
	sts calculatorOutput,temp
	sts calculatorOutputRest,temp
	sts calculatorOutputLength,temp
	rcall translate_numbers_to_string
	rcall print_calculator_output
	ret
exit_division: ; do we need this?
	ldi temp,15
	ldi YL,low(calculatorOutput)
	ldi YH,high(calculatorOutput)
	add YL,temp
	inc temp4
	st Y,temp4
	rjmp division_loop

jump_second_line_lcd:
    ldi temp,entry_mode
    rcall send_command

    ldi temp,force_cursor_beginning_second_line
    rcall send_command
    ret

translate_numbers_to_string_division_rest:
	ldi counter,0
	lds temp1,calculatorInput1Length
translate_numbers_to_string_division_rest_loop:
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
    add YL,counter
	ld temp,Y
	cpi temp,0
	breq translate_zero_division_rest
	cpi temp,1
	breq translate_one_division_rest
	cpi temp,2
	breq translate_two_division_rest
	cpi temp,3
	breq translate_three_division_rest
	cpi temp,4
	breq translate_four_division_rest
	cpi temp,5
	breq translate_five_division_rest
	cpi temp,6
	breq translate_six_division_rest
	cpi temp,7
	breq translate_seven_division_rest
	cpi temp,8
	breq translate_eight_division_rest
	cpi temp,9
	breq translate_nine_division_rest
translate_zero_division_rest:
	ldi temp,'0'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_one_division_rest:
	ldi temp,'1'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_two_division_rest:
	ldi temp,'2'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_three_division_rest:
	ldi temp,'3'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_four_division_rest:
	ldi temp,'4'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_five_division_rest:
	ldi temp,'5'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_six_division_rest:
	ldi temp,'6'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_seven_division_rest:
	ldi temp,'7'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_eight_division_rest:
	ldi temp,'8'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
translate_nine_division_rest:
	ldi temp,'9'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string_division_rest	
	inc counter
	rjmp translate_numbers_to_string_division_rest_loop
return_translate_numbers_to_string_division_rest:
	ret

translate_numbers_to_string:
	ldi counter,0
	lds temp1,calculatorOutputLength
translate_numbers_to_string_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
    add YL,counter
	ld temp,Y
	cpi temp,0
	breq translate_zero
	cpi temp,1
	breq translate_one
	cpi temp,2
	breq translate_two
	cpi temp,3
	breq translate_three
	cpi temp,4
	breq translate_four
	cpi temp,5
	breq translate_five
	cpi temp,6
	breq translate_six
	cpi temp,7
	breq translate_seven
	cpi temp,8
	breq translate_eight
	cpi temp,9
	breq translate_nine
translate_zero:
	ldi temp,'0'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string
	inc counter
	rjmp translate_numbers_to_string_loop
translate_one:
	ldi temp,'1'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string
	inc counter
	rjmp translate_numbers_to_string_loop
translate_two:
	ldi temp,'2'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string
	inc counter
	rjmp translate_numbers_to_string_loop
translate_three:
	ldi temp,'3'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string
	inc counter
	rjmp translate_numbers_to_string_loop
translate_four:
	ldi temp,'4'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string
	inc counter
	rjmp translate_numbers_to_string_loop
translate_five:
	ldi temp,'5'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string
	inc counter
	rjmp translate_numbers_to_string_loop
translate_six:
	ldi temp,'6'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string
	inc counter
	rjmp translate_numbers_to_string_loop
translate_seven:
	ldi temp,'7'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string
	inc counter
	rjmp translate_numbers_to_string_loop
translate_eight:
	ldi temp,'8'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string	
	inc counter
	rjmp translate_numbers_to_string_loop
translate_nine:
	ldi temp,'9'
	st Y,temp
	cp counter,temp1
	breq return_translate_numbers_to_string	
	inc counter
	rjmp translate_numbers_to_string_loop
return_translate_numbers_to_string:
	ret

translate_string_to_numbers: 
    ldi counter,0
translate_string_to_numbers_loop:
    ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
    add YL,counter
    ld temp,Y
    cpi temp,0
    breq translate_input2
    cpi temp,'0'
    breq swap_zero
    cpi temp,'1'
    breq swap_one
    cpi temp,'2'
    breq swap_two
    cpi temp,'3'
    breq swap_three
    cpi temp,'4'
    breq swap_four
    cpi temp,'5'
    breq swap_five
    cpi temp,'6'
    breq swap_six
    cpi temp,'7'
    breq swap_seven
    cpi temp,'8'
    breq swap_eight
    cpi temp,'9'
    breq swap_nine
swap_zero:
    ldi temp,0
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop
swap_one:
    ldi temp,1
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop
swap_two:
    ldi temp,2
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop
swap_three:
    ldi temp,3
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop
swap_four:
    ldi temp,4
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop
swap_five:
    ldi temp,5
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop
swap_six:
    ldi temp,6
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop
swap_seven:
    ldi temp,7
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop 
swap_eight:
    ldi temp,8
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop
swap_nine:
    ldi temp,9
    st Y,temp
    inc counter
    rjmp translate_string_to_numbers_loop

translate_input2:
    ldi counter,0
loop_for_input2:
	ldi YL,low(calculatorInput2)
    ldi YH,high(calculatorInput2)
    add YL,counter
    ld temp,Y
	cpi temp,0
	breq return_translate_string_to_numbers
	cpi temp,'0'
    breq swap_zero_2
    cpi temp,'1'
    breq swap_one_2
    cpi temp,'2'
    breq swap_two_2
    cpi temp,'3'
    breq swap_three_2
    cpi temp,'4'
    breq swap_four_2
    cpi temp,'5'
    breq swap_five_2
    cpi temp,'6'
    breq swap_six_2
    cpi temp,'7'
    breq swap_seven_2
    cpi temp,'8'
    breq swap_eight_2
    cpi temp,'9'
    breq swap_nine_2
swap_zero_2:
    ldi temp,0
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_one_2:
    ldi temp,1
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_two_2:
    ldi temp,2
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_three_2:
    ldi temp,3
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_four_2:
    ldi temp,4
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_five_2:
    ldi temp,5
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_six_2:
    ldi temp,6
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_seven_2:
    ldi temp,7
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_eight_2:
    ldi temp,8
    st Y,temp
    inc counter
    rjmp loop_for_input2
swap_nine_2:
    ldi temp,9
    st Y,temp
    inc counter
    rjmp loop_for_input2
return_translate_string_to_numbers:
    ret

print_calculator_output:
	ldi temp,'='
	rcall send_letter

	rcall jump_second_line_lcd
	
	ldi temp,'='
	rcall send_letter

	lds temp,calculatorOutputSign
	cpi temp,1
	brne print_calculator_output_1

	ldi temp,'-'
	rcall send_letter

print_calculator_output_1:
	ldi counter,0
	lds temp1,calculatorOutputLength
    inc temp1 ; this must be 
print_calculator_output_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
    add YL,counter
	ld temp,Y
	rcall send_letter
	cp counter,temp1
	breq return_print_calculator_output
    rjmp print_calculator_output_loop
return_print_calculator_output:
	ret 

jump_switch_12:
	rjmp switch_12
jump_switch_13:
	rjmp switch_13
jump_shift_memory_calc_output:
	rjmp shift_memory_calc_output
additional_label_to_return_from_carry_calculation:
	rjmp return_calculate_carry
calculate_carry:
	lds counter,calculatorOutputLength
	lds temp1,0
loop_calculate_carry:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	clc 
	adc YL,counter
	ld temp,Y
	cpi temp1,1
	brne switches
	inc temp
switches:
	cpi temp,$0A
	breq switch_0A
	cpi temp,$0B
	breq switch_0B
	cpi temp,$0C
	breq switch_0C
	cpi temp,$0D
	breq switch_0D
	cpi temp,$0E
	breq switch_0E
	cpi temp,$0F
	breq switch_0F
	cpi temp,$10
	breq switch_10
	cpi temp,$11
	breq switch_11
	cpi temp,$12
	breq jump_switch_12  ; HERE GAVRASM DO NOT SHOW ANY ERROR!!! When we go switch_12
	cpi temp,$13
	breq jump_switch_13
no_switch:
	ldi temp1,0
	cpi counter,0
	st Y,temp
	breq additional_label_to_return_from_carry_calculation
	dec counter
	rjmp loop_calculate_carry
switch_0A:
	ldi temp,0
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq jump_shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_0B:
	ldi temp,1
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_0C:
	ldi temp,2
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_0D:
	ldi temp,3
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_0E:
	ldi temp,4
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_0F:
	ldi temp,5
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_10:
	ldi temp,6
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_11:
	ldi temp,7
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_12:
	ldi temp,8
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
switch_13:
	ldi temp,9
	ldi temp1,1
	st Y,temp
	cpi counter,0
	breq shift_memory_calc_output
	dec counter
	rjmp loop_calculate_carry
shift_memory_calc_output:
	lds counter,calculatorOutputLength
shift_memory_calc_output_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	clc 
	adc YL,counter
	ld temp,Y
	inc YL
	st Y,temp
	cpi counter,0
	breq return_calculate_carry_shift
	dec counter
	rjmp shift_memory_calc_output_loop
return_calculate_carry_shift:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	ldi temp,1
	st Y,temp
	lds temp,calculatorOutputLength
	inc temp
	sts calculatorOutputLength,temp
	ret
return_calculate_carry:
	ret

calculate_borrow:
	lds counter,calculatorOutputLength
	lds temp3,calculatorOutputLength
calculate_borrow_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	clc
	adc YL,counter
	ld temp,Y
	cpi counter,0
	breq exit_calculate_borrow
check_borrow:
	dec counter
	ld temp1,Y
	push temp
	andi temp,$F0
	cpi temp,$F0
	breq borrow
	pop temp
jump_loop:
	dec counter
	inc counter
	rjmp calculate_borrow_loop
borrow:
	pop temp
	subi temp,6
	andi temp,$0F
	st Y,temp
	dec YL
	ld temp1,Y
	dec temp1
	st Y,temp1
	rjmp jump_loop
exit_calculate_borrow:
	ret

calculate_borrow_division:
	lds counter,calculatorInput1Length
	lds temp3,calculatorInput1Length
calculate_borrow_division_loop:
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
	clc
	adc YL,counter
	ld temp,Y
	cpi counter,0
	breq exit_calculate_borrow_division
check_borrow_division:
	dec counter
	ld temp1,Y
	push temp
	andi temp,$F0
	cpi temp,$F0
	breq borrow_division
	pop temp
jump_loop_division:
	dec counter
	inc counter
	rjmp calculate_borrow_division_loop
borrow_division:
	pop temp
	subi temp,6
	andi temp,$0F
	st Y,temp
	dec YL
	ld temp1,Y
	dec temp1
	st Y,temp1
	rjmp jump_loop_division
exit_calculate_borrow_division:
	ret

shift_output_borrow:
	lds counter,calculatorOutputLength
	ldi temp,0 ; counter for fields
	ldi temp2,0 ; counter for how many shifts we need to use
	ldi temp3,0
	clc
shift_output_borrow_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	adc YL,temp
	ld temp1,Y
	cpi temp1,0
	brne shift_left_loop
add_shift:
	inc temp2
	inc temp 
	rjmp shift_output_borrow_loop
shift_left_loop:
	cpi temp2,0
	breq exit_shift
	rcall shift_output_left
	dec temp2
	sub temp,temp3
	dec temp
	rjmp shift_left_loop
exit_shift:
	ret
	
shift_output_left:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	add YL,temp
	ld temp1,Y
	push temp1
	ldi temp1,0
	st Y,temp1
	pop temp1
	dec YL 
	st Y,temp1
	cp temp,counter
	breq exit_shift_output_left
	inc temp
	inc temp3
	rjmp shift_output_left
exit_shift_output_left:
	dec counter
	sts calculatorOutputLength,counter
	ret 

count_multiplication_output_carry_length:
	ldi temp,0
	ldi counter,0
count_multiplication_output_carry_length_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	add YL,temp
	ld temp1,Y
	cpi temp1,0
	brne return_count_multiplication_output_carry_length
	inc counter
	inc temp
	rjmp count_multiplication_output_carry_length_loop
return_count_multiplication_output_carry_length:
	ldi temp,15
	sub temp,counter
	sts calculatorOutputCarryLength,temp
	ret

set_output_sign: 
    push temp
    lds temp,calculatorOutputSign
    ldi temp,1
    sts calculatorOutputSign,temp
    pop temp
    ret

clear_output_sign:
    push temp
    lds temp,calculatorOutputSign
    ldi temp,0
    sts calculatorOutputSign,temp
    pop temp
    ret

shift_input1_division:
	ldi temp1,0
	lds counter,calculatorInput1Length
	dec counter
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
	ld temp,Y
	cpi temp,0
	breq shift_input1
	ret
shift_input1:
	cp temp1,counter
	breq return_shift_input1_division
	inc YL 
	ld temp,Y
	dec YL
	st Y,temp
	inc YL
	ldi temp,0
	st Y,temp
	inc temp1
	rjmp shift_input1
return_shift_input1_division:
	lds temp,calculatorInput1Length
	dec temp
	sts calculatorInput1Length,temp
	ret


calculate_carry_multiplication: ; my scientific research showed that highest carry value in multiplication is 17
	ldi counter,15
	ldi temp2,15
	lds temp1,calculatorOutputCarryLength
calculate_carry_multiplication_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	add YL,temp2
	ld temp,Y
	cpi temp,$0A
	brlo jump_carry_0
	cpi temp,$14
	brlo jump_carry_1
	cpi temp,$1E
	brlo jump_carry_2
	cpi temp,$28
	brlo jump_carry_3
	cpi temp,$32
	brlo jump_carry_4
	cpi temp,$3C
	brlo jump_carry_5
	cpi temp,$46
	brlo jump_carry_6
	cpi temp,$50
	brlo jump_carry_7
	cpi temp,$5A
	brlo jump_carry_8
	cpi temp,$64
	brlo jump_carry_9
	cpi temp,$6E
	brlo jump_carry_10
	cpi temp,$78
	brlo jump_carry_11
	cpi temp,$82
	brlo jump_carry_12
	cpi temp,$8C
	brlo jump_carry_13
	cpi temp,$96
	brlo jump_carry_14
	cpi temp,$A0
	brlo jump_carry_15
	cpi temp,$AA
	brlo jump_carry_16
	cpi temp,$B4
	brlo jump_carry_17
jump_carry_0:
	rjmp carry_0
jump_carry_1:
	rjmp carry_1
jump_carry_2:
	rjmp carry_2
jump_carry_3:
	rjmp carry_3
jump_carry_4:
	rjmp carry_4
jump_carry_5:
	rjmp carry_5
jump_carry_6:
	rjmp carry_6
jump_carry_7:
	rjmp carry_7
jump_carry_8:
	rjmp carry_8
jump_carry_9:
	rjmp carry_9
jump_carry_10:
	rjmp carry_10
jump_carry_11:
	rjmp carry_11
jump_carry_12:
	rjmp carry_12
jump_carry_13:
	rjmp carry_13
jump_carry_14:
	rjmp carry_14
jump_carry_15:
	rjmp carry_15
jump_carry_16:
	rjmp carry_16
jump_carry_17:
	rjmp carry_17
jump_return_calculate_carry_multiplication_1:
	rjmp return_calculate_carry_multiplication

	carry_0:
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication_1
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_1:
	ldi temp3,$A
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	inc temp
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_2:
	ldi temp3,$14
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,2
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_3:
	ldi temp3,$1E
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,3
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_4:
	ldi temp3,$28
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,4
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_5:
	ldi temp3,$32
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,5
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
jump_return_calculate_carry_multiplication:
	rjmp return_calculate_carry_multiplication
	carry_6:
	ldi temp3,$3C
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,6
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_7:
	ldi temp3,$46
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,7
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_8:
	ldi temp3,$50
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,8
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_9:
	ldi temp3,$5A
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,9
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_10:
	ldi temp3,$64
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,$0A
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_11:
	ldi temp3,$6E
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,$0B
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication_2
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	jump_return_calculate_carry_multiplication_2:
	rjmp return_calculate_carry_multiplication
	carry_12:
	ldi temp3,$78
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,$0C
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq jump_return_calculate_carry_multiplication_2
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_13:
	ldi temp3,$82
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,$0D
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_14:
	ldi temp3,$8C
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,$0E
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_15:
	ldi temp3,$96
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,$0F
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_16:
	ldi temp3,$A0
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,$10
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
	carry_17:
	ldi temp3,$AA
	sub temp,temp3
	st Y,temp
	dec YL
	ld temp,Y
	ldi temp3,$11
	add temp,temp3
	st Y,temp
	cpi temp1,0
	breq return_calculate_carry_multiplication
	dec temp1
	dec temp2
	rjmp calculate_carry_multiplication_loop
return_calculate_carry_multiplication:
	ret

count_output_length:
	ldi temp,0
	ldi counter,0
count_output_length_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	add YL,temp
	ld temp1,Y
	cpi temp1,0
	brne return_count_output_length
	inc counter
	inc temp
	rjmp count_output_length_loop
return_count_output_length:
	ldi temp,15
	sub temp,counter
	sts calculatorOutputLength,temp
	ret

shift_output_multiplication_left:
	lds counter,calculatorOutputLength
	ldi temp1,0
	ldi temp3,0
shift_output_multiplication_left_loop:
	ldi temp,15
	sub temp,counter
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	add YL,temp
	ld temp2,Y
	st Y,temp3 
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	add YL,temp1
	st Y,temp2
	cpi counter,0
	breq return_shift_output_multiplication_left
	dec counter
	inc temp1
	rjmp shift_output_multiplication_left_loop
return_shift_output_multiplication_left:
	ret

reset_memory_output:
	ldi counter,0
	ldi temp,0
reset_memory_output_loop:
	ldi YL,low(calculatorOutput)
    ldi YH,high(calculatorOutput)
	add YL,counter
	st Y,temp
	cpi counter,15
	breq return_reset_memory_output
	inc counter
	rjmp reset_memory_output_loop
return_reset_memory_output:
	ret

reset_memory_input1:
	ldi counter,0
	ldi temp,0
reset_memory_input1_loop:
	ldi YL,low(calculatorInput1)
    ldi YH,high(calculatorInput1)
	add YL,counter
	st Y,temp
	cpi counter,15
	breq return_reset_memory_input1
	inc counter
	rjmp reset_memory_input1_loop
return_reset_memory_input1:
	ret

reset_memory_input2:
	ldi counter,0
	ldi temp,0
reset_memory_input2_loop:
	ldi YL,low(calculatorInput2)
    ldi YH,high(calculatorInput2)
	add YL,counter
	st Y,temp
	cpi counter,15
	breq return_reset_memory_input2
	inc counter
	rjmp reset_memory_input2_loop
return_reset_memory_input2:
	ret

add_rest_output:
	lds temp1,calculatorInput1Length
	lds temp,calculatorOutputRest
	cpi temp,1
	brne return_add_rest_output
	ldi XL,low(calculatorOutput)
	ldi XH,high(calculatorOutput)
    ldi ZL,low(restString<<1)
    ldi ZH,high(restString<<1) ; word alignment
    rcall print
	rcall translate_numbers_to_string_division_rest
	ldi counter,0
add_rest_output_loop:
	ldi YL,low(calculatorInput1)
	ldi YH,high(calculatorInput1)
	add YL,counter
	ld temp,Y
	rcall send_letter
	cp counter,temp1
	breq return_add_rest_output
	rjmp add_rest_output_loop
return_add_rest_output:
	ret

press_any_key_check:
    sbi PORTD,PORTD7
    sbi PORTD,PORTD6
    sbi PORTD,PORTD5
    rcall delay1mS
    IN temp,PIND
    ANDI temp,$0F
    cpi temp,0
    brne pressed_any_key
    cbi PORTD,PORTD7
    cbi PORTD,PORTD6
    cbi PORTD,PORTD5
    ret
pressed_any_key:
    rcall reset_calc
    rcall reset_counter
    rcall reset_memory
    cbi PORTD,PORTD7
    cbi PORTD,PORTD6
    cbi PORTD,PORTD5
    ret

delayTx1mS:
    rcall delay1mS
    dec R16
    brne delayTx1mS
    ret

delay1mS:
    push YL
    push YH
    ldi YL,low(((fclk/1000)-18)/4)
    ldi YH,high(((fclk/1000)-18)/4)
delay1mS_01:
    sbiw YH:YL,1
    brne delay1mS_01
    pop YH
    pop YL
    ret

delayTx1uS:
    rcall delay1uS
    dec R16
    brne delayTx1uS
    ret

delay1uS:
    push    R16                           ; [2] these instructions do nothing except consume clock cycles
    pop     R16                            ; [2]
    push    R16                            ; [2]
    pop     R16                            ; [2]
    ret                                     ; [4]             