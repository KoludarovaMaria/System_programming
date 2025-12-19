format ELF64 executable 3
entry _start

segment readable writeable
    ; Данные для вывода
    prompt_n       db 'Enter n: ', 0
    result_msg     db 'Result: ', 0
    newline        db 10, 0
    
    ; Переменные
    n              dq 0      ; входное число n
    sum            dq 0      ; результат
    k              dq 1      ; счетчик цикла
    
    ; Буферы
    input_buf      rb 32
    output_buf     rb 32

segment readable executable
; ============================================
; Подпрограмма: преобразование числа в строку
; Вход: RAX = число
; Выход: RSI = указатель на строку, RCX = длина
; ============================================
int_to_str:
    push rbx
    push rdx
    push r8
    
    mov rbx, output_buf + 31  ; конец буфера
    mov byte [rbx], 0         ; нуль-терминатор
    dec rbx
    
    test rax, rax
    jns .convert_positive
    
    ; Отрицательное число
    neg rax
    push rax
    mov rax, 1                ; флаг отрицательного
    jmp .convert
    
.convert_positive:
    push rax
    xor rax, rax              ; флаг положительного
    
.convert:
    pop rcx                   ; сохраняем число в RCX
    push rax                  ; сохраняем флаг знака
    
    mov rax, rcx              ; число в RAX для деления
    
.divide_loop:
    xor rdx, rdx              ; обнуляем RDX (важно для деления)
    mov r8, 10
    div r8                    ; rax = частное, rdx = остаток
    
    add dl, '0'              ; преобразуем цифру в символ
    mov [rbx], dl
    dec rbx
    
    test rax, rax
    jnz .divide_loop
    
    pop rax                   ; восстанавливаем флаг знака
    cmp rax, 1
    jne .done
    
    ; Если было отрицательное, добавляем минус
    mov byte [rbx], '-'
    dec rbx
    
.done:
    inc rbx                   ; корректируем указатель
    mov rsi, rbx              ; возвращаем указатель на начало строки
    mov rcx, output_buf + 31
    sub rcx, rbx              ; вычисляем длину
    
    pop r8
    pop rdx
    pop rbx
    ret

; ============================================
; Подпрограмма: чтение строки с stdin
; Выход: RAX = длина, буфер в input_buf
; ============================================
read_string:
    mov rax, 0                ; sys_read
    mov rdi, 0                ; stdin
    mov rsi, input_buf
    mov rdx, 32               ; максимальная длина
    syscall
    
    ; Добавляем нуль-терминатор
    mov rbx, input_buf
    add rbx, rax
    mov byte [rbx], 0
    
    ret

; ============================================
; Подпрограмма: преобразование строки в число
; Вход: RSI = указатель на строку
; Выход: RAX = число
; ============================================
str_to_int:
    push rbx
    push rcx
    push rdx
    
    xor rax, rax             ; обнуляем результат
    xor rcx, rcx             ; обнуляем счетчик
    xor rbx, rbx             ; для знака
    
    ; Проверяем знак
    cmp byte [rsi], '-'
    jne .parse_loop
    inc rbx                  ; устанавливаем флаг отрицательного
    inc rsi
    
.parse_loop:
    mov cl, byte [rsi]
    test cl, cl
    jz .finish
    cmp cl, 10              ; также проверяем символ новой строки
    je .finish
    
    cmp cl, '0'
    jb .finish
    cmp cl, '9'
    ja .finish
    
    ; Преобразуем символ в цифру
    sub cl, '0'
    
    ; Умножаем текущий результат на 10 и добавляем цифру
    imul rax, rax, 10
    add rax, rcx
    
    inc rsi
    jmp .parse_loop
    
.finish:
    ; Если был знак минус, инвертируем
    test rbx, rbx
    jz .positive
    neg rax
    
.positive:
    pop rdx
    pop rcx
    pop rbx
    ret

; ============================================
; Подпрограмма: вывод строки
; Вход: RSI = строка
; ============================================
print_string:
    push rsi
    push rdx
    
    ; Вычисляем длину строки
    mov rdx, 0
.find_end:
    cmp byte [rsi + rdx], 0
    je .found_end
    inc rdx
    jmp .find_end
    
.found_end:
    ; Выводим строку
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    ; rsi уже установлен
    ; rdx = длина
    syscall
    
    pop rdx
    pop rsi
    ret

; ============================================
; Главная программа
; ============================================
_start:
    ; Выводим приглашение
    mov rsi, prompt_n
    call print_string
    
    ; Читаем ввод
    call read_string
    mov rsi, input_buf
    call str_to_int
    mov [n], rax
    
    ; Инициализация
    mov qword [sum], 0        ; sum = 0
    mov qword [k], 1          ; k = 1
    
calc_loop:
    mov rbx, [k]
    cmp rbx, [n]              ; while (k <= n)
    jg end_calc
    
    ; Вычисляем знак: (-1)^(k-1)
    mov rcx, rbx
    dec rcx                   ; rcx = k-1
    and rcx, 1                ; проверяем четность
    jz positive_term          ; если четное -> положительный член
    
    ; Отрицательный член: -k^2
    mov rax, rbx
    imul rax, rax             ; rax = k^2
    sub qword [sum], rax      ; sum -= k^2
    jmp next_iter
    
positive_term:
    ; Положительный член: +k^2
    mov rax, rbx
    imul rax, rax             ; rax = k^2
    add qword [sum], rax      ; sum += k^2
    
next_iter:
    inc qword [k]             ; k++
    jmp calc_loop
    
end_calc:
    ; Выводим сообщение о результате
    mov rsi, result_msg
    call print_string
    
    ; Преобразуем результат в строку и выводим
    mov rax, [sum]
    call int_to_str           ; теперь rsi = строка, rcx = длина
    
    ; Выводим число (rsi и rcx уже установлены)
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    syscall
    
    ; Выводим новую строку
    mov rsi, newline
    call print_string
    
    ; Завершаем программу
    mov rax, 60               ; sys_exit
    xor rdi, rdi              ; код возврата 0
    syscall