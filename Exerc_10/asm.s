        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
main    
        MOV R0, #0xFFFF
        MOV R1, #0xFFFF
        BL Mul16b
        MUL R0,R1
        B       main
        
Mul16b: PUSH {R3,R4,LR}         ;caso haja algo em R3 e R4
        MOVS R2, #0
        MOV R3, R1              ;R1 permanece inalterado
        BL aux   
        RRX R2, R2              ;divide R2 por 2
        POP {R3,R4,PC}          ;recupera valores de R3 e R4
;aux é recursiva  
aux:
        PUSH {LR}
        CBZ R3, aux_fim
        MOVS R4,#0
aux_loop:                       ;aux_loop conta quantas divisões +1 pode fazer por 2
        LSRS R3, R3, #1
        ADD R4, R4, #1
        BHS  aux_plus
        B aux_loop
aux_plus:
        PUSH {R4}
        BL aux
        POP {R4}
        ADD R2, R2, R0
        LSLS R2, R2, R4
aux_fim:
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
