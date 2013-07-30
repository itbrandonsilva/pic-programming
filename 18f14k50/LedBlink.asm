#include <p18F14k50.inc>

    ; "WDT is controlled by SWDTEN bit of the WDTCON register."
    CONFIG WDTEN=OFF
    ; Use internal oscillator.
    CONFIG FOSC=IRC

    ; Don't know exactly why this line is necessary yet, but
    ; the code works without it; will uncomment when I know
    ; why it should be here.
    ;
    ;     org 0

    ; Define constant register symbols and initialize them.
    COUNT1 equ 0x08
    COUNT2 equ 0x09
    clrf COUNT1
    clrf COUNT2

    ; Set all PORTA pins as output. (Pins RA0, RA1, and RA3 
    ; can only be inputs; See PORTA summary in datasheet.)
    clrf PORTA
    clrf TRISA

LOOP
    ; Output high on all PORTA pins.
    setf LATA
    call Delay
    ; Output low on all PORTB pins.
    clrf LATA
    call Delay
    ; Repeat
    goto LOOP;

Delay
Loop1

    ; COUNT2 allows the delay to be long enough to be able
    ; to see the LED blinking.

    decfsz		COUNT1,1,1
    goto		Loop1
    decfsz		COUNT2,1,1
    goto		Loop1
return

end