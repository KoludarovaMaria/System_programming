format ELF64 executable

segment readable executable
entry start

; Системные вызовы
SYS_READ    = 0
SYS_WRITE   = 1
SYS_OPEN    = 2
SYS_CLOSE   = 3
SYS_EXIT    = 60

; Флаги открытия файлов
O_RDONLY    = 0
O_WRONLY    = 1
O_CREAT     = 64
O_TRUNC     = 512

STDERR      = 2

start:
    ; Получаем количество аргументов
    pop rcx
    cmp rcx, 3
    jne error_args
    
    ; Пропускаем имя программы
    pop rdi
    
    ; Открываем входной файл
    pop rdi
    mov rax, SYS_OPEN
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    jl error_input
    mov [input_fd], rax
    
    ; Открываем выходной файл
    pop rdi
    mov rax, SYS_OPEN
    mov rsi, O_WRONLY or O_CREAT or O_TRUNC
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl error_output
    mov [output_fd], rax

    ; Инициализация
    mov qword [lines_count], 0
    mov qword [buffer_ptr], line_buffer

read_loop:
    ; Читаем строку
    mov rsi, [buffer_ptr]  ; текущая позиция в буфере
    mov r12, rsi           ; сохраняем начало строки
    
read_char:
    ; Читаем один символ
    mov rax, SYS_READ
    mov rdi, [input_fd]
    mov rsi, char_buffer
    mov rdx, 1
    syscall
    
    cmp rax, 0
    jle check_last_line    ; конец файла или ошибка
    
    mov al, [char_buffer]
    
    ; Сохраняем символ в буфере
    mov rsi, [buffer_ptr]
    mov [rsi], al
    inc qword [buffer_ptr]
    
    ; Проверяем конец строки
    cmp al, 10
    jne read_char
    
    ; Заменяем \n на 0
    mov rsi, [buffer_ptr]
    dec rsi
    mov byte [rsi], 0
    
    ; Сохраняем указатель на строку
    mov rbx, [lines_count]
    shl rbx, 3
    add rbx, lines_array
    mov [rbx], r12
    
    inc qword [lines_count]
    
    ; Проверяем лимиты
    cmp qword [lines_count], 10000
    jae error_too_many_lines
    
    mov rax, [buffer_ptr]
    cmp rax, line_buffer_end
    jae error_buffer_overflow
    
    jmp read_loop

check_last_line:
    ; Проверяем, есть ли последняя строка без \n
    cmp r12, [buffer_ptr]
    je finish_reading
    
    ; Сохраняем последнюю строку
    mov rsi, [buffer_ptr]
    mov byte [rsi], 0
    
    mov rbx, [lines_count]
    shl rbx, 3
    add rbx, lines_array
    mov [rbx], r12
    
    inc qword [lines_count]

finish_reading:
    ; Закрываем входной файл
    mov rax, SYS_CLOSE
    mov rdi, [input_fd]
    syscall

    ; Записываем строки в обратном порядке
    mov rcx, [lines_count]
    test rcx, rcx
    jz close_output
    
    dec rcx

write_loop:
    ; Получаем указатель на строку
    mov rax, rcx
    shl rax, 3
    add rax, lines_array
    mov rsi, [rax]
    
    ; Вычисляем длину строки
    mov rdi, rsi
    call strlen
    mov rdx, rax
    
    ; Записываем строку
    mov rax, SYS_WRITE
    mov rdi, [output_fd]
    syscall
    
    ; Записываем перевод строки (кроме последней строки)
    cmp rcx, 0
    je no_newline
    
    mov rax, SYS_WRITE
    mov rdi, [output_fd]
    mov rsi, newline
    mov rdx, 1
    syscall

no_newline:
    dec rcx
    jns write_loop

close_output:
    ; Закрываем выходной файл
    mov rax, SYS_CLOSE
    mov rdi, [output_fd]
    syscall
    
    ; Успешный выход
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Вычисление длины строки
; rdi - указатель на строку
; возвращает rax - длина
strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; Обработка ошибок
error_args:
    mov rsi, msg_args
    mov rdx, msg_args_len
    jmp error_exit

error_input:
    mov rsi, msg_input
    mov rdx, msg_input_len
    jmp error_exit

error_output:
    mov rsi, msg_output
    mov rdx, msg_output_len
    jmp error_exit

error_buffer_overflow:
    mov rsi, msg_buffer
    mov rdx, msg_buffer_len
    jmp error_exit

error_too_many_lines:
    mov rsi, msg_too_many
    mov rdx, msg_too_many_len

error_exit:
    mov rax, SYS_WRITE
    mov rdi, STDERR
    syscall
    
    ; Закрываем файлы при ошибке
    mov rax, SYS_CLOSE
    mov rdi, [input_fd]
    syscall
    
    mov rax, SYS_CLOSE
    mov rdi, [output_fd]
    syscall
    
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

segment readable writeable
    input_fd      dq 0
    output_fd     dq 0
    lines_count   dq 0
    buffer_ptr    dq 0
    
    char_buffer   db 0
    newline       db 10

    ; Сообщения об ошибках
    msg_args      db "Usage: ./program input.txt output.txt", 10
    msg_args_len  = $ - msg_args
    
    msg_input     db "Error: Cannot open input file", 10
    msg_input_len = $ - msg_input
    
    msg_output    db "Error: Cannot open output file", 10
    msg_output_len = $ - msg_output
    
    msg_buffer    db "Error: Buffer overflow - file too large", 10
    msg_buffer_len = $ - msg_buffer
    
    msg_too_many  db "Error: Too many lines (max 10000)", 10
    msg_too_many_len = $ - msg_too_many

; Буфер для данных (1MB)
line_buffer:
    times 1048576 db 0
line_buffer_end:

; Массив указателей на строки (10000 указателей)
lines_array:
    times 10000 dq 0