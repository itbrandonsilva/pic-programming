; Servo used in this sample: HS-322HD

#include <p16F887.inc>

    __config _CONFIG1, _LVP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTOSCIO
    ; Set CONFIG2 defaults to squelch programmer warning
    __config _CONFIG2, _WRT_OFF & _BOR21V

    cblock 0x20
        HIGHH
        HIGHL
        LOWH
        LOWL
    endc

    ; Analog output is not needed for this application.
    banksel ANSEL
    clrf ANSEL
    clrf ANSELH

    ; All PORTA pins will be used for output.
    banksel TRISA
    clrf TRISA
    movlw b'11111111'
    movwf TRISB

    ; Enables pull-up resistors allowing PORTB bits to be toggled with switches.
    banksel OPTION_REG
    bcf OPTION_REG,7
    banksel WPUB
    movlw b'00000111'
    movwf WPUB

    ; Output high on RA0 for power LED. (for fun)
    banksel PORTA
    movlw b'00000001'
    movwf PORTA

    ; "Compare mode, trigger special event (CCP1IF bit is set; CCP1 resets TMR1 or TMR2"
    banksel CCP1CON
    movlw b'00001011'
    movwf CCP1CON

    ; Initialize CCP1 compare interrupt by clearing the bit. (Not sure if this is required, but I like it.)
    banksel PIR1
    bcf PIR1,CCP1IF

    ; Enable CCP1 compare interrupt.
    banksel PIE1
    bsf PIE1,CCP1IE

    banksel INTCON
    ; Uncommenting this line results in a stack overflow. Don't know why yet.
    ; bsf INTCON,GIE
    bsf INTCON,PEIE

    ; Initialize CCPR1 to trigger the first interrupt.
    banksel PORTA
    call SNEUT

    ; Start TMR1
    movlw b'00000001'
    movwf T1CON

MAIN
    btfss PORTB,RA0
    call SLEFT
    btfss PORTB,RA1
    call SNEUT
    btfss PORTB,RA2
    call SRIGHT

    ; CCP1IF is set when CCPR1 is equal to TMR1.
    ; When CCP1IF is set, TMR1 is reset back to 0,
    ; as configured in CCP1CON.
    ; CCPR1 is toggled between (HIGHH/HIGHL) and
    ; (LOWH/LOWL) each time SERVO is called
    ; to update the pulse width timing. SERVO
    ; will clear CCP1IF so we can listen for the
    ; the next interrupt.

    btfsc PIR1,CCP1IF
    call SERVO
    goto MAIN


; Timing explanation:
; Tcy = Time it takes to complete one clock cycle.
; We are using a 4Mhz internal oscillator.
; Tcy = [1000000us/4,000,000hz]*4 = 1us
; Our servo will operate at 50hz (20ms)
; Our servo will rotate the furthest counter-clockwise
; when the duty cycle is 600us.
; Therefore the low duty cycle would then be 19400us to
; enforce a 50hz frequency (20ms pulses).
; 20ms = 20000us
; 19400us + 600us = 20000us = 20ms

; Servo counter-clockwise - 600us duty cycle
; High 0x0258 (600us)
; Low  0x4BC8 (19400us)

; Servo Neutral - 1500us duty cycle
; High 0x05DC (1500us)
; Low  0x4844 (18500us)

; Servo clockwise - 2400us duty cycle
; High 0x0960 (2400us)
; Low  0x44C0 (17600us)

SLEFT
    movlw 0x02
    movwf HIGHH
    movlw 0x58
    movwf HIGHL

    movlw 0x4B
    movwf LOWH
    movlw 0xC8
    movwf LOWL
    return

SNEUT
    movlw 0x05
    movwf HIGHH
    movlw 0xDC
    movwf HIGHL

    movlw 0x48
    movwf LOWH
    movlw 0x44
    movwf LOWL
    return

SRIGHT
    movlw 0x09
    movwf HIGHH
    movlw 0x60
    movwf HIGHL

    movlw 0x44
    movwf LOWH
    movlw 0xC0
    movwf LOWL
    return

SERVOHIGH
    movf HIGHH,0
    movwf CCPR1H
    movf HIGHL,0
    movwf CCPR1L
    return

SERVOLOW
    movf LOWH,0
    movwf CCPR1H
    movf LOWL,0
    movwf CCPR1L
    return

SERVO
    movlw B'00100000'    ; Toggle RA5 output bit.
    xorwf PORTA,1

    btfsc PORTA,RA5    ; If RA5 output is now high
    call SERVOHIGH
    btfss PORTA,RA5    ; If RA5 output is now low
    call SERVOLOW

    bcf PIR1,CCP1IF    ; Clear the interrupt bit so we can be ready for the next interrupt.
    return

    end
