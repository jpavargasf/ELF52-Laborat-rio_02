;--|Autor: João Paulo Vargas da Fonseca
;--|RA:2024268
;--|Data:21/08/2021
;--|Trabalho desenvolvido para a disciplina de Sistemas Microcontrolados, para o 
;--|curso de Engenharia Eletrônica da Universidade Tecnológica Federal do 
;--|Paraná
;--|
;--|Arquivo: Calculadora para operação com inteiros
;--|
;--|Comentários:-Todas as subrotinas foram projetadas de modo a seguir o padrão                
;--|             AAPCS para subrotinas.
;--|            -Algumas subrotinas (as de configuração de ports GPIO e UART) 
;--|             são as mesmas disponíveis no arquivo TM4C129E_SM_IAR9  
;--|            -Divisões por zero resultam no código NaN(Not a Number)
;--|            -Este projeto está configurado para rodar no kit TM4C129E        
;--|
;-------------------------------------------------------------------------------
        PUBLIC  __iar_program_start
        EXTERN  __vector_table
       ; PUBLIC  __iar_data_init3
        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        ;REQUIRE __iar_data_init3
        
        THUMB

; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608
SYSCTL_PRGPIO		EQU     0x0A08
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
PORTA_BIT               EQU     000000000000001b ; bit  0 = Port A
PORTF_BIT               EQU     000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     001000000000000b ; bit 12 = Port N
UART0_BIT               EQU     00000001b        ; bit  0 = UART 0

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400
GPIO_IS                 EQU     0x0404
GPIO_IBE                EQU     0x0408
GPIO_IEV                EQU     0x040C
GPIO_IM                 EQU     0x0410
GPIO_RIS                EQU     0x0414
GPIO_MIS                EQU     0x0418
GPIO_ICR                EQU     0x041C
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_PCTL               EQU     0x052C

; UART definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8
;UART bit definitions
TXFE_BIT                EQU     10000000b ; TX FIFO full
RXFF_BIT                EQU     01000000b ; RX FIFO empty
BUSY_BIT                EQU     00001000b ; Busy


; PROGRAMA PRINCIPAL

__iar_program_start
        
main
;-------------------Configuração inicial de GPIO e UART-------------------------
        MOV R2, #(UART0_BIT)
	BL UART_enable ; habilita clock ao port 0 de UART

        MOV R2, #(PORTA_BIT)
	BL GPIO_enable ; habilita clock ao port A de GPIO
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b ; bits 0 e 1 como especiais
        BL GPIO_special

	MOV R1, #0xFF ; máscara das funções especiais no port A (bits 1 e 0)
        MOV R2, #0x11  ; funções especiais RX e TX no port A (UART)
        BL GPIO_select

	LDR R0, =UART_PORT0_BASE
        BL UART_config ; configura periférico UART0
        
        
;----------------------------Programa principal---------------------------------
loop   
        BL calculator           ;responsável por receber números, operadores e realizar operação
        B loop


; SUB-ROTINAS

;----------
; UART_enable: habilita clock para as UARTs selecionadas em R2
; R2 = padrão de bits de habilitação das UARTs
; Destrói: R0 e R1
UART_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCUART]
	ORR R1, R2 ; habilita UARTs selecionados
	STR R1, [R0, #SYSCTL_RCGCUART]

waitu	LDR R1, [R0, #SYSCTL_PRUART]
	TEQ R1, R2 ; clock das UARTs habilitados?
	BNE waitu

        BX LR
        
; UART_config: configura a UART desejada
; R0 = endereço base da UART desejada
; Destrói: R1
UART_config:
        LDR R1, [R0, #UART_CTL]
        BIC R1, #0x01 ; desabilita UART (bit UARTEN = 0)
        STR R1, [R0, #UART_CTL]

        ; clock = 16MHz, baud rate = 9600 bps
        MOV R1, #104
        STR R1, [R0, #UART_IBRD]
        MOV R1, #11
        STR R1, [R0, #UART_FBRD]
        
        ; 8 bits, 1 stop, odd parity, FIFOs disabled, no interrupts
        MOV R1, #01100010b
        STR R1, [R0, #UART_LCRH]
        
        ; clock source = system clock
        MOV R1, #0x00
        STR R1, [R0, #UART_CC]
        
        LDR R1, [R0, #UART_CTL]
        ORR R1, #0x01 ; habilita UART (bit UARTEN = 1)
        STR R1, [R0, #UART_CTL]

        BX LR


; GPIO_special: habilita funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como funções especiais
; Destrói: R2
GPIO_special:
	LDR R2, [R0, #GPIO_AFSEL]
	ORR R2, R1 ; configura bits especiais
	STR R2, [R0, #GPIO_AFSEL]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_select: seleciona funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem alterados
; R2 = padrão de bits (1) a serem selecionados como funções especiais
; Destrói: R3
GPIO_select:
	LDR R3, [R0, #GPIO_PCTL]
        BIC R3, R1
	ORR R3, R2 ; seleciona bits especiais
	STR R3, [R0, #GPIO_PCTL]

        BX LR
;----------

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R2
; R2 = padrão de bits de habilitação dos ports
; Destrói: R0 e R1
GPIO_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCGPIO]
	ORR R1, R2 ; habilita ports selecionados
	STR R1, [R0, #SYSCTL_RCGCGPIO]

waitg	LDR R0, [R0, #SYSCTL_PRGPIO]
	TEQ R0, R1 ; clock dos ports habilitados?
	BNE waitg

        BX LR
;----------------Início das subrotinas escritas pelo Autor----------------------
;-------------------------------calculator--------------------------------------
;calculator recebe os dois operandos, operadores e realiza a operação
;R0 = endereço da UART
;Destrói: R1, R2, R3
calculator
        PUSH {LR}
        PUSH {R0}
        MOV R1, #0              ;indica que é o primeiro operando e operação
        BL receiveFirstOp       ;R0 = primeiro operando e R1 = operação
        PUSH {R0, R1}           
        LDR R0, [SP, #8]        ;endereço UART
        MOV R1, #1              ;segundo operando    
        BL receiveFirstOp       ;R0 = segundo operando e R1 = sinal de igualdade
        POP {R1, R2}            ;operando 1 e operação
        BL operation            ;R0 = resultado, R1 = código de erro
        
        ;adequa registradores para serem passados para subrotinas
        MOV R2, R1
        MOV R1, R0
        POP {R0}
        ;R0 = UART_BASE, R1 = resultado, R2 = código

        ;compara o código resultado da operação
        CMP R2, #-1
        BGT calculator_ok       ;resultado positivo
        BEQ calculator_NaN      ;divisão por zero

        ;resultado negativo
        ;escrever '-'
        PUSH {R1}
        MOV R1, #45             ;'-'
        BL send_char
        POP {R1}                ;reculpera resultado
        B calculator_ok
        
calculator_NaN                  ;send NaN
        MOV R2, #3              ;tamanho de NaN
        MOV R3, #1              ;modo de escrita
        LDR R1, =NaN            ;endereço base
        BL send_string
        B calculator_end
        
calculator_ok
        BL send_number
        
calculator_end
        ;send CRLF
        MOV R2, #2
        MOV R3, #1
        LDR R1, =CRLF
        BL send_string
        
        POP {PC}
/*
;---------------------------------send_CRLF-------------------------------------
;R0 = base UART
send_CRLF
        PUSH {LR}
        MOV R2, #2
        MOV R3, #1
        LDR R1, =CRLF
        BL send_string
        POP {PC}
        
;---------------------------------send_NaN--------------------------------------
;R0 = base UART
send_NaN
        PUSH {LR}
        MOV R2, #3
        MOV R3, #1
        LDR R1, =NaN
        BL send_string
        POP {PC}
*/
;-------------------------------send_Number-------------------------------------
;send_number envia um número decimal para o endereço de UART
;R0 = endereço UART
;R1 = número em formato decimal
;Destrói: R1, R2, R3        
send_number
        PUSH {R4, LR}
        MOV R4, R0
        MOV R0, R1
        BL num_to_BCD           ;dígitos no STACK
        MOV R3, R0              ;R3 = número de dígitos
        MOV R0, R4              ;R0 = endereço da UART

send_number_stack               ;envia os números da STACK
        POP {R1}
        BL send_char
        SUBS R3, R3, #1         ;afeta flags
        BNE send_number_stack   ;Z=1?
       
        POP {R4, PC}
;-------------------------------send_string-------------------------------------
;send_string envia uma string para UART
;R0 = endereço UART
;R1 = endereço início string na ROM
;R2 = número de caracteres
;R3 = tipo de operação (se soma o endereço ou diminui) (+1 ou -1) ou
;     se é normal(1) ou de trás pra frente(-1)
;Destrói: R1, R2, R3
send_string
        PUSH {R4, R5, R6, LR}
        CMP R3, #1
        ITE EQ
          MOVEQ R5, R2
          MVNNE R5, #0
  
        MOV R6, R1
        MOVS R4, #0
        
send_string_loop
        CMP R4, R5
        BEQ send_string_end
        LDRB R1, [R6, R4]
        BL send_char
        ADD R4, R3              ;R4 = R4 + 1 OU R4 = R4 - 1
        B send_string_loop
        
send_string_end
        POP {R4, R5, R6, PC}
 ;-------------------------------num_to_BCD-------------------------------------       
;num_to_BCD recebe número e o transforma em BCD (ASCII) NA RAM
;R0 = número 
;Destrói: R0, R1, R2, R3
;Retorno: R0 = quantidade de dígitos no stack
num_to_BCD
        MOVS R2, #0             ;contador de dígitos
        CMP R0, R2
        BNE num_to_BCD_loop     ;R0!=0?        
        
        MOV R0, #48             ;código ASCII
        PUSH {R0}
        MOVS R2, #1             ;1 dígito
        B num_to_BCD_end
         
num_to_BCD_loop
        MOV R1, #10
        ;CMP R0, #0
        ;BEQ num_to_BCD_end

        ;calcular resto de divisão
        MOV R3, R0
        UDIV R0, R0, R1        ;altera flags
        MUL R1, R0, R1          
        SUB R1, R3, R1          ;R1 = R0 - floor( R0 / R1 )
        ;R0 = quociente R1 = resto
        
        ADD R1, R1, #48         ;código ASCII
        PUSH {R1}
        ADD R2, R2, #1
        
        CMP R0, #0
        BNE num_to_BCD_loop     
num_to_BCD_end
        MOV R0, R2
        BX LR

/*
;----------------------------remainder_div--------------------------------------
;remainder_div recebe dois números e retorna o resto da divisão entre eles
;R0 = dividendo
;R1 = divisor
;Destrói: R0, R1, R2
;Retorno: R0 = quociente
;         R1 = resto        
remainder_div
        MOV R2, R0
        UDIV R0, R0, R1
        MUL R1, R0, R1
        SUB R1, R2, R1
        BX LR
*/
;---------------------------------operation-------------------------------------
;operation realiza a operação de +, -, * ou / 
;R0 = segundo operando
;R1 = primeiro operando
;R2 = operação
;Destrói: R0, R1
;Retorno: R0 = resultado
;         R1 = código de erro: 0 normal, -1 NaN, -2 negativo
operation
        ;multiplicação
        CMP R2, #42             ;'*'
        ITT EQ
          MULEQ R0, R1, R0
          MOVEQ R1, #0
        BEQ operation_end 
        
        ;soma
        CMP R2, #43             ;'+'
        ITT EQ
          ADDEQ R0, R1, R0
          MOVEQ R1, #0
        BEQ operation_end
        
        ;subtração
        CMP R2, #45             ;'-' 
        BNE operation_div
        CMP R1, R0
        ITTEE HS
          SUBHS R0, R1, R0
          MOVHS R1, #0
          SUBLO R0, R0, R1
          MOVLO R1, #-2 
        B operation_end  

        ;divisão
operation_div
        ;se chegou até aqui estou assumindo que é '/'
        CMP R0, #0
        ITE EQ
          MVNEQ R1, #0
          UDIVNE R0, R1, R0
        
operation_end
        BX LR
       
;-----------------------------receiveFirstOp------------------------------------       
;receiveFirstOp recebe o operando(número) e operação('+','-','*','/' ou '=')
;R0 = endereço da UART
;R1 = 0 (operando 1) ou 1(operando 2)
;Destrói: R0, R1, R2, R3
;Retorno: R0 = operando 
;         R1 = operação      
receiveFirstOp
        PUSH {R4, R5, R6, LR}
        MOVS R3, #0             ;R3 guarda o resultado após cada ciclo
        MOV R4, #10             ;fator multiplicante após cada ciclo       
        MOVS R5, #0             ;contador

receiveFirstOp_loop
        PUSH {R0}               ;preservar endereço UART
        PUSH {R1}               ;preservar se op1 ou op2        
        BL receive_char
        PUSH {R0}               ;porque is_number pode alterar R0
        BL is_number
        CMP R0, #-1             ;se R0 = -1 não é número
        BNE receiveFirstOp_loop_number
        
        ;verifica qual tipo de operador é
        POP {R0, R1}
        BL is_operator          ;flags são alteradas aqui
        BNE receiveFirstOp_operator_Nan_no
        CMP R5, #0
        BNE receiveFirstOp_operator_ACK
        B receiveFirstOp_operator_Nan_no

receiveFirstOp_operator_Nan_no  ;não é número nem operador
        POP {R0}                ;endereço da UART
        B receiveFirstOp_loop   ;necessário receber outro caractere


receiveFirstOp_loop_number      ;confirmado que é número
        POP {R0 ,R6}            ;R0 = dígito do número e R6 = 0 (op1) ou 1 (op2)
        MOV R1, R0              ;send_char necessita char em R1
        POP {R0}                ;recupera endereço UART em R0
        BL send_char
        ADD R5, R5, #1          ;atualiza contador
        MUL R3, R3, R4          ;R3 = R3*10
        SUB R1, R1, #48         ; 0 <= R1 <= 9        
        ADD R3, R3, R1          
        CMP R5, #3              ;se deu 3 dígitos
        MOV R1, R6              ;R6 = 0 (op1) ou 1 (op2)
        BNE receiveFirstOp_loop
        
receiveFirstOp_operator         ;loop para receber o operador
        PUSH {R0}               ;depende do end UART
        PUSH {R1}               ; e modo (op1) ou (op2)
        BL receive_char
        POP {R1}
        BL is_operator
        CMP R0, #-1
        BNE receiveFirstOp_operator_ACK
        POP {R0}
        B receiveFirstOp_operator

receiveFirstOp_operator_ACK     ;acknowledgement ou reconhecimento do operador correto
        MOV R1, R0              ;R1 = char
        POP {R0}                ;R0 = endereço UART
        BL send_char
        MOV R0, R3              ;R0 = número ou (op)
        POP {R4, R5, R6, PC}
;-------------------------------is_operator-------------------------------------        
;is_operator recebe char e confere se seu código ASCII corresponde a 
;operadores '+','-','*' ou '/' quando R1 = 0 ou '=' quando R1 = '='
;R0 = char
;R1 = modo
;Retorno: R0 = operação ou -1 caso não operação
;Destrói: R0
is_operator
        CBZ R1, is_operator_zero
        CMP R0, #61             ;'='
        BEQ is_operator_end
        B is_operator_no
is_operator_zero
        CMP R0, #42             ;'*'
        BEQ is_operator_end
        CMP R0, #43             ;'+'
        BEQ is_operator_end
        CMP R0, #45             ;'-'        
        BEQ is_operator_end
        CMP R0, #47             ;'/'        
        BEQ is_operator_end
is_operator_no
        MVN R0, #0
is_operator_end
        BX LR
;-------------------------------is_number---------------------------------------        
;is_number recebe char e confere se seu código ASCII corresponde a número
;dentre 0 a 9
;R0 = char
;Destrói R0
;Retorno: R0 em ASCII ou -1 caso não número
is_number
        SUBS R0, R0, #48        ;48 representa o 0 em ASCII
        BLO is_number_nan       ;R0<0? 
        CMP R0, #9
        BHI is_number_nan       ;R0>9?
        B is_number_end
is_number_nan
        MVN R0, #0              ;R0 = -1
is_number_end
        BX LR
;-------------------------------receive_char------------------------------------        
;receive_char retorna o char recebido da UART
;R0 = endereço da UART
;Destrói: R0 e R1
;Retorno: R0 = char
receive_char
        LDR R1, [R0, #UART_FR]  ;status da UART
        TST R1, #RXFF_BIT       ;transmissor vazio?
        BEQ receive_char
        LDR R0, [R0]            ;recebe char
        BX LR
;--------------------------------send_char--------------------------------------        
;send_char envia o char para UART
;R0 = endereço da UART
;R1 = char
;Destrói: R2
send_char
        LDR R2, [R0, #UART_FR]
        TST R2, #TXFE_BIT
        BEQ send_char
        STR R1, [R0]
        BX LR

;-------------------------------ROM constants-----------------------------------
        SECTION .rodata:CONST(2)
        DATA
        
NaN     DC8  "NaN"
CRLF    DC8  "\r\n"

        END