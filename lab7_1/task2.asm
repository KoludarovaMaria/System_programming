format ELF64
public _start

; Константы
SYS_READ    = 0
SYS_WRITE   = 1
SYS_MMAP    = 9
SYS_MUNMAP  = 11
SYS_FORK    = 57
SYS_EXIT    = 60
SYS_WAIT4   = 61
SYS_NANOSLEEP = 35

STDOUT      = 1
PROT_READ   = 0x1
PROT_WRITE  = 0x2
MAP_SHARED  = 0x01
MAP_ANONY   = 0x20

; Вариант 889
COUNT       = 889          ; Исправлено: 889 чисел
ARRAY_SIZE  = 4 + (COUNT * 4)

section '.data' writeable
    msg_start       db "Массив из 889 чисел заполнен.", 10, 0
    msg_start_len   = $ - msg_start

    msg_task0:
        db "[Процесс 1] 0.75 квантиль: ", 0
    len_0 = $ - msg_task0

    msg_task1:
        db "[Процесс 2] Количество чисел кратных пяти: ", 0
    len_1 = $ - msg_task1

    msg_task2:
        db "[Процесс 3] Количество чисел, сумма цифр которых кратна 3: ", 0
    len_2 = $ - msg_task2

    msg_task3:
        db "[Процесс 4] Наиболее часто встречающаяся цифра в случайных числах: ", 0
    len_3 = $ - msg_task3

    newline         db 10, 0
    space           db " ", 0

    array_ptr       dq 0
    data_ptr        dq 0
    seed            dd 889        ; Инициализируем сид вариантом

    num_buffer      rb 20

    timespec:
        tv_sec      dq 0
        tv_nsec     dq 1000000

section '.text' executable
_start:
    ; 1. Выделение памяти
    mov rax, SYS_MMAP
    xor edi, edi               ; Адрес выбирает ОС
    mov rsi, ARRAY_SIZE        ; Размер памяти
    mov rdx, PROT_READ or PROT_WRITE
    mov r10, MAP_SHARED or MAP_ANONY
    mov r8, -1
    xor r9, r9
    syscall

    cmp rax, 0
    jl exit_error

    mov [array_ptr], rax
    mov dword [rax], 0
    lea rbx, [rax + 4]
    mov [data_ptr], rbx

    ; 2. Заполнение массива 889 случайными числами
    mov rdi, [data_ptr]
    mov rcx, COUNT
fill_loop:
    call rand
    mov [rdi], eax
    add rdi, 4
    loop fill_loop

    ; Сообщение о заполнении
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, msg_start
    mov rdx, msg_start_len
    syscall

    ; 3. Создание 4 процессов
    xor r15, r15               ; Номер процесса
fork_loop:
    cmp r15, 4
    je wait_children

    mov rax, SYS_FORK
    syscall

    test rax, rax
    js exit_error
    jz child_process           ; Ветка потомка

    inc r15
    jmp fork_loop

child_process:
    ; Определяем какое задание выполнять по номеру процесса
    cmp r15, 0
    je task_quantile_75
    cmp r15, 1
    je task_multiples_of_five
    cmp r15, 2
    je task_sum_digits_divisible_by_3
    cmp r15, 3
    je task_most_frequent_digit
    jmp child_exit

; ==============================================
; ЗАДАЧА 1: 0.75 квантиль
; ==============================================
task_quantile_75:
    ; Копируем массив в локальную память для сортировки
    mov rdx, COUNT
    shl rdx, 2                  ; rdx = COUNT * 4
    sub rsp, rdx
    and rsp, -16                ; Выравнивание стека

    mov rdi, rsp
    mov rsi, [data_ptr]
    mov rcx, COUNT
    rep movsd

    ; Сортируем копию массива
    mov rdi, rsp
    mov rcx, COUNT
    call bubble_sort

    ; Вычисляем позицию 0.75 квантиля
    ; Формула: position = 0.75 * (n - 1)
    mov rax, COUNT
    dec rax                     ; n - 1
    mov rbx, 75                 ; Для умножения на 0.75 (75/100)
    mul rbx                     ; rax = 75*(n-1)
    
    ; Делим на 100
    mov rbx, 100
    xor rdx, rdx
    div rbx                     ; rax = позиция, rdx = остаток
    
    ; Округляем вверх если остаток > 0
    test rdx, rdx
    jz .get_value
    inc rax
    
.get_value:
    ; Получаем значение по индексу
    mov ebx, [rsp + rax*4]
    mov r14, rbx                ; Сохраняем результат

    ; Освобождаем стек
    mov rdx, COUNT
    shl rdx, 2
    add rsp, rdx

    call wait_my_turn
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, msg_task0
    mov rdx, len_0
    syscall
    mov rax, r14
    call print_num
    call print_newline
    call pass_turn
    jmp child_exit

; ==============================================
; ЗАДАЧА 2: Количество чисел кратных пяти
; ==============================================
task_multiples_of_five:
    mov rsi, [data_ptr]
    mov rcx, COUNT
    xor rbx, rbx                ; Счетчик
    
.count_loop:
    lodsd                       ; eax = текущее число
    ; Проверяем кратность 5
    test eax, eax
    jz .is_multiple             ; 0 кратен любому числу
    
    ; Берем модуль числа
    mov edx, eax
    test edx, edx
    jns .positive
    neg edx
.positive:
    
    ; Делим на 5
    mov eax, edx
    xor edx, edx
    mov r8d, 5
    div r8d
    test edx, edx               ; Проверяем остаток
    jnz .next
.is_multiple:
    inc rbx
.next:
    loop .count_loop

    mov r14, rbx

    call wait_my_turn
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, msg_task1
    mov rdx, len_1
    syscall
    mov rax, r14
    call print_num
    call print_newline
    call pass_turn
    jmp child_exit

; ==============================================
; ЗАДАЧА 3: Количество чисел, сумма цифр которых кратна 3
; ==============================================
task_sum_digits_divisible_by_3:
    mov rsi, [data_ptr]
    mov rcx, COUNT
    xor rbx, rbx                ; Счетчик
    
.scan:
    push rcx
    lodsd
    call sum_of_digits          ; Получаем сумму цифр
    test eax, eax
    jz .divisible               ; 0 кратен 3
    
    ; Проверяем кратность 3
    xor edx, edx
    mov r8d, 3
    div r8d
    test edx, edx
    jnz .not_divisible
.divisible:
    inc rbx
.not_divisible:
    pop rcx
    loop .scan

    mov r14, rbx

    call wait_my_turn
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, msg_task2
    mov rdx, len_2
    syscall
    mov rax, r14
    call print_num
    call print_newline
    call pass_turn
    jmp child_exit

; ==============================================
; ЗАДАЧА 4: Наиболее часто встречающаяся цифра
; ==============================================
task_most_frequent_digit:
    ; Выделяем память под счетчики цифр (10 чисел по 8 байт)
    sub rsp, 80
    mov rdi, rsp
    call count_digits           ; Подсчитываем частоту цифр

    ; Ищем цифру с максимальной частотой
    mov rcx, 0
    mov rbx, -1                 ; Максимальная частота
    mov rdx, -1                 ; Цифра с максимальной частотой
    
.find_max:
    cmp rcx, 10
    je .print_result
    mov rax, [rsp + rcx*8]
    cmp rax, rbx
    jle .next_digit
    mov rbx, rax
    mov rdx, rcx
.next_digit:
    inc rcx
    jmp .find_max

.print_result:
    mov r14, rdx                ; Сохраняем цифру
    add rsp, 80

    call wait_my_turn
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, msg_task3
    mov rdx, len_3
    syscall
    mov rax, r14
    call print_num
    call print_newline
    call pass_turn
    jmp child_exit

child_exit:
    mov rax, SYS_EXIT
    xor edi, edi
    syscall

; ==============================================
; Ожидание завершения всех процессов
; ==============================================
wait_children:
.wait_loop:
    mov rax, SYS_WAIT4
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    cmp rax, 0
    jg .wait_loop

    ; Освобождаем память
    mov rax, SYS_MUNMAP
    mov rdi, [array_ptr]
    mov rsi, ARRAY_SIZE
    syscall

    mov rax, SYS_EXIT
    xor edi, edi
    syscall

exit_error:
    mov rax, SYS_EXIT
    mov edi, 1
    syscall

; ==============================================
; ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
; ==============================================

; Сортировка пузырьком
bubble_sort:
    cmp rcx, 1
    jle .return
    dec rcx
.outer_loop:
    push rcx
    mov rsi, rdi
.inner_loop:
    mov eax, [rsi]
    mov ebx, [rsi+4]
    cmp eax, ebx
    jle .no_swap
    mov [rsi], ebx
    mov [rsi+4], eax
.no_swap:
    add rsi, 4
    loop .inner_loop
    pop rcx
    loop .outer_loop
.return:
    ret

; Генератор случайных чисел от 0 до 99999
rand:
    mov eax, [seed]
    mov edx, 1103515245
    imul edx
    add eax, 12345
    mov [seed], eax
    ; Получаем число от 0 до 99999
    xor edx, edx
    mov ebx, 100000
    div ebx
    mov eax, edx                ; Остаток - наше случайное число
    ret

; Подсчет суммы цифр числа
sum_of_digits:
    push rbx
    push rcx
    xor ebx, ebx                ; Сумма цифр
    mov ecx, eax
    test ecx, ecx
    jns .positive
    neg ecx                     ; Берем модуль для отрицательных
.positive:
.calc_loop:
    test ecx, ecx
    jz .done
    xor edx, edx
    mov eax, ecx
    mov r8d, 10
    div r8d                     ; eax = частное, edx = цифра
    add ebx, edx
    mov ecx, eax
    jmp .calc_loop
.done:
    mov eax, ebx
    pop rcx
    pop rbx
    ret

; Подсчет частоты цифр во всех числах
count_digits:
    push rdi
    ; Обнуляем счетчики
    mov rcx, 10
    xor rax, rax
    rep stosq
    pop rdi                     ; rdi теперь указывает на начало массива счетчиков

    mov rsi, [data_ptr]
    mov rcx, COUNT
.process_number:
    lodsd
    test eax, eax
    jz .process_zero
    
    ; Для положительных чисел
    mov r8d, eax
    jmp .extract_digits

.process_zero:
    inc qword [rdi]             ; Цифра 0
    jmp .next_number

.extract_digits:
    test r8d, r8d
    jz .next_number
    xor edx, edx
    mov eax, r8d
    mov r9d, 10
    div r9d                     ; eax = частное, edx = цифра
    mov r8d, eax
    inc qword [rdi + rdx*8]
    jmp .extract_digits

.next_number:
    loop .process_number
    ret

; Ожидание своей очереди для вывода
wait_my_turn:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
.check_turn:
    mov rbx, [array_ptr]
    mov ecx, [rbx]              ; Текущий номер процесса, который может выводить
    cmp ecx, r15d
    je .can_print
    ; Ждем немного
    mov rax, SYS_NANOSLEEP
    mov rdi, timespec
    xor rsi, rsi
    syscall
    jmp .check_turn
.can_print:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

; Передача очереди следующему процессу
pass_turn:
    push rbx
    mov rbx, [array_ptr]
    lock inc dword [rbx]        ; Атомарное увеличение
    pop rbx
    ret

; Печать числа
print_num:
    push rbx
    push rcx
    push rdx
    push rsi
    
    lea rsi, [num_buffer + 19]
    mov byte [rsi], 0
    mov rbx, 10
    
    test rax, rax
    jns .convert
    neg rax
    push rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rdx, 1
    mov rsi, '-'
    push rsi
    mov rsi, rsp
    syscall
    pop rsi
    pop rax
    
.convert:
    dec rsi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz .convert
    
    ; Вывод строки
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rdx, [num_buffer + 19]
    sub rdx, rsi
    syscall
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

print_newline:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, newline
    mov rdx, 1
    syscall
    ret