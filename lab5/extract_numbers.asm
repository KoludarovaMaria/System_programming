section .data
    error_argc db "Usage: ./program input_file output_file", 10, 0
    error_open_input db "Error: Cannot open input file", 10, 0
    error_open_output db "Error: Cannot open output file", 10, 0
    space db " ", 0
    newline db 10, 0
    
section .bss
    input_fd resq 1
    output_fd resq 1
    buffer resb 1024
    number_buffer resb 32
    in_number resb 1
    
section .text
    global _start

_start:
    ; Проверяем количество аргументов
    pop rcx
    cmp rcx, 3
    jne error_arguments
    
    ; Пропускаем имя программы
    pop rdi
    
    ; Получаем имя входного файла
    pop rdi
    
    ; Открываем входной файл для чтения
    mov rax, 2          ; sys_open
    mov rsi, 0          ; O_RDONLY
    mov rdx, 0          ; mode
    syscall
    
    cmp rax, 0
    jl error_open_input_file
    mov [input_fd], rax
    
    ; Получаем имя выходного файла
    pop rdi
    
    ; Создаем/открываем выходной файл для записи
    mov rax, 2          ; sys_open
    mov rsi, 0x41       ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0644o      ; права доступа
    syscall
    
    cmp rax, 0
    jl error_open_output_file
    mov [output_fd], rax
    
    ; Инициализируем состояние
    mov byte [in_number], 0
    
read_loop:
    ; Читаем данные из файла
    mov rax, 0          ; sys_read
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, 1024
    syscall
    
    cmp rax, 0
    jle process_final_number ; Если конец файла
    
    ; Обрабатываем прочитанные данные
    mov rcx, rax        ; количество прочитанных байт
    mov rsi, buffer
    
process_buffer:
    mov al, [rsi]
    
    ; Проверяем цифру (0-9)
    cmp al, '0'
    jb not_digit
    cmp al, '9'
    ja not_digit
    
    ; Это цифра - добавляем в текущее число
    call add_to_number
    jmp next_char
    
not_digit:
    ; Не цифра - если было число, завершаем его
    cmp byte [in_number], 1
    jne next_char
    
    ; Завершаем текущее число
    call finish_number
    
next_char:
    inc rsi
    loop process_buffer
    jmp read_loop

process_final_number:
    ; Обрабатываем последнее число если оно есть
    cmp byte [in_number], 1
    jne exit_program
    call finish_number

exit_program:
    ; Закрываем файлы
    mov rax, 3          ; sys_close
    mov rdi, [input_fd]
    syscall
    
    mov rax, 3          ; sys_close
    mov rdi, [output_fd]
    syscall
    
    mov rax, 60         ; sys_exit
    mov rdi, 0
    syscall

; Функция для добавления цифры к текущему числу
add_to_number:
    push rsi
    push rcx
    
    ; Находим конец буфера числа
    mov rdi, number_buffer
    cmp byte [in_number], 0
    je .first_digit
    
    ; Ищем конец существующего числа
.find_end:
    cmp byte [rdi], 0
    je .add_digit
    inc rdi
    jmp .find_end
    
.first_digit:
    mov byte [in_number], 1
    
.add_digit:
    ; Добавляем новую цифру
    mov [rdi], al
    inc rdi
    mov byte [rdi], 0   ; нулевой терминатор
    
    pop rcx
    pop rsi
    ret

; Функция для завершения текущего числа и записи в файл
finish_number:
    push rsi
    push rcx
    
    ; Проверяем, что число не пустое
    cmp byte [number_buffer], 0
    je .done
    
    ; Записываем число в выходной файл
    mov rdi, [output_fd]
    mov rsi, number_buffer
    call write_string
    
    ; Записываем пробел после числа
    mov rdi, [output_fd]
    mov rsi, space
    call write_string
    
    ; Очищаем буфер числа
    mov rdi, number_buffer
    mov rcx, 32
    xor al, al
    rep stosb
    
.done:
    mov byte [in_number], 0
    pop rcx
    pop rsi
    ret

; Функция для записи строки в файл
; rdi - файловый дескриптор, rsi - указатель на строку
write_string:
    push rcx
    push rdx
    push rsi
    
    ; Находим длину строки
    mov rdx, rsi
.find_length:
    cmp byte [rdx], 0
    je .found_length
    inc rdx
    jmp .find_length
    
.found_length:
    sub rdx, rsi        ; длина строки в rdx
    
    ; Записываем строку
    mov rax, 1          ; sys_write
    ; rdi уже содержит файловый дескриптор
    ; rsi уже содержит указатель на строку
    ; rdx содержит длину
    syscall
    
    pop rsi
    pop rdx
    pop rcx
    ret

; Функция для записи строки в stderr
; rsi - указатель на строку
write_error:
    push rcx
    push rdx
    
    ; Находим длину строки
    mov rdx, rsi
.find_error_length:
    cmp byte [rdx], 0
    je .found_error_length
    inc rdx
    jmp .find_error_length
    
.found_error_length:
    sub rdx, rsi        ; длина строки в rdx
    
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    syscall
    
    pop rdx
    pop rcx
    ret

; Обработчики ошибок
error_arguments:
    mov rsi, error_argc
    call write_error
    jmp exit_error

error_open_input_file:
    mov rsi, error_open_input
    call write_error
    jmp exit_error

error_open_output_file:
    mov rsi, error_open_output
    call write_error
    jmp exit_error

exit_error:
    mov rax, 60         ; sys_exit
    mov rdi, 1
    syscall