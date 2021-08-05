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
```
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
```
<p>wait_CR</p>
<ul>
    <li>Espera receber o caractere '\r'</li>
    <li>Cada Byte lido pela função wrx</li>
</ul>
```
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
```
<p>wtx</p>
<ul>
    <li>Espera Tx esvaziar para enviar o byte</li>
    <li>É o mesmo label que há em uart2, só que agora como função</li>
</ul>
```
;R3 = dado a ser escrito
wtx     LDR R4, [R0, #UART_FR] ; status da UART
        TST R4, #TXFE_BIT ; transmissor vazio?
        BEQ wtx
        STR R3, [R0] ; escreve no registrador de dados da UART0 (transmite)

        BX LR
```
<p>wrx</p>
<ul>
    <li>Espera Rx estar cheio para fazer a leitura</li>
    <li>É o mesmo label que há em uart2, só que agora como função</li>
</ul>
```
;retorna R3 como dado lido
wrx
        LDR R4, [R0, #UART_FR] ; status da UART
        TST R4, #RXFF_BIT ; receptor cheio?
        BEQ wrx
        LDR R3, [R0] 

        BX LR
```
<h3>Alterações em funções importantes:</h3>
UART_config
<ul>
    <li>IBRD = 3333 e FBRD = 22 para 300bps</li>
</ul>
```
        ; clock = 16MHz, baud rate = 300 bps
        MOV R1, #3333
        STR R1, [R0, #UART_IBRD]
        MOV R1, #22
        STR R1, [R0, #UART_FBRD]
```
<ul>
    <li>UARTLCRH</li>
    <li>WLEN = 0x3, FEN = 0, STP2 = 1, PEN = 1, EPS = 1</li>
    <li>1 byte de dado, FIFO disabled, 2 stop bits, paridade par, paridade habilitada</li>
</ul>
```
        ; 8 bits, 2 stops, even parity, FIFOs disabled, no interrupts
        MOV R1, #01101110b
        STR R1, [R0, #UART_LCRH]
```
main
<ul>
    <li>Loop infinito de esperar o caractere desejado e escrever a string</li>
</ul>
```
loop:
        BL wait_CR              ;espera pelo caractere '\r'
        BL transfer_string      ;escreve a string "Sistemas Microcontrolados\r\n"
        B loop
```