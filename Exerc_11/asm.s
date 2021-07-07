        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
main    
       ; MOV R0, #0xABCD
        ;BL fatorial_r
        MOVS R0, #0xAB
        BL fatorial_l
        B       main

fatorial_l:
        PUSH {R1,R2,LR}
        MOV R1, R0
        CBZ R0, fatorial_l_zero
fatorial_l_loop
        SUB R1, R1, #1
        CBZ R1, fatorial_l_fim
        MOV R2, R0
        MUL R0, R0, R1
        CMP R0, R2
        BMI fatorial_l_overflow
        B fatorial_l_loop
fatorial_l_overflow
        MVN R0, #0
        B fatorial_l_fim
fatorial_l_zero:
        MOVS R0, #1
fatorial_l_fim:
        POP {R1,R2,PC}
        ;dependendo do tamanho de R0, fatorial_r causa stack overflow
        ;melhor usar fatorial_l
fatorial_r:                             
        PUSH {R1,LR}
        MOV R1, R0
        BL fatorial_r_aux
        POP {R1,PC}
        
fatorial_r_aux:
        PUSH {LR}
        CBZ R1, fatorial_r_aux_zero
        PUSH {R1}
        SUB R1, R1, #1
        BL fatorial_r_aux
        POP {R1}
        MULS R0, R0, R1
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
