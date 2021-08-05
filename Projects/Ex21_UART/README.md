<h2>Laboratório 05 - João Paulo Vargas da Fonseca</h2>
<h4>Comentários</h4>
<ul>
    <li>Foi utilizado o arquivo UART2 como base</li>
</ul>
<h3>Funções importantes:</h3>

<p>transfer_string</p>
<ul>
    <li>Transfere a string "Sistemas Microcontrolados\r\n" através da UART</li>
    <li>Cada Byte transferido pela função wtx</li>
</ul>
'''assembly
;transfer_string transfere o conteudo de ROM08 seguido por CR e LF
;R0 = endereco da UART
;destrói R1, R2, R3
transfer_string
        PUSH {LR}
        LDR R1, =ROM08          ;endereço de início da string
        MOVS R2, #0             ;contador
ts_loop
        CMP R2, #25             ;já escreveu toda a string?
        BEQ ts_CRLF
        LDRB R3, [R1, R2]       ;carrega byte        
        BL wtx                  ;transmite byte
        ADD R2, #1
        B ts_loop
        
ts_CRLF
        LDR R1, =CR             ;endereço de '\r'
        LDRB R3, [R1]           ;'\r'
        BL wtx                  ;transmite byte
        
        LDR R1, =LF             ;endereço de '\n'
        LDRB R3, [R1]           ;'\n'
        BL wtx                  ;transmite byte
        
        POP {PC}
<p>wait_CR</p>
'''assembly
;wait_CR espera pelo caractere '\r'
;R0 = endereco da UART
;destrói R1, R2, R3
wait_CR
        PUSH {LR}
        LDR R1, =CR             ;endereço de '\r'
        LDRB R2, [R1]           ;R2 = '\r'
w_CR_loop
        BL wrx                  ;recebe dado
        CMP R2, R3              ;é '\r'?
        BEQ ACK_CR
        B w_CR_loop
    
ACK_CR
        POP {PC}
