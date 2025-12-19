format ELF64 executable

entry _start

segment readable executable

_start:
    ; Получаем аргументы командной строки
    pop rcx             ; argc
    cmp rcx, 3          ; проверяем, что есть 2 аргумента + имя программы (b и c)
    jl show_usage       ; если аргументов меньше - показываем использование
    
    pop rsi             ; пропускаем argv[0] (имя программы)
    
    ; Читаем первый аргумент (b)
    pop rsi
    call str_to_int
    mov [b], rax
    
    ; Читаем второй аргумент (c)  
    pop rsi
    call str_to_int
    mov [c], rax
    
    ; Вычисляем выражение: (((c+b)*b)-c)
    ; c + b
    mov rax, [c]        ; rax = c
    add rax, [b]        ; rax = c + b
    
    ; (c + b) * b
    imul qword [b]      ; rax = (c + b) * b
    
    ; ((c + b) * b) - c
    sub rax, [c]        ; rax = ((c + b) * b) - c
    
    ; Выводим результат
    mov rsi, result_msg
    call print_string
    call print_int
    call new_line
    call exit

show_usage:
    mov rsi, usage_msg
    call print_string
    call exit

; Функция преобразования строки в число
str_to_int:
    push rbx
    push rcx
    push rdx
    xor rax, rax        ; обнуляем результат
    xor rbx, rbx        ; обнуляем для работы с байтами
    mov rcx, 10         ; основание системы счисления
    
    ; Проверяем знак
    mov bl, [rsi]
    cmp bl, '-'
    jne .convert_loop
    inc rsi             ; пропускаем минус
    push 1              ; флаг отрицательного числа
    jmp .convert_loop_no_sign
    
.convert_loop:
    push 0              ; флаг положительного числа
    
.convert_loop_no_sign:
    mov bl, [rsi]       ; берем текущий символ
    cmp bl, 0           ; конец строки?
    je .done_digits
    cmp bl, '0'
    jl .invalid
    cmp bl, '9'
    jg .invalid
    
    sub bl, '0'         ; преобразуем символ в цифру
    imul rax, rcx       ; умножаем текущий результат на 10
    add rax, rbx        ; добавляем новую цифру
    
    inc rsi             ; переходим к следующему символу
    jmp .convert_loop_no_sign
    
.invalid:
    ; Если встречаем нецифровой символ, считаем, что число закончилось
    jmp .done_digits
    
.done_digits:
    pop rdx             ; получаем флаг знака
    test rdx, rdx
    jz .positive
    neg rax             ; меняем знак на отрицательный
    
.positive:
    pop rdx
    pop rcx
    pop rbx
    ret

; Функция вывода числа
print_int:
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rcx, 10
    xor rbx, rbx        ; счетчик цифр
    
    ; Проверяем отрицательное число
    test rax, rax
    jns .positive
    neg rax             ; делаем число положительным
    push rax
    mov al, '-'
    call print_char     ; выводим минус
    pop rax
    
.positive:
    ; Извлекаем цифры и сохраняем в стек
.iter1:
    xor rdx, rdx
    div rcx             ; rax / 10, остаток в rdx
    add dl, '0'         ; преобразуем цифру в символ
    push rdx
    inc rbx
    cmp rax, 0
    jne .iter1
    
    ; Выводим цифры из стека
.iter2:
    pop rax
    call print_char
    dec rbx
    jnz .iter2
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Функция вывода строки
print_string:
    push rax
    push rdi
    push rdx
    
    ; Находим длину строки
    mov rdi, rsi
    xor rcx, rcx
.not_end:
    cmp byte [rdi], 0
    je .found_end
    inc rdi
    inc rcx
    jmp .not_end
    
.found_end:
    ; Выводим строку
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rdx, rcx        ; длина строки
    syscall
    
    pop rdx
    pop rdi
    pop rax
    ret

; Функция вывода одного символа
print_char:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Сохраняем символ в стеке
    push rax
    
    ; Системный вызов write
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, rsp        ; указатель на символ в стеке
    mov rdx, 1          ; длина 1 байт
    syscall
    
    ; Восстанавливаем стек
    pop rax
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Функция вывода новой строки
new_line:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, newline
    mov rdx, 1          ; длина 1 байт
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; Функция выхода
exit:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; код возврата 0
    syscall

segment readable writeable
    newline db 10
    usage_msg db 'Usage: program b c', 10, 0
    result_msg db 'Result: ', 0
    b dq 0
    c dq 0