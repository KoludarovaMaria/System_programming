format ELF executable
entry _start

segment readable executable
_start:
    ; Вывод заголовка
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_matrix
    mov edx, msg_matrix_len
    int 0x80
    
    ; Заполнение буфера символами
    mov ecx, total_chars
    mov esi, buffer
    mov al, [symbol]
    
fill_buffer:
    mov [esi], al
    inc esi
    loop fill_buffer
    
    ; Вывод матрицы MxK
    mov esi, buffer
    mov ecx, total_lines
    
print_lines:
    push ecx
    
    ; Вывод одной строки матрицы
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    mov edx, chars_per_line
    int 0x80
    
    ; Переход к следующей строке
    add esi, chars_per_line
    
    ; Новая строка
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    pop ecx
    loop print_lines
    
    ; Завершение
    mov eax, 1
    xor ebx, ebx
    int 0x80

segment readable writeable
    symbol db '+'
    total_chars = 66
    chars_per_line = 6
    total_lines = 11
    msg_matrix db 'Matrix 6x11:', 10
    msg_matrix_len = $ - msg_matrix
    newline db 10
    buffer rb 100