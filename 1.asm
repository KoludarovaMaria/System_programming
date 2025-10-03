format ELF64 executable

segment executable readable
entry _start

_start:
    ; Получаем аргументы командной строки
    pop rcx         ; argc
    cmp rcx, 2
    jl exit         ; если нет аргументов
    
    pop rsi         ; argv[0] - имя программы
    pop rsi         ; argv[1] - наш символ
    
    ; Проверяем, что аргумент не пустой
    cmp byte [rsi], 0
    je exit
    
    ; Сохраняем символ
    mov al, [rsi]
    mov [char_buffer], al
    
    ; Выводим "символ "
    mov rax, 1
    mov rdi, 1
    mov rsi, symbol_msg
    mov rdx, symbol_len
    syscall
    
    ; Выводим сам символ
    mov rax, 1
    mov rdi, 1
    mov rsi, char_buffer
    mov rdx, 1
    syscall
    
    ; Выводим ", ASCII "
    mov rax, 1
    mov rdi, 1
    mov rsi, ascii_msg
    mov rdx, ascii_len
    syscall
    
    ; Преобразуем ASCII-код в строку
    movzx rax, byte [char_buffer]
    mov rdi, num_buffer
    call int_to_string
    
    ; Находим длину строки с числом
    mov rsi, num_buffer
    mov rdx, 0
.find_length:
    cmp byte [rsi + rdx], 0
    je .found
    inc rdx
    jmp .find_length
.found:
    
    ; Выводим ASCII-код
    mov rax, 1
    mov rdi, 1
    mov rsi, num_buffer
    syscall
    
    ; Новая строка
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    jmp exit

; Функция преобразования числа в строку
int_to_string:
    push rbx
    mov rcx, 10
    mov rbx, 15
    mov byte [rdi + 16], 0
    
.convert:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rdi + rbx], dl
    dec rbx
    test rax, rax
    jnz .convert
    
.fill:
    cmp rbx, 0
    jl .done
    mov byte [rdi + rbx], ' '
    dec rbx
    jmp .fill
    
.done:
    pop rbx
    ret

exit:
    mov rax, 60     ; sys_exit
    xor rdi, rdi
    syscall

segment readable writeable
    symbol_msg db 'символ '
    symbol_len = $ - symbol_msg
    ascii_msg db ', ASCII '
    ascii_len = $ - ascii_msg
    newline db 10
    
    char_buffer rb 1
    num_buffer rb 16