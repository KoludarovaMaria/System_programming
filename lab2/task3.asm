format ELF executable
entry _start

segment readable executable
_start:
    ; Вывод заголовка
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_triangle
    mov edx, msg_triangle_len
    int 0x80
    
    mov edi, buffer
    mov ecx, 1  ; количество символов в первой строке
    
triangle_loop:
    push ecx
    mov al, [symbol]
    
    ; Заполнение строки символами
    mov ebx, ecx
fill_line:
    mov [edi], al
    inc edi
    dec ebx
    jnz fill_line
    
    ; Добавление новой строки
    mov byte [edi], 10
    inc edi
    
    pop ecx
    inc ecx
    cmp ecx, total_lines
    jle triangle_loop
    
    ; Вывод треугольника
    mov eax, 4
    mov ebx, 1
    mov ecx, buffer
    mov edx, edi
    sub edx, buffer
    int 0x80
    
    ; Завершение
    mov eax, 1
    xor ebx, ebx
    int 0x80

segment readable writeable
    symbol db '+'
    total_lines = 11
    msg_triangle db 'Triangle:', 10
    msg_triangle_len = $ - msg_triangle
    buffer rb 100