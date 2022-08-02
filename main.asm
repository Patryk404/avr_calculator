;
; ***********************************
; * (Add program task here)         *
; * (Add AVR type and version here) *
; * (C)2021 by Gerhard Schmidt      *
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
; (Add all user adjustable constants here, e.g.)
; .equ clock=1000000 ; Define the clock frequency
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
.equ decrement_cursor=$04
.equ increment_cursor=$06
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
calculatorSignIndex: .BYTE 1 ; to remember when we put sign! 
calculatorOutput: .BYTE 16
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
     ;;;;;;;;;;;;;


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

    rcall check_row1
    ldi temp,3
    rcall delayTx1mS

    rcall check_row2
    ldi temp,3
    rcall delayTx1mS

    rcall check_row3
    ldi temp,3
    rcall delayTx1mS

    rcall check_row4
    ldi temp,3
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
      out PORTB,temp
      sbi PORTC,PORTC0
      sbi PORTC,PORTC1
      rcall delay1uS
      cbi PORTC,PORTC1
      rcall delay1uS
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
      rcall send_letter
      
next_key_row1_1:
      IN temp,PIND
      ANDI temp,$04
      cpi temp,$04
      brne next_key_row1_2
      cpi counter,$10
      breq return_from_row1
      ldi temp,'2'
      rcall send_letter

next_key_row1_2:
      IN temp,PIND
      ANDI temp,$02
      cpi temp,$02
      brne next_key_row1_3
      cpi counter,$10
      breq return_from_row1
      ldi temp,'3'
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
      ldi temp,'+'
      sts calculatorSign,temp
      rcall send_letter
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
      add ZL,counter
      ldi temp,'4'
      st Z,temp
      rcall send_letter
next_key_row2_1:
      IN temp,PIND
      ANDI temp,$04
      CPI temp,$04
      brne next_key_row2_2
      cpi counter,$10
      breq return_from_row2
      add ZL,counter
      ldi temp,'5'
      st Z,temp
      rcall send_letter
next_key_row2_2:
      IN temp,PIND
      ANDI temp,$02
      CPI temp,$02
      brne next_key_row2_3
      cpi counter,$10
      breq return_from_row2
      add ZL,counter
      ldi temp,'6'
      st Z,temp
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
      ldi temp,'-'
      sts calculatorSign,temp
      rcall send_letter
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
    rcall send_letter
next_key_row3_1:
    in temp,PIND
    ANDI temp,$04
    CPI temp,$04
    brne next_key_row3_2
    cpi counter,$10
    breq return_from_row3
    ldi temp,'8'
    rcall send_letter
next_key_row3_2:
    in temp,PIND
    andi temp,$02
    cpi temp,$02
    brne next_key_row3_3
    cpi counter,$10
    breq return_from_row3
    ldi temp,'9'
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
    ldi temp,'*'
    sts calculatorSign,temp
    rcall send_letter
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
    ldi temp,'0'
    rcall send_letter
next_key_row4_2:
    IN temp,PIND
    andi temp,$02
    cpi temp,$02 ; Equal button
    brne next_key_row4_3
    cpi counter,$10
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
    ldi temp,0b11111101 ; / division
    sts calculatorSign,temp
    rcall send_letter
return_from_row4:
    CBI PORTD,PORTD4
    ret

check_reset:
    IN temp,PINC
    andi temp,$04
    brne return_from_reset
    rcall reset_calc
return_from_reset:
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
    ldi counter,0
    sts calculatorInput1,temp
    sts calculatorInput2,temp
    sts calculatorSign,temp
    sts calculatorOutput,temp
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
    ; ldi temp,0
    ; cpi temp,0
    ; breq return_undo


    ldi temp,entry_mode
    rcall send_command

    ldi temp,decrement_cursor
    rcall send_command

    ldi temp,' '
    rcall send_letter 
    rcall send_letter

    ldi temp,entry_mode
    rcall send_command

    ldi temp,increment_cursor
    rcall send_command

    ldi temp,0b00010100
    rcall send_command
return_undo:
    ret 

jump_second_line_lcd:
    ldi temp,entry_mode
    rcall send_command

    ldi temp,force_cursor_beginning_second_line
    rcall send_command
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

