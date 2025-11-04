format ELF executable
entry _start

segment readable executable
_start:
    ; Реверс строки
    mov ecx, str_len
    mov esi, string + str_len - 1
    mov edi, reversed
    
reverse_loop:
    std
    lodsb
    cld
    stosb
    loop reverse_loop
    
    ; Вывод исходной строки
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_original
    mov edx, msg_original_len
    int 0x80
    
    mov eax, 4
    mov ebx, 1
    mov ecx, string
    mov edx, str_len
    int 0x80
    
    ; Новая строка
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    ; Вывод reversed строки
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_reversed
    mov edx, msg_reversed_len
    int 0x80
    
    mov eax, 4
    mov ebx, 1
    mov ecx, reversed
    mov edx, str_len
    int 0x80
    
    ; Новая строка
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    ; Завершение
    mov eax, 1
    xor ebx, ebx
    int 0x80

segment readable writeable
    string db 'AMVtdiYVETHnNhuYwnWDVBqL', 0
    str_len = $ - string - 1
    msg_original db 'Original: '
    msg_original_len = $ - msg_original
    msg_reversed db 'Reversed: '
    msg_reversed_len = $ - msg_reversed
    newline db 10
    reversed rb 30