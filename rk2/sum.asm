format ELF64 executable 3

entry start

; Константы для системных вызовов
SYS_WRITE = 1
SYS_EXIT = 60
SYS_FORK = 57
SYS_WAIT4 = 61
SYS_PIPE = 22
SYS_READ = 0
SYS_CLOSE = 3
STDOUT = 1

segment readable executable

start:
    ; Получаем аргументы командной строки
    pop rcx                 ; argc
    cmp rcx, 2
    jl usage_error

    ; Пропускаем argv[0]
    pop rdi                 ; argv[0] - имя программы
    pop rdi                 ; argv[1] - строка с N
    call atoi64
    mov [N], rax

    ; Создаем pipe для первого дочернего процесса
    mov rax, SYS_PIPE
    mov rdi, pipe1
    syscall
    test rax, rax
    jnz pipe_error

    ; Создаем pipe для второго дочернего процесса
    mov rax, SYS_PIPE
    mov rdi, pipe2
    syscall
    test rax, rax
    jnz pipe_error

    ; Создаем первый дочерний процесс (для сложения)
    mov rax, SYS_FORK
    syscall

    cmp rax, 0
    jl fork_error
    jz child1               ; Если 0 - мы в дочернем процессе
    
    mov [child_pid1], rax   ; Сохраняем PID
    
    ; Закрываем неиспользуемые концы pipe в родительском процессе
    ; Для pipe1: закрываем write конец (родитель будет только читать)
    mov rax, SYS_CLOSE
    mov edi, [pipe1+4]      ; pipe1[1] - write end (32-bit)
    syscall
    
    ; Для pipe2: закрываем write конец
    mov rax, SYS_CLOSE
    mov edi, [pipe2+4]      ; pipe2[1] - write end (32-bit)
    syscall

    ; Создаем второй дочерний процесс (для вычитания)
    mov rax, SYS_FORK
    syscall

    cmp rax, 0
    jl fork_error
    jz child2               ; Если 0 - мы в дочернем процессе
    
    mov [child_pid2], rax   ; Сохраняем PID

    ; Родительский процесс читает результаты из pipe
    call read_results
    
    ; Выводим результат
    push rax
    mov rsi, msg_sum
    mov rdx, msg_sum_len
    call print_string
    pop rax

    call print_number
    call print_newline

    ; Завершаем программу
    jmp exit_program

fork_error:
    mov rsi, fork_err_msg
    mov rdx, fork_err_len
    call print_string
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

pipe_error:
    mov rsi, pipe_err_msg
    mov rdx, pipe_err_len
    call print_string
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

; ============================================
; Первый дочерний процесс - сумма прибавляемых элементов
; ============================================
child1:
    ; В дочернем процессе закрываем read конец pipe1
    mov rax, SYS_CLOSE
    mov edi, [pipe1]        ; pipe1[0] - read end (32-bit)
    syscall
    
    ; Также закрываем оба конца pipe2 (нам не нужен)
    mov rax, SYS_CLOSE
    mov edi, [pipe2]        ; pipe2[0] - read end (32-bit)
    syscall
    mov rax, SYS_CLOSE
    mov edi, [pipe2+4]      ; pipe2[1] - write end (32-bit)
    syscall

    mov r8, 0               ; i = 0
    xor r9, r9              ; сумма прибавляемых = 0
    mov r10, [N]            ; N

add_loop:
    cmp r8, r10
    jg child1_done

    ; Определяем паттерн: + + - - + + - - ...
    mov rax, r8
    mov rbx, 4
    xor rdx, rdx
    div rbx                 ; rdx = i % 4

    ; Если остаток 0 или 1 - прибавляем
    cmp rdx, 0
    je do_add
    cmp rdx, 1
    je do_add
    jmp next_add_item

do_add:
    add r9, r8

next_add_item:
    inc r8
    jmp add_loop

child1_done:
    ; Записываем результат в pipe1
    mov [r9_result], r9     ; сохраняем результат
    mov rax, SYS_WRITE
    mov edi, [pipe1+4]      ; pipe1[1] - write end (32-bit)
    mov rsi, r9_result
    mov rdx, 8              ; 8 байт (64-битное число)
    syscall
    
    ; Закрываем write конец pipe1
    mov rax, SYS_CLOSE
    mov edi, [pipe1+4]      ; pipe1[1] - write end (32-bit)
    syscall
    
    ; Завершаем процесс
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; ============================================
; Второй дочерний процесс - сумма вычитаемых элементов
; ============================================
child2:
    ; В дочернем процессе закрываем read конец pipe2
    mov rax, SYS_CLOSE
    mov edi, [pipe2]        ; pipe2[0] - read end (32-bit)
    syscall
    
    ; Также закрываем оба конца pipe1 (нам не нужен)
    mov rax, SYS_CLOSE
    mov edi, [pipe1]        ; pipe1[0] - read end (32-bit)
    syscall
    mov rax, SYS_CLOSE
    mov edi, [pipe1+4]      ; pipe1[1] - write end (32-bit)
    syscall

    mov r8, 0               ; i = 0
    xor r9, r9              ; сумма вычитаемых = 0
    mov r10, [N]            ; N

sub_loop:
    cmp r8, r10
    jg child2_done

    ; Определяем паттерн: + + - - + + - - ...
    mov rax, r8
    mov rbx, 4
    xor rdx, rdx
    div rbx                 ; rdx = i % 4

    ; Если остаток 2 или 3 - вычитаем (складываем в отдельную сумму)
    cmp rdx, 2
    je do_sub
    cmp rdx, 3
    je do_sub
    jmp next_sub_item

do_sub:
    add r9, r8

next_sub_item:
    inc r8
    jmp sub_loop

child2_done:
    ; Записываем результат в pipe2
    mov [r9_result2], r9    ; сохраняем результат
    mov rax, SYS_WRITE
    mov edi, [pipe2+4]      ; pipe2[1] - write end (32-bit)
    mov rsi, r9_result2
    mov rdx, 8              ; 8 байт (64-битное число)
    syscall
    
    ; Закрываем write конец pipe2
    mov rax, SYS_CLOSE
    mov edi, [pipe2+4]      ; pipe2[1] - write end (32-bit)
    syscall
    
    ; Завершаем процесс
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; ============================================
; Чтение результатов из pipe
; ============================================
read_results:
    xor r12, r12            ; sum_add
    xor r13, r13            ; sum_sub
    
    ; Читаем результат из первого pipe
    mov rax, SYS_READ
    mov edi, [pipe1]        ; pipe1[0] - read end (32-bit)
    mov rsi, buffer1
    mov rdx, 8
    syscall
    
    mov r12, [buffer1]      ; sum_add
    
    ; Закрываем read конец первого pipe
    mov rax, SYS_CLOSE
    mov edi, [pipe1]        ; pipe1[0] - read end (32-bit)
    syscall
    
    ; Читаем результат из второго pipe
    mov rax, SYS_READ
    mov edi, [pipe2]        ; pipe2[0] - read end (32-bit)
    mov rsi, buffer2
    mov rdx, 8
    syscall
    
    mov r13, [buffer2]      ; sum_sub
    
    ; Закрываем read конец второго pipe
    mov rax, SYS_CLOSE
    mov edi, [pipe2]        ; pipe2[0] - read end (32-bit)
    syscall
    
    ; Ждем завершения дочерних процессов
    mov rax, SYS_WAIT4
    mov rdi, [child_pid1]
    mov rsi, status
    xor rdx, rdx
    xor r10, r10
    syscall
    
    mov rax, SYS_WAIT4
    mov rdi, [child_pid2]
    mov rsi, status
    xor rdx, rdx
    xor r10, r10
    syscall
    
    ; Вычисляем итоговую сумму
    mov rax, r12
    sub rax, r13
    ret

; ============================================
; Вспомогательные процедуры
; ============================================

; Преобразование строки в число (atoi)
; Вход: rdi = указатель на строку
; Выход: rax = число
atoi64:
    xor rax, rax            ; обнуляем результат
    xor rcx, rcx            ; обнуляем счётчик

atoi_loop:
    movzx rbx, byte [rdi+rcx] ; получаем очередной символ
    test rbx, rbx           ; конец строки?
    jz atoi_done

    cmp bl, '0'
    jb atoi_done
    cmp bl, '9'
    ja atoi_done

    sub bl, '0'             ; преобразуем ASCII в цифру
    imul rax, 10            ; умножаем текущий результат на 10
    add rax, rbx            ; добавляем новую цифру

    inc rcx                 ; переходим к следующему символу
    jmp atoi_loop

atoi_done:
    ret

; Вывод строки
; Вход: rsi = указатель на строку, rdx = длина
print_string:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

; Вывод числа
; Вход: rax = число
print_number:
    ; Сохраняем регистры
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    ; Проверяем на отрицательное число
    test rax, rax
    jns .positive
    neg rax
    push rax
    mov rsi, minus_sign
    mov rdx, 1
    call print_string
    pop rax

.positive:
    ; Преобразуем число в строку
    lea rdi, [buffer + 31]  ; начинаем с конца буфера
    mov byte [rdi], 0       ; терминатор строки
    mov rbx, 10             ; делитор

.convert_loop:
    dec rdi                 ; двигаемся назад по буферу
    xor rdx, rdx            ; очищаем rdx перед делением
    div rbx                 ; rax = rax/10, rdx = остаток
    add dl, '0'             ; преобразуем цифру в ASCII
    mov [rdi], dl           ; сохраняем символ

    test rax, rax           ; проверяем, закончилось ли число
    jnz .convert_loop

    ; Выводим строку
    mov rsi, rdi
    mov rdx, buffer + 32
    sub rdx, rsi            ; вычисляем длину строки
    call print_string

    ; Восстанавливаем регистры
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

; Вывод новой строки
print_newline:
    mov rsi, newline
    mov rdx, 1
    call print_string
    ret

; Обработка ошибки использования
usage_error:
    mov rsi, usage_msg
    mov rdx, usage_msg_len
    call print_string
    mov rax, SYS_EXIT
    mov rdi, 1              ; код ошибки
    syscall

; Выход из программы
exit_program:
    mov rax, SYS_EXIT
    xor rdi, rdi            ; код успешного завершения
    syscall

; ============================================
; Сегмент данных
; ============================================
segment readable writeable

; Данные программы
N            dq 0
child_pid1   dq 0
child_pid2   dq 0
status       dq 0

; Pipe дескрипторы
; pipe[0] - read end, pipe[1] - write end (32-bit каждый)
pipe1        dd 0, 0
pipe2        dd 0, 0

; Буферы для данных
buffer       rb 32          ; буфер для преобразования чисел
buffer1      dq 0           ; буфер для результата из pipe1
buffer2      dq 0           ; буфер для результата из pipe2
r9_result    dq 0           ; временное хранение результата child1
r9_result2   dq 0           ; временное хранение результата child2

; Сообщения
usage_msg     db "Usage: ./sum N", 10
usage_msg_len = $ - usage_msg

fork_err_msg  db "Error creating process", 10
fork_err_len  = $ - fork_err_msg

pipe_err_msg  db "Error creating pipe", 10
pipe_err_len  = $ - pipe_err_msg

msg_sum       db "Total sum: ", 0
msg_sum_len   = $ - msg_sum - 1  ; минус терминатор

newline       db 10
minus_sign    db "-"