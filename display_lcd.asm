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
      SBI DDRB,DDB0
      SBI DDRB,DDB1
      SER R16
      OUT DDRD,R16
                 ;;;;;;;;;;;;;;;;;;;;;;;;;
                 ;;;;;
Initialization_LCD_HARDWARE:
      ldi temp,200
      rcall delayTx1mS

      ; first part of reset sequence

      ldi temp,0b00110000  ; reset LCD
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,10
      rcall delayTx1mS

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ; second part of reset sequence
      ldi temp,0b00110000
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,200
      rcall delayTx1uS

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ; Third part of reset sequence
      ldi temp,0b00110000
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,200
      rcall delayTx1uS
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


      ; set mode lines and font
      ldi temp,0b00111000
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,80
      rcall delayTx1uS
      ;;;;;;;;;;;;;;;;;;;;;;;;;

      ; Display On/Off Control instruction
      ldi temp,0b00001000        ;; DISPLAY OFF
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,80
      rcall delayTx1uS


      ldi temp,0b00000001 ; clear display instruction
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,4
      rcall delayTx1mS


      ldi temp,0b00000110     ; entry mode
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,80
      rcall delayTx1uS

      ldi temp,0b00001111 ; turn display on enable cursor and blink ;)
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,80
      rcall delayTx1uS
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ;;;;;;;;;;;;;;;;;;;;;;;;;;; WRITING SCREEN!

      ldi temp,0b10000000 ; SET POSITION OF CURSOR
      out PORTD,temp
      rcall clear_enable
      rcall enable_lol
      ldi temp,80
      rcall delayTx1uS

      ldi temp,0b01010000 ; "P"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01000001 ; "A"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01010100 ; "T"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01010010 ; "R"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01011001 ; "Y"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b01001011 ; "K"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b00110100 ; "4"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b00110000 ; "0"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

      ldi temp,100
      rcall delayTx1mS

      ldi temp,0b00110100 ; "4"
      out PORTD,temp
      sbi PORTB,PORTB0
      sbi PORTB,PORTB1
      rcall delay1uS
      cbi PORTB,PORTB1
      rcall delay1uS

;
; **********************************
;    P R O G R A M   L O O P
; **********************************
;
Loop:
	rjmp loop

enable_lol:
  sbi PORTB,PORTB1
  rcall delay1uS
  sbi PORTB,PORTB0
  rcall delay1uS
  ret
clear_enable:
  cbi PORTB,PORTB0
  cbi PORTB,PORTB1
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

