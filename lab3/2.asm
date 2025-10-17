format ELF64 executable

entry _start

segment readable executable

_start:
    ; Получаем аргументы командной строки
    pop rcx             ; argc
    cmp rcx, 4          ; проверяем, что есть 3 аргумента + имя программы
    jl exit             ; если аргументов меньше - выходим
    
    pop rsi             ; пропускаем argv[0] (имя программы)
    
    ; Читаем первый аргумент (a)
    pop rsi
    call str_to_int
    mov [a], rax
    
    ; Читаем второй аргумент (b)  
    pop rsi
    call str_to_int
    mov [b], rax
    
    ; Читаем третий аргумент (c)
    pop rsi
    call str_to_int
    mov [c], rax
    
    ; Вычисляем выражение: (((b*c) - b) + c) - a) - b
    mov rax, [b]
    imul qword [c]      ; rax = b * c
    sub rax, [b]        ; rax = (b*c) - b
    add rax, [c]        ; rax = ((b*c) - b) + c
    sub rax, [a]        ; rax = (((b*c) - b) + c) - a
    sub rax, [b]        ; rax = ((((b*c) - b) + c) - a) - b
    
    ; Выводим результат
    call print_int
    call new_line
    call exit

; Функция преобразования строки в число
str_to_int:
    push rbx
    push rcx
    push rdx
    xor rax, rax        ; обнуляем результат
    xor rbx, rbx        ; обнуляем для работы с байтами
    mov rcx, 10         ; основание системы счисления
    
.convert_loop:
    mov bl, [rsi]       ; берем текущий символ
    cmp bl, 0           ; конец строки?
    je .done
    cmp bl, '0'
    jl .done
    cmp bl, '9'
    jg .done
    
    sub bl, '0'         ; преобразуем символ в цифру
    imul rax, rcx       ; умножаем текущий результат на 10
    add rax, rbx        ; добавляем новую цифру
    
    inc rsi             ; переходим к следующему символу
    jmp .convert_loop
    
.done:
    pop rdx
    pop rcx
    pop rbx
    ret

; Функция вывода числа
print_int:
    push rbx
    push rcx
    push rdx
    
    mov rcx, 10
    xor rbx, rbx        ; счетчик цифр
    
    ; Проверяем отрицательное число
    test rax, rax
    jns .positive
    neg rax             ; делаем число положительным
    push rax
    mov al, '-'
    call print_symbl    ; выводим минус
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
    call print_symbl
    dec rbx
    jnz .iter2
    
    pop rdx
    pop rcx
    pop rbx
    ret

; Функция вывода одного символа
print_symbl:
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
    a dq 0
    b dq 0
    c dq 0