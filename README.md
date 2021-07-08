# Laboratorio_02
 lab_02_ex10_ex11

João Paulo Vargas da Fonseca

Exerc_10:
            Foi feito levando em conta que qualquer número posiivo
            maior que zero pode ser escrito na forma 
            
                            b=(2^n)*(c+1) 
            
            ou seja, a multiplicação de dois números 'a' e 'b' pode
            ser feita fazendo a multiplicação por uma potência de 
            dois, uma soma e mais outra multiplicação de acordo com
            a fórmula a seguir
            
                            a*b=(2^n)*(a*c+a)
                            
            A multiplicação a*c será calculada a partir da mesma função,
            ou seja, foi criada uma sub-rotina "Mul16b" que é responsável
            por preparar e finalizar a multiplicação, que é feita em 
            uma sub-rotina "aux" recursiva.
            
Exerc_11:   
            Foi feito de duas formas, uma forma recursiva: fatorial_r não
            recomendada por ter desempenho pior que em loop: fatorial_l
            
            Já quanto ao método de verificar se houve overflow, simplesmente
            verifico se é maior que a constante 12 em decimal, já que fatorial
            de 13 para cima causaria overflow se utilizasse somente 1 registrador,
            que é o meu caso.