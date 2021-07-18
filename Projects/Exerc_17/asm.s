/*---------------------------------------------------
Autor:          João Paulo Vargas da Fonseca
Disciplina:     ELF52 - Sistemas Microcontrolados
Arquivo:        Exercício 17

Detalhes:        Placa TM4C129E
                
                  LEDS 
                     D1 = PN1           MSB
                     D2 = PN0
                     D3 = PF4
                     D4 = PF0           LSB           
-----------------------------------------------------*/
        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
PORTNF_BIT              EQU     1000000100000b ; bit 12 = Port N, bit 5 = Port F 

GPIO_PORTN          	EQU     0x40064000
GPIO_PORTF              EQU     0x4005D000
GPIO_DIR_R     	        EQU     0x400
GPIO_DEN_R           	EQU     0x51C
GPIO_DATA_R             EQU     0x3FC

PORTF_BITS              EQU     10001b
PORTN_BITS              EQU     11b
                              
__iar_program_start



main   
        BL inicializacao
        BL configuracao
        BL operacao
        B       main

inicializacao
        ;Habilita Clocks portas N e F
        MOV R1, #PORTNF_BIT
        LDR R2, =SYSCTL_RCGCGPIO_R
        LDR R0, [R2]
        ORR R0, R1
        STR R0, [R2]
        
        ;Habilita portas N e F
        LDR R2, =SYSCTL_PRGPIO_R
wait    LDR R1, [R2]
        TEQ R1, R0
        BNE wait
        BX LR

configuracao
        PUSH {LR}                       ;Necessário pois chama outras sub-rotinas

        LDR R0, =GPIO_PORTN             ;Endereço Porta N
        LDR R1, =GPIO_PORTF             ;Endereço Porta F
        MOV R2, #PORTN_BITS             ;Configuração dos bits da Porta N
        MOV R3, #PORTF_BITS             ;Configuração dos bits da Porta F
        
        MOV R4, #GPIO_DIR_R             ;Define saídas
        
        BL config_RW
        
        MOV R4, #GPIO_DEN_R             ;Habilita digital
        
        BL config_RW
        
        POP {PC}

        ;R4 é o offset
config_RW
        ;Porta N
        //ADD R5, R0, R4                  ;R5:=0x40064000   +    R4
        LDR R6, [R0, R4]                    ;Lê estado anterior
        ORR R6, R2                      ;Bit de saída 11b
        STR R6, [R0, R4]                    ;Armazena novo estado
           
        ;Porta F
        //ADD R5, R1, R4                  ;R5:=0x4005D000   +    R4
        LDR R6, [R1, R4]                    ;Lê estado anterior
        ORR R6, R3                      ;Bit de saída 10001b
        STR R6, [R1, R4]                    ;Armazena novo estado

        BX LR

operacao
        PUSH {LR}
        //ADD R0, #GPIO_DATA_R            ;R0:= 0x400643FC
        //ADD R1, #GPIO_DATA_R            ;R1:= 0x4005D3FC
        
        MOVS R4, #0                     ;Contador
operacao_loop

        CMP R4, #10000b                 
        IT EQ                           ;Se R4==16
          ANDEQ R4, R4, #0              ;R4:=0
          
        ;Porta N
        ;Leds mais significativos       11xx
        ;R2=11b
        MOV R5, R4, LSR #2              ;11xx -> 0011
        AND R5, R5, R2                  ;Se há 11xx
        STR R5, [R0, #GPIO_DATA_R]                    ;aplica estado
        
        ;Porta F
        ;Leds menos significativos      xx11
        ;R3=10001b
        AND R5, R3, R4                  ;Se há xxx1
        MOV R6, R4, LSL #3              ;Move xx1x ->xx1x000
        AND R6, R6, R3                  ;Se há xx1x
        ORR R5, R6                      ;xx11
        STR R5, [R1, #GPIO_DATA_R]                    ;aplica estado
        
        BL delay
        
        ADD R4, R4, #1
        B operacao_loop
        POP {PC}
 
delay                                           
        MOVT R5, #0x020
delay_loop
        CBZ R5, delay_fim
        SUB R5, R5, #1
        B delay_loop
delay_fim
        BX LR

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
