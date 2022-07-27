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
; free: R17 to R29
; free: R31:R30 = Z
;
; **********************************
;           S R A M
; **********************************
;
.dseg
.org SRAM_START
; (Add labels for SRAM locations here, e.g.
; sLabel1:
;   .byte 16 ; Reserve 16 bytes)
;
; **********************************
;         C O D E
; **********************************
;
.cseg
.org 000000
;
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
      SBI DDRC,DDC0
      SBI DDRC,DDC1
      SER R16
      OUT DDRB,R16
                 ;;;;;;;;;;;;;;;;;;;;;;;;;
                 ;;;;;
Initialization_LCD_HARDWARE:
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

      ldi temp,0b01010000 ; "P"
      rcall send_letter

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01000001 ; "A"
      rcall send_letter

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01010100 ; "T"
      rcall send_letter

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01010010 ; "R"
      rcall send_letter

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01011001 ; "Y"
      rcall send_letter

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01001011 ; "K"
      rcall send_letter

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b00110100 ; "4"
      rcall send_letter

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b00110000 ; "0"
      rcall send_letter

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b00110100 ; "4"
      rcall send_letter

;
; **********************************
;    P R O G R A M   L O O P
; **********************************
;
Loop:
	rjmp loop

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
;
; End of source code
;
; (Add Copyright information here, e.g.
; .db "(C)2021 by Gerhard Schmidt  " ; Source code readable
; .db "C(2)20 1ybG reahdrS hcimtd  " ; Machine code format
;

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

