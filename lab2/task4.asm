format ELF executable
entry _start

segment readable executable

_start:
    ; Вычисляем сумму цифр 5277616985
    mov esi, num_str
    mov ecx, 10
    xor ebx, ebx
    
sum_loop:
    mov al, [esi]
    sub al, '0'
    add bl, al
    inc esi
    loop sum_loop

    ; Преобразуем результат в строку
    movzx ax, bl
    mov edi, result
    
    cmp al, 10
    jb one_digit
    ; Двузначное число
    mov cl, 10
    div cl
    add al, '0'
    mov [edi], al
    inc edi
    mov al, ah
one_digit:
    add al, '0'
    mov [edi], al
    inc edi
    ; Добавляем символ новой строки
    mov byte [edi], 10

    ; Вывод текста
    mov eax, 4
    mov ebx, 1
    mov ecx, output_text
    mov edx, output_text_len
    int 0x80

    ; Вывод результата
    mov eax, 4
    mov ebx, 1
    mov ecx, result
    mov edx, 3
    int 0x80

    ; Завершение программы
    mov eax, 1
    xor ebx, ebx
    int 0x80

segment readable writeable
    num_str db '5277616985'
    output_text db 'Sum of digits: '
    output_text_len = $ - output_text
    result rb 3