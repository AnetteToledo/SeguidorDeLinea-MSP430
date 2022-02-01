;-------------------------------------------------------------------------------
; 28/06/2021
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; LENGUAJES DE INTERFAZ - S6A
; @Anette Toledo
; Equipo #4: Itzel Galdamez, Selene Rosales, Ingrid Sarmiento, Guadalupe Torres
;
; *****************ROBOT SEGUIDOR DE LINEA - MSP430G2553************************
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

MAIN
											;1110 0111
		bis.b   #00E7h,&P1DIR;// definir P1.4 y P1.3 como entrada de los sensores, el resto salida
		bis.b   #0040h,&P1SEL; //definir P1.6(0100 000) como temporizador (PWM)
		mov.b   #00ffh,&P2DIR; // 1111 1111 - P2DIR

		;TACCR0 = period-1;  //Período de PWM
		mov.w   #0fffh,R12 ;R12=periodo - 0fffh=4095hz(F max)
		dec.w   R12
		mov.w   R12,&TA0CCR0 ;//Timer_0

		;TACCR1 = period*D;  //CCR1 PWM ciclo de trabajo(duty cycle)
		mov.w   #599Ah,&TA0CCR1 ;#599Ah=22938hz
		mov.w   &TA0CCR1,R12

		;TACCTL1 = OUTMOD_7;  //Reset-set de selección CCR1
		;Configuramos la salida en modo Reset/Set
        ;la salida se pone a 0 cuando la cuenta llegue al valor de TACCR1(duty cycle)
        ;y se pone a 1 cuando la cuenta llega al valor TACCR0 (periodo)
		mov.w   #00E0h,&TA0CCTL1
        ;TACTL = TASSEL_2|MC_1;   //Reloj secundario SMCLK, upmode
        ;Elegimos como fuente de reloj SMCLK(TASSEL_2) que nos da una frecuencia de 1MHz
        ;y que cuente en modo ascendente. ACLK -> TASSEL_1. CAP=0, estamos en modo comparación.
        mov.w   #0210h,&TA0CTL

        ;while(1)/while(true) -  superloop
WHILE
		;el sensor envía alto voltaje en una superficie oscura
		mov.b   &P1IN,R15
		and.b   #0018h,R15

		;ejemplo R15=sensorout

		cmp #0018h,R15;if (sensorout == 0x18) // si sensorout==0018h
        jz 	straight;//salta si es cero ->straight

        cmp #0008h,R15; // si sensorout==0008h
        jz    turnright; //salta si es cero -> turnright

        cmp #0010h,R15;// si sensorout==0010h
        jz    turnleft; //salta si es cero -> turnleft

        cmp #0000h,R15;// si sensorout==0000h
        jz    stop; //salta si es cero -> stop

		jmp WHILE ;// salta a la etiqueta WHILE

;-------------------------------------------------------------------------------
; FUNCIONES
;-------------------------------------------------------------------------------
straight: ;RECTO
        mov.w   #0000h, &P2OUT ;Poner 0 a P2OUT
        mov.w   &P2OUT, R12 ; P2OUT -> R12
        bis.w   #0024h, R12; 0010 0100 ->giran ambos motores
        mov.w   R12, &P2OUT; R12 ->P2OUT
        jmp WHILE ; Salto a WHILE
        ret

turnright: ;DERECHA
        mov.w    #0000h, &P2OUT ;Poner 0 a P2OUT
        mov.w    &P2OUT, R12 ; P2OUT -> R12
        bis.w    #0020h, R12 ;0010 0000 ->gira motor izquierdo
        mov.w    R12, &P2OUT ; R12 ->P2OUT
        jmp WHILE ; Salto a WHILE
       ret

turnleft: ;IZQUIERDA
        mov.w    #0000h, &P2OUT ;Poner 0 a P2OUT
        mov.w    &P2OUT, R12 ; P2OUT -> R12
        bis.w    #0004h, R12 ;0000 0100 ->gira motor derecho
        mov.w    R12, &P2OUT ; R12 ->P2OUT
        jmp WHILE ; Salto a WHILE
        ret

stop: ;DETENERSE
        mov.w    #0000h, &P2OUT ;Poner 0 a P2OUT ->Se detiene
        mov.w    &P2OUT, R12 ; P2OUT -> R12
        mov.w    R12, &P2OUT ; R12 ->P2OUT
     	jmp WHILE ; Salto a WHILE
     	ret


;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------

            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
