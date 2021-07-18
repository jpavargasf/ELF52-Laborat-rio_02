/*---------------------------------------------------
Autor:          João Paulo Vargas da Fonseca
Disciplina:     ELF52 - Sistemas Microcontrolados
Arquivo:        Exercício 18

Detalhes:        Placa TM4C129E
                
                  LEDS 
                     D1 = PN1           MSB
                     D2 = PN0
                     D3 = PF4
                     D4 = PF0           LSB       
                  
                  Switches      
                     SW1 = PJ0
                     SW2 = PJ1
         
 Comentários:   Estruturei esse programa com base no projeto
                gpio2-int, pois fica mais fácil tanto de
                entender como debugar. Pois no 17, certos 
                registradores após carregados uma vez eram
                tidos como constantes. No 18, eles são 
                carregados e destruídos em cada sub-rotina
                
                O número somente atualiza após o soltar do 
                botão ou então ao pressionamento do outro
                botão.
-----------------------------------------------------*/
        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
;endereço base das portas
GPIO_PORT_N          	EQU     0x40064000
GPIO_PORT_F             EQU     0x4005D000
GPIO_PORT_J             EQU     0x40060000
;endereço de offset
GPIO_DIR_R     	        EQU     0x400
GPIO_DEN_R           	EQU     0x51C
GPIO_DATA_R             EQU     0x3FC
GPIO_PUR_R              EQU     0x510           ;pull up resistor
;bits usados em I/O
GPIO_PORT_J_I           EQU     11b
GPIO_PORT_N_O           EQU     11b
GPIO_PORT_F_O           EQU     10001b
;bits de habilitação das portas GPIO
GPIO_PORT_J_B           EQU     000000100000000b;8
GPIO_PORT_N_B           EQU     001000000000000b;12
GPIO_PORT_F_B           EQU     000000000100000b;5
;cte de debounce
CTE_DEBOUNCE            EQU     0xA2C2          ;41666 --> para 10ms
                              
__iar_program_start



main
        BL GPIO_config                  ;configura os PORTS N, F e J

operation
        MOVS R0, #0                     ;contador
operation_loop
        BL LED_output                   ;escreve R0 nos leds
        BL SW_input                     ;espera o pressionamento de botão
        CMP R1, #1                      ;prioridade ao SW1
        ITE EQ
          ADDEQ R0, #1                  ;SW1
          SUBNE R0, #1                  ;SW2
        B operation_loop

;escreve nos leds os 4 LSBs de R0 - abcd
LED_output
        ;LED D1 E D2                    ;abxx
        LDR R1, =GPIO_PORT_N            ;0x40064000
        MOV R2, R0, LSR #2              ;abxx-->ab
        AND R2, #GPIO_PORT_N_O          ;ab AND 11
        STR R2, [R1, #GPIO_DATA_R]      ;0x400643FC
        
        ;LED D3 E D4                    ;xxcd
        LDR R1, =GPIO_PORT_F            ;0x4005D000
        AND R2, R0, #11b                ;cd
        AND R3, R2, #GPIO_PORT_F_O      ;d AND 1
        LSL R2, #3                      
        AND R2, #GPIO_PORT_F_O          ;c AND 1
        ORR R2, R3
        STR R2, [R1, #GPIO_DATA_R]      ;0x4005D3FC
        
        BX LR

;Espera algum botão ser apertado e retorna o valor em R1
SW_input
        LDR R2, =GPIO_PORT_J            ;0x40060000
SW_input_debounce
        MOV R3, #CTE_DEBOUNCE           ;restarta temporizador = 41666
        ;temporizador do debounce é 41666 * 6 * 25M = 10 ms
        ; (constante)*(número de instruções)*(clock) = 10 ms
SW_input_debounce_timer
        LDR R1, [R2, #GPIO_DATA_R]      ;lê entrada (ativa em 0)
        EORS R1, #GPIO_PORT_J_I         ;se 0x = 1x ou x0 = x1 ou 00 = 11
        BEQ SW_input_debounce           ;se Z = 1 (nenhuma entrada) restarta temporizador
        SUBS R3, R3, #1                 ;conta tempo
        BEQ SW_input_wait_change        ;se passou 10ms entrada aceita
        B SW_input_debounce_timer
      
        ;espera alterar o sinal de entrada
        ;isso permite que pressionamentos acima de 10 ms contem como somente um
        ;espera ser depressionado ou pressionado outro botão
SW_input_wait_change
        LDR R4, [R2, #GPIO_DATA_R]
        EOR R4, #GPIO_PORT_J_I
        CMP R4, R1
        BNE SW_input_ACK
        B SW_input_wait_change
        
SW_input_ACK
        BX LR

GPIO_config
        PUSH {LR}                       
      
        MOV R0, #GPIO_PORT_J_B          ;000000100000000b
        ORR R0, #GPIO_PORT_N_B          ;001000100000000b
        ORR R0, #GPIO_PORT_F_B          ;001000100100000b
        BL GPIO_enable                  ;habilita clocks em J N e F
        
        MOV R1, #GPIO_PORT_N_O          ;11b
        LDR R0, =GPIO_PORT_N            ;0x40064000
        BL GPIO_output                  ;configura saída de N
        
        LDR R0, =GPIO_PORT_F            ;0x4005D000
        MOV R1, #GPIO_PORT_F_O          ;10001b
        BL GPIO_output                  ;configura saída de F
        
        LDR R0, =GPIO_PORT_J            ;0x40060000
        MOV R1, #GPIO_PORT_J_I          ;11b
        BL GPIO_input                   ;configura entrada de J
        
        POP {PC}

        ;habilita o clock nos ports especificados em R0
GPIO_enable        
        LDR R1, =SYSCTL_RCGCGPIO_R
        LDR R2, [R1]
        ORR R2, R0
        STR R2, [R1]
        ;verifica se está habilitado
        LDR R1, =SYSCTL_PRGPIO_R
GPIO_enable_wait
        LDR R0, [R1]
        CMP R0, R2
        BNE GPIO_enable_wait
        
        BX LR
        ;configura bits R1 da GPIO com endereço R0 como saída
GPIO_output
        ;habilita sinal de entrada
        LDR R2, [R0, #GPIO_DIR_R]
        ORR R2, R1
        STR R2, [R0, #GPIO_DIR_R]
        ;habilita sinal digital
        LDR R2, [R0, #GPIO_DEN_R]
        ORR R2, R1
        STR R2, [R0, #GPIO_DEN_R]
        
        BX LR

GPIO_input
        ;habilita sinal de saída
        LDR R2, [R0, #GPIO_DIR_R]
        BIC R2, R1                       ;BIT CLEAR                              
        STR R2, [R0, #GPIO_DIR_R]
        ;habilita sinal digital
        LDR R2, [R0, #GPIO_DEN_R]
        ORR R2, R1
        STR R2, [R0, #GPIO_DEN_R]
        ;configura pull-up resistor
        LDR R2, [R0, #GPIO_PUR_R]
        ORR R2, R1
        STR R2, [R0, #GPIO_PUR_R]
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
