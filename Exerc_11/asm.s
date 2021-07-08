        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
main    
        MOV R0, #12
        BL fatorial_r
        MOVS R0, #12
        BL fatorial_l
        
        MOV R0, #13
        BL fatorial_r
        MOVS R0, #13
        BL fatorial_l
        
        B       main

fatorial_l:
        ;armazena conteúdo R1
        PUSH {R1}                       
       
       ;compara se há overflow
        MOVS R1, #13
        CMP R0, R1
        BHS fatorial_l_overflow
        
        ;compara se é zero
        CBZ R0, fatorial_l_zero         
        
        ;faz o cálculo do fatorial                                
        MOV R1, R0                      
fatorial_l_loop
        SUB R1, R1, #1
        CBZ R1, fatorial_l_fim
        MULS R0, R0, R1
        B fatorial_l_loop
        
        ;designa -1 para R0 caso overflow
fatorial_l_overflow
        MVN R0, #0
        B fatorial_l_fim
        
        ;caso R0==0 R0!=1
fatorial_l_zero:
        MOVS R0, #1
        
fatorial_l_fim:
        POP {R1}
        BX LR
        
        

        ;melhor usar fatorial_l
fatorial_r:
        ;armazena R1 e LR
        PUSH {R1,LR}
        
        ;compara se overflow
        MOV R1, #13
        CMP R0, R1
        BLO fatorial_r_c0
        MVN R0, #0
        B fatorial_r_fim
        
        ;chama a sub-rotina recursiva
fatorial_r_c0
        MOV R1, R0
        BL fatorial_r_aux
        
fatorial_r_fim
        POP {R1,PC}
        
fatorial_r_aux:

        PUSH {LR}
        
        ;se zero retorna 1
        CBZ R1, fatorial_r_aux_zero
        
        ;armazena R1 para ser usado quando retornar
        PUSH {R1}
        SUB R1, R1, #1
        BL fatorial_r_aux
        
        POP {R1}
        MUL R0, R0, R1
        B fatorial_r_aux_fim
        
fatorial_r_aux_zero:
        MOVS R0, #1
        
fatorial_r_aux_fim:
        POP {PC}
        
        
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
