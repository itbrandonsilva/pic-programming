; Tested on a LCM-S01602DTR/M module, which seems
; to have an HD44780 onboard.

#include <p16F887.inc>

    __config _CONFIG1, _LVP_OFF & _MCLRE_OFF & _PWRTE_ON & _INTOSCIO
	; Set CONFIG2 defaults to squelch programmer warning
    __config _CONFIG2, _WRT_OFF & _BOR40V
    

    cblock 0x20
        REPEAT
        DELAYCOUNT
        STARTED
    endC

    ;org 0x00
    call CONFIG_PORTS
    call CONFIG_LCD
    call DISPLAY_OFF

MAIN
    call CHECK_KEYS
    goto MAIN

CONFIG_PORTS
    banksel TRISA
    clrf TRISA
    movlw B'11111111'
    movwf TRISB
    clrf TRISC

    ; Enables pull-up resistors allowing PORTB bits to be toggled with switches.
    banksel OPTION_REG
    bcf OPTION_REG,7
    banksel WPUB
    movlw b'11111111'
    movwf WPUB

    banksel ANSEL
    clrf ANSEL
    clrf ANSELH

    banksel PORTA
    return

CONFIG_LCD
    bsf PORTA,RA0    ; Initialize high on LCD clock input.
    movlw b'00110000'    ; Ensure we are using the 8bit interface
    call LCD_INS
    movlw b'00001100'    ; Turns on the display
    call LCD_INS
    return

CHECK_KEYS
    call KEY
    return

KEY
    btfsc PORTB,RB0
    return
    call DISPLAY_ON
KEYWAIT
    btfss PORTB,RB0
    goto KEYWAIT
    call DISPLAY_OFF
    return

DISPLAY_CLEAR
    movlw 0x01
    call LCD_INS
    return

C_SPACE
    movlw b'00100000'
    call LCD_DAT
    return

C_O
    movlw b'01001111'
    call LCD_DAT
    return

C_F
    movlw b'01000110'
    call LCD_DAT
    return

C_N
    movlw b'01001110'
    call LCD_DAT
    return

C_EP
    movlw b'00100001'
    call LCD_DAT
    return

DISPLAY_OFF
    call DISPLAY_CLEAR
    call C_SPACE
    call C_SPACE
    call C_SPACE
    call C_SPACE
    call C_O
    call C_F
    call C_F
    call C_EP
    return

DISPLAY_ON
    call DISPLAY_CLEAR
    call C_SPACE
    call C_SPACE
    call C_SPACE
    call C_SPACE
    call C_O
    call C_N
    call C_EP
    return

LCD_INS    ; Sends instruction from W to LCD
    bcf PORTA,RA1    ; We are sending an instruction.
    bcf PORTA,RA2    ; We are writing data (0=write,1=read)
    movwf PORTC
    call TOGGLE    ; Trigger clock falling edge; tell the LCD to get it's instructions/data. 
    return

LCD_DAT    ; Sends data from W to LCD
    bsf PORTA,RA1    ; We are sending data
    bcf PORTA,RA2
    movwf PORTC
    call TOGGLE   
    return

; The HD44780 LCD is a device that runs on a clock.
; It uses this clock in order to know when to execute instructions that it is given.
; It is a falling edge-triggered clock, which means it executes new instructions on the falling edge of the clock signal.
TOGGLE
    bcf PORTA,RA0
    call DELAY    ; Give the LCD some time to complete it's work
    bsf PORTA,RA0
    return

; Tcy = Time it takes to complete one clock cycle.
; We are using a 4Mhz internal oscillator.
; Tcy = [1,000,000us/4,000,000hz]*4 = 1us
; 50 calls per loop * 80 loops = 
; approximately 4000 clock cycles (including
; decfsz and other operations).
; Tcy(1us) * 4000 clock cycles = 4000us = 4ms.
; This delay function delays for approximately 4ms.
; There isn't a specific reason for using a 4ms
; delay when toggling RA0 besides giving the LCD
; plenty of time to complete it's operations. 
; If you want to provide a more precise clock source 
; to the LCD, consult the relevant datasheets.

DELAY
    movlw b'00001111' ; 50 decrements
    movwf REPEAT
REPEAT_LOOP       
    movlw b'00110010' ; 80 repeats
    movwf DELAYCOUNT
LOOP  
    decfsz DELAYCOUNT 
    goto LOOP        
    decfsz REPEAT
    goto REPEAT_LOOP
    return

end
