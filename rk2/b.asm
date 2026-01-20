format ELF64
include 'func.asm'
public _start

section '.bss' writable
    N dq 0
    sum_add dq 0          ; сумма добавляемых элементов
    sum_sub dq 0          ; сумма вычитаемых элементов (положительных, но со знаком -)
    child_pid_add dq 0
    child_pid_sub dq 0
    status dq 0

section '.data' writable
    msg_add db "Sum of added elements: ", 0
    msg_sub db "Sum of subtracted elements: ", 0
    msg_total db "Total sum: ", 0
    msg_err_args db "Usage: program N (where N >= 0)", 0xA, 0
    msg_fork_err db "Fork failed", 0xA, 0

section '.text' executable

; Функция для дочернего процесса, вычисляющего сумму добавляемых элементов
; Паттерн: каждые 4 элемента: [0]+[1]-[2]-[3]
; Или аналитически: если i mod 4 == 0 или i mod 4 == 1, то элемент добавляется
child_add_process:
    mov rbx, [N]
    xor r12, r12          ; сумма
    xor r13, r13          ; индекс i
    
.add_loop:
    cmp r13, rbx
    jg .add_done
    
    ; Проверяем i mod 4
    mov rax, r13
    mov rcx, 4
    xor rdx, rdx
    div rcx               ; RDX = i mod 4
    
    ; Если i mod 4 == 0 или i mod 4 == 1, то добавляем
    cmp rdx, 0
    je .do_add
    cmp rdx, 1
    je .do_add
    jmp .next
    
.do_add:
    add r12, r13
    
.next:
    inc r13
    jmp .add_loop
    
.add_done:
    ; Вывод результата
    mov rsi, msg_add
    call print_str
    
    mov rdi, r12
    call print_number
    call new_line
    
    ; Завершение с кодом = сумма (ограничиваем 0-255)
    mov rax, 60
    mov rdi, r12
    cmp rdi, 255
    jbe .exit
    mov rdi, 255
.exit:
    syscall

; Функция для дочернего процесса, вычисляющего сумму вычитаемых элементов
; Элементы с i mod 4 == 2 или i mod 4 == 3 вычитаются
child_sub_process:
    mov rbx, [N]
    xor r12, r12          ; сумма положительных значений вычитаемых элементов
    xor r13, r13          ; индекс i
    
.sub_loop:
    cmp r13, rbx
    jg .sub_done
    
    ; Проверяем i mod 4
    mov rax, r13
    mov rcx, 4
    xor rdx, rdx
    div rcx               ; RDX = i mod 4
    
    ; Если i mod 4 == 2 или i mod 4 == 3, то запоминаем для вычитания
    cmp rdx, 2
    je .do_sub
    cmp rdx, 3
    je .do_sub
    jmp .next_sub
    
.do_sub:
    add r12, r13
    
.next_sub:
    inc r13
    jmp .sub_loop
    
.sub_done:
    ; Вывод результата (это сумма положительных значений, которые будут вычтены)
    mov rsi, msg_sub
    call print_str
    
    mov rdi, r12
    call print_number
    call new_line
    
    ; Завершение с кодом = сумма (ограничиваем 0-255)
    mov rax, 60
    mov rdi, r12
    cmp rdi, 255
    jbe .exit_sub
    mov rdi, 255
.exit_sub:
    syscall

; Функция для проверки результата (однопроцессорный вариант для проверки)
check_result:
    push rbp
    mov rbp, rsp
    
    mov rbx, [N]
    xor r12, r12          ; общая сумма
    xor r13, r13          ; индекс i
    
.check_loop:
    cmp r13, rbx
    jg .check_done
    
    ; Определяем знак элемента
    mov rax, r13
    mov rcx, 4
    xor rdx, rdx
    div rcx               ; RDX = i mod 4
    
    ; Если i mod 4 == 0 или i mod 4 == 1, то +
    ; Если i mod 4 == 2 или i mod 4 == 3, то -
    cmp rdx, 2
    jb .positive          ; if RDX < 2
    ; Отрицательный элемент
    sub r12, r13
    jmp .next_check
    
.positive:
    add r12, r13
    
.next_check:
    inc r13
    jmp .check_loop
    
.check_done:
    ; Выводим результат проверки
    mov rsi, msg_total
    call print_str
    mov rdi, r12
    call print_number
    call new_line
    
    pop rbp
    ret

_start:
    ; Проверка аргументов командной строки
    pop rax                 ; argc
    cmp rax, 2
    jge .args_ok

    ; Ошибка: не хватает аргументов
    mov rsi, msg_err_args
    call print_str
    jmp exit_error

.args_ok:
    ; Получение N
    mov rsi, [rsp + 8]      ; argv[1]
    call str_number
    mov [N], rax
    
    ; Проверяем, что N >= 0
    cmp rax, 0
    jl .n_error
    
    ; Для проверки: вычисляем результат одним процессом
    ; call check_result
    
    ; Создание первого дочернего процесса (сумма добавляемых элементов)
    mov rax, 57             ; sys_fork
    syscall
    cmp rax, 0
    jl .fork_error
    jz child_add_process    ; если 0 - это дочерний процесс add
    mov [child_pid_add], rax ; иначе сохраняем PID

    ; Создание второго дочернего процесса (сумма вычитаемых элементов)
    mov rax, 57             ; sys_fork
    syscall
    cmp rax, 0
    jl .fork_error
    jz child_sub_process    ; если 0 - это дочерний процесс sub
    mov [child_pid_sub], rax ; иначе сохраняем PID

    ; Родительский процесс ждет завершения дочерних
.parent_wait:
    ; Ждем первого ребенка (add) и получаем его код возврата
    mov rax, 61             ; sys_wait4
    mov rdi, [child_pid_add]
    lea rsi, [status]
    xor rdx, rdx
    xor r10, r10
    syscall

    ; Получаем код возврата (сумму добавляемых элементов)
    mov rax, [status]
    mov al, ah              ; код возврата в AH
    movzx rax, al           ; расширяем до 64 бит
    mov [sum_add], rax

    ; Ждем второго ребенка (sub)
    mov rax, 61             ; sys_wait4
    mov rdi, [child_pid_sub]
    lea rsi, [status]
    xor rdx, rdx
    xor r10, r10
    syscall

    ; Получаем код возврата (сумму вычитаемых элементов в положительном виде)
    mov rax, [status]
    mov al, ah              ; код возврата в AH
    movzx rax, al           ; расширяем до 64 бит
    mov [sum_sub], rax

    ; Вычисляем итоговую сумму: sum_add - sum_sub
    mov rax, [sum_add]
    sub rax, [sum_sub]

    ; Выводим результат
    mov rsi, msg_total
    call print_str

    mov rdi, rax
    call print_number
    call new_line

    ; Успешный выход
    mov rax, 60
    xor rdi, rdi
    syscall

.n_error:
    mov rsi, msg_err_args
    call print_str
    jmp exit_error

.fork_error:
    mov rsi, msg_fork_err
    call print_str

exit_error:
    mov rax, 60
    mov rdi, 1
    syscall