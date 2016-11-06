#include <msp430.h>

#define RSP r7

        .macro CALL func
        incd    RSP
        mov     r0, @RSP
        add     #8, @RSP
        br      #\func
        .endm

        .macro RET
        decd    RSP
        mov     2(RSP), r0
        .endm

;-------------------------------------------------------------------------------
; A FORTH INTERPRETER
;
        .text
;-------------------------------------------------------------------------------
MAIN:
        mov     #WDTPW|WDTHOLD, &WDTCTL
        mov.b   &CALBC1_16MHZ, &BCSCTL1
        mov.b   &CALDCO_16MHZ, &DCOCTL

        mov     #0x400, r1
        mov     #0x400, r4
        mov     #0x1FE, RSP

        mov.b   #0xFF, &P1DIR
        mov.b   #0x00, &P1OUT
        mov.b   #0xFF, &P2DIR
        mov.b   #0x00, &P2OUT
        bis.b   #BIT2|BIT1, &P1SEL
        bis.b   #BIT2|BIT1, &P1SEL2

        bis.b   #UCSSEL_2, &UCA0CTL1
        mov.b   #0x68, &UCA0BR0
        mov.b   #0x00, &UCA0BR1
        mov.b   #UCBRF_3|UCOS16, &UCA0MCTL
        bic.b   #UCSWRST, &UCA0CTL1

    .Lloop:
        mov.b   #'>', r15
        CALL    SERIAL_SEND_BLOCKING
        mov.b   #' ', r15
        CALL    SERIAL_SEND_BLOCKING
    .Linput:
        CALL    SERIAL_RECV_BLOCKING
        cmp     #'\r', r15
        jeq     .Lecho
        dec     r4
        mov.b   r15, @r4
        CALL    SERIAL_SEND_BLOCKING
        jmp     .Lend
    .Lecho:
        mov.b   #'\n', r15
        CALL    SERIAL_SEND_BLOCKING
        mov.b   #'\r', r15
        CALL    SERIAL_SEND_BLOCKING
        CALL    ECHO
        mov     r1, r4
        jmp     .Lloop
    .Lend:
        jmp     .Linput

ECHO:
        mov     r1, r5
        jmp     2f
1:      dec     r5
        mov.b   @r5, r15
        CALL    SERIAL_SEND_BLOCKING
2:      cmp     r5, r4
        jne     1b
        mov.b   #'\n', r15
        CALL    SERIAL_SEND_BLOCKING
        mov.b   #'\r', r15
        CALL    SERIAL_SEND_BLOCKING
        RET

SERIAL_RECV_BLOCKING:
        bit.b   #UCA0RXIFG, &IFG2
        jz      SERIAL_RECV_BLOCKING
        mov.b   &UCA0RXBUF, r15
        RET

SERIAL_SEND_BLOCKING:
        bit.b   #UCA0TXIFG, &IFG2
        jz      SERIAL_SEND_BLOCKING
        mov.b   r15, &UCA0TXBUF
        RET

;------------------------------------------------------------------------------
; UNEXPECTED_ISR 
;------------------------------------------------------------------------------
UNEXPECTED_ISR:
        reti

;------------------------------------------------------------------------------
; Interrupt Vectors
;------------------------------------------------------------------------------
        .section ".vectors", "ax", @progbits
        .word UNEXPECTED_ISR    ;0xffe0 
        .word UNEXPECTED_ISR    ;0xffe2 
        .word UNEXPECTED_ISR    ;0xffe4 (PORT1_VECTOR)
        .word UNEXPECTED_ISR    ;0xffe6 (PORT2_VECTOR)
        .word UNEXPECTED_ISR    ;0xffe8 
        .word UNEXPECTED_ISR    ;0xffea (ADC10_VECTOR)
        .word UNEXPECTED_ISR    ;0xffec (USCIAB0TX_VECTOR) 
        .word UNEXPECTED_ISR    ;0xffee (USCIAB0RX_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff0 (TIMER0_A1_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff2 (TIMER0_A0_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff4 (WDT_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff6 (COMPARATORA_VECTOR)
        .word UNEXPECTED_ISR    ;0xfff8 (TIMER1_A1_VECTOR)
        .word UNEXPECTED_ISR    ;0xfffa (TIMER1_A0_VECTOR)
        .word UNEXPECTED_ISR    ;0xfffc (NMI_VECTOR)
        .word MAIN              ;0xfffe (RESET_VECTOR)
        .end

