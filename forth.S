#include <msp430.h>

;-------------------------------------------------------------------------------
; REGISTER DEFINITIONS
;-------------------------------------------------------------------------------

#define PC  r0 // program counter
#define RSP r1 // return stack pointer
#define SR  r2 // status register
#define CG  r3 // constant generator
#define PSP r4 // parameter stack pointer
#define IP  r5 // instruction pointer
#define W   r6 // work register
#define TOS r7 // top-of-stack in register
#define INP r8 // input buffer pointer
#define X   r9 // scratch register X

#define RSP_START 0x400
#define PSP_START 0x1FE
#define INP_START 0x37D

;-------------------------------------------------------------------------------
; ASSEMBLER MACROS
;-------------------------------------------------------------------------------

        .macro NEXT
        mov     @IP+, W
        mov     W, PC
        .endm

        .macro PUSHPSP reg
        incd    PSP
        mov     \reg, @PSP
        .endm

        .macro POPPSP reg
        mov     @PSP, \reg
        decd    PSP
        .endm

        .macro PUSHINP reg
        dec     INP
        mov.b   \reg, @INP
        .endm

;-------------------------------------------------------------------------------
; A FORTH INTERPRETER
;
        .text
;-------------------------------------------------------------------------------
MAIN:
        ; disable watchdog and run at 16Mhz
        mov     #WDTPW|WDTHOLD, &WDTCTL
        mov.b   &CALBC1_16MHZ, &BCSCTL1
        mov.b   &CALDCO_16MHZ, &DCOCTL

        ; initialize stack pointer
        mov     #RSP_START, RSP
        mov     #PSP_START, PSP
        mov     #INP_START, INP

        ; all port pins off
        mov.b   #0xFF, &P1DIR
        mov.b   #0x00, &P1OUT
        mov.b   #0xFF, &P2DIR
        mov.b   #0x00, &P2OUT

        ; P1.1 & P1.2 as UART mode
        bis.b   #BIT2|BIT1, &P1SEL
        bis.b   #BIT2|BIT1, &P1SEL2

        ; initialize UART module
        bis.b   #UCSSEL_2, &UCA0CTL1
        mov.b   #0x68, &UCA0BR0
        mov.b   #0x00, &UCA0BR1
        mov.b   #UCBRF_3|UCOS16, &UCA0MCTL
        bic.b   #UCSWRST, &UCA0CTL1

PROMPT:
        mov.b   #'>', r15
        call    #SERIAL_SEND_BLOCKING
        mov.b   #' ', r15
        call    #SERIAL_SEND_BLOCKING
1:      call    #SERIAL_RECV_BLOCKING
        cmp     #'\r', r15
        jeq     2f
        PUSHINP r15
        call    #SERIAL_SEND_BLOCKING
        jmp     1b
2:      mov.b   #'\n', r15
        call    #SERIAL_SEND_BLOCKING
        mov.b   #'\r', r15
        call    #SERIAL_SEND_BLOCKING
        call    #ECHO
        mov     #INP_START, INP
        jmp     PROMPT

ECHO:
        mov     #INP_START, X
        jmp     2f
1:      dec     X
        mov.b   @X, r15
        call    #SERIAL_SEND_BLOCKING
2:      cmp     X, INP
        jne     1b
        mov.b   #'\n', r15
        call    #SERIAL_SEND_BLOCKING
        mov.b   #'\r', r15
        call    #SERIAL_SEND_BLOCKING
        ret

SERIAL_RECV_BLOCKING:
        bit.b   #UCA0RXIFG, &IFG2
        jz      SERIAL_RECV_BLOCKING
        mov.b   &UCA0RXBUF, r15
        ret

SERIAL_SEND_BLOCKING:
        bit.b   #UCA0TXIFG, &IFG2
        jz      SERIAL_SEND_BLOCKING
        mov.b   r15, &UCA0TXBUF
        ret

;------------------------------------------------------------------------------
; UNEXPECTED INTERRUPT SERVICE ROUTINE
;------------------------------------------------------------------------------
UNEXPECTED_ISR:
        reti

;------------------------------------------------------------------------------
; INTERRUPT VECTORS
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

