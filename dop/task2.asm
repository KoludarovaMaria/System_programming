format ELF64 executable 3

; Константы системных вызовов
SYS_exit        = 60
SYS_write       = 1
SYS_nanosleep   = 35
SYS_clone       = 56
SYS_futex       = 202

; Константы для futex
FUTEX_WAIT      = 0
FUTEX_WAKE      = 1
FUTEX_PRIVATE   = 128
CLONE_VM        = 0x00000100
CLONE_FS        = 0x00000200
CLONE_FILES     = 0x00000400
CLONE_SIGHAND   = 0x00000800
CLONE_THREAD    = 0x00010000

; Константы задачи
TOTAL_FLASHES   = 20
MIN_DELAY       = 50000000    ; 50ms
MAX_DELAY       = 150000000   ; 150ms

segment readable writeable
    ; Общие данные
    board_number     dq 0
    
    ; Семафоры
    board_sem        dd 1      ; Семафор для доски (1 - доступна)
    
    ; Счетчики для лампочек
    lamp1_flash      dd 0      ; Счетчик вспышек L1
    lamp2_flash      dd 0      ; Счетчик вспышек L2
    
    ; Переменные для запоминания чисел
    remembered_a1    dq 0      ; Что запомнил A1
    remembered_a2    dq 0      ; Что запомнил A2
    
    ; Для отладки - запоминаем кто последний читал
    last_reader      db 0      ; 1 = A1, 2 = A2
    
    ; Счетчики
    flashes_created  dq 0      ; Сколько вспышек создано
    flashes_processed dq 0     ; Сколько вспышек обработано
    
    ; Флаги управления
    program_active   dd 1      ; 1 = активна, 0 = завершение
    stop_threads     dd 0      ; 1 = остановить потоки
    
    ; Случайное зерно
    seed             dq 123456789
    
    ; Буфер вывода
    buffer           rb 256
    
    ; Сообщения
    header           db '=== Lamps and Board Simulation ===',10
                     db 'Two people (A1 and A2) observe lamps L1 and L2',10
                     db 'Each lamp flash: read board -> turn off -> write board+1',10,10
    header_len       = $ - header
    
    board_msg        db 'Board: '
    board_msg_len    = $ - board_msg
    
    created_msg      db '  Created: '
    created_msg_len  = $ - created_msg
    
    processed_msg    db '  Processed: '
    processed_msg_len = $ - processed_msg
    
    lamp1_flash_msg  db '[L1 FLASH!]',0
    lamp1_flash_len  = 11
    lamp2_flash_msg  db '[L2 FLASH!]',0
    lamp2_flash_len  = 11
    
    final_msg        db 10,'=== FINAL RESULT ===',10
    final_msg_len    = $ - final_msg
    
    success_msg      db 'SUCCESS: All 20 flashes correctly counted!',10
    success_msg_len  = $ - success_msg
    
    fail_msg         db 'ERROR: Board shows ',0
    fail_msg2        db ', should be 20',10
    fail_msg2_len    = $ - fail_msg2
    
    dash_line        db '----------------------------------------',10
    dash_len         = $ - dash_line
    
    newline          db 10
    
    ; Переменные для вывода
    current_lamp     db 0      ; 1 = L1, 2 = L2
    
    ; Стеки потоков
    stack1           rb 8192
    stack1_top:
    
    stack2           rb 8192
    stack2_top:

segment readable executable
entry start

start:
    ; Заголовок
    mov     rdi, header
    mov     rsi, header_len
    call    print_string
    
    ; Создаем поток A1
    mov     rdi, CLONE_VM or CLONE_FS or CLONE_FILES or CLONE_SIGHAND or CLONE_THREAD
    mov     rsi, stack1_top
    xor     rdx, rdx
    xor     r10, r10
    xor     r8, r8
    mov     rax, SYS_clone
    syscall
    
    test    rax, rax
    jz      person_a1
    
    ; Создаем поток A2
    mov     rdi, CLONE_VM or CLONE_FS or CLONE_FILES or CLONE_SIGHAND or CLONE_THREAD
    mov     rsi, stack2_top
    xor     rdx, rdx
    xor     r10, r10
    xor     r8, r8
    mov     rax, SYS_clone
    syscall
    
    test    rax, rax
    jz      person_a2
    
    ; Главный поток - создаем ровно 20 вспышек
    mov     r15, TOTAL_FLASHES
    mov     rdi, dash_line
    mov     rsi, dash_len
    call    print_string

create_flashes:
    ; Случайно выбираем лампочку
    call    random
    and     rax, 1
    jz      flash_lamp1
    
flash_lamp2:
    ; Вспышка L2
    mov     byte [current_lamp], 2  ; Устанавливаем флаг лампочки 2
    lock inc dword [lamp2_flash]    ; Увеличиваем счетчик вспышек L2
    jmp     flash_done

flash_lamp1:
    ; Вспышка L1
    mov     byte [current_lamp], 1  ; Устанавливаем флаг лампочки 1
    lock inc dword [lamp1_flash]    ; Увеличиваем счетчик вспышек L1

flash_done:
    ; Увеличиваем счетчик созданных вспышек
    lock inc qword [flashes_created]
    
    ; Показываем состояние с информацией о лампочке
    call    show_flash_status
    
    ; Пауза между вспышками
    call    random_delay
    
    dec     r15
    jnz     create_flashes
    
    ; Все 20 вспышек созданы
    ; Ждем пока ВСЕ будут обработаны
    mov     rdi, dash_line
    mov     rsi, dash_len
    call    print_string
    
    mov     r14, 2000          ; Максимум 2000 попыток

wait_loop:
    mov     rax, [flashes_created]
    mov     rbx, [flashes_processed]
    cmp     rax, rbx
    je      all_processed
    
    ; Короткая пауза
    mov     rdi, 5000000       ; 5ms
    call    delay_ns
    
    dec     r14
    jnz     wait_loop
    
    ; Если слишком долго ждем, выходим
    jmp     force_stop

all_processed:
    ; Все обработано, останавливаем потоки
    mov     dword [stop_threads], 1
    
    ; Даем время потокам завершиться
    mov     rdi, 100000000     ; 100ms
    call    delay_ns
    
    ; Вывод результата
    mov     rdi, final_msg
    mov     rsi, final_msg_len
    call    print_string
    
    ; Формируем строку результата
    mov     rdi, buffer
    mov     rcx, 256
    xor     al, al
    rep stosb
    
    mov     rdi, buffer
    
    ; "Board: "
    mov     rsi, board_msg
    mov     rcx, board_msg_len
    rep movsb
    
    ; Число на доске
    mov     rax, [board_number]
    call    num_to_str
    
    mov     al, 10
    stosb
    
    ; "Created: "
    mov     rsi, created_msg
    mov     rcx, created_msg_len
    rep movsb
    
    ; Количество созданных вспышек
    mov     rax, [flashes_created]
    call    num_to_str
    
    mov     al, 10
    stosb
    
    ; "Processed: "
    mov     rsi, processed_msg
    mov     rcx, processed_msg_len
    rep movsb
    
    ; Количество обработанных вспышек
    mov     rax, [flashes_processed]
    call    num_to_str
    
    mov     al, 10
    stosb
    
    ; "L1 flashes: "
    mov     rsi, .l1_msg
    mov     rcx, .l1_msg_len
    rep movsb
    
    ; Количество вспышек L1
    mov     eax, [lamp1_flash]
    call    num_to_str
    
    mov     al, 10
    stosb
    
    ; "L2 flashes: "
    mov     rsi, .l2_msg
    mov     rcx, .l2_msg_len
    rep movsb
    
    ; Количество вспышек L2
    mov     eax, [lamp2_flash]
    call    num_to_str
    
    mov     al, 10
    stosb
    
    ; Вычисляем длину
    lea     rax, [buffer]
    sub     rdi, rax
    mov     rsi, rdi
    
    ; Вывод
    mov     rdi, buffer
    call    print_string
    
    ; Проверка корректности
    mov     rax, [board_number]
    cmp     rax, TOTAL_FLASHES
    je      success
    
    ; Ошибка
    mov     rdi, fail_msg
    mov     rsi, 19
    call    print_string
    
    mov     rdi, buffer
    mov     rcx, 256
    xor     al, al
    rep stosb
    
    mov     rdi, buffer
    mov     rax, [board_number]
    call    num_to_str
    
    lea     rax, [buffer]
    sub     rdi, rax
    mov     rsi, rdi
    
    mov     rdi, buffer
    call    print_string
    
    mov     rdi, fail_msg2
    mov     rsi, fail_msg2_len
    call    print_string
    
    jmp     exit

.l1_msg      db 'L1 flashes pending: '
.l1_msg_len  = $ - .l1_msg
.l2_msg      db 'L2 flashes pending: '
.l2_msg_len  = $ - .l2_msg

force_stop:
    ; Принудительная остановка
    mov     dword [stop_threads], 1
    
    jmp     exit

success:
    ; Успех
    mov     rdi, success_msg
    mov     rsi, success_msg_len
    call    print_string

exit:
    xor     edi, edi
    mov     eax, SYS_exit
    syscall

; ==============================================
; Человек A1 (L1)
; ==============================================
person_a1:
a1_loop:
    ; Проверяем флаг остановки
    cmp     dword [stop_threads], 0
    jne     a1_exit
    
    ; Проверяем, была ли вспышка L1
    cmp     dword [lamp1_flash], 0
    je      a1_no_flash
    
    ; Была вспышка - начинаем обработку
    
    ; 1. Берем семафор доски (ждем доступа)
    call    wait_board_sem
    
    ; 2. Читаем число с доски и запоминаем
    mov     rax, [board_number]
    mov     [remembered_a1], rax
    mov     byte [last_reader], 1  ; Отмечаем что A1 читал
    
    ; 3. Показываем что прочитали
    call    show_read_status
    
    ; 4. Освобождаем семафор доски
    call    signal_board_sem
    
    ; 5. Имитация "выключения лампочки" - задержка
    call    random_delay_short
    
    ; 6. Снова берем семафор доски
    call    wait_board_sem
    
    ; 7. Записываем новое значение (запомненное + 1)
    mov     rax, [remembered_a1]
    inc     rax
    mov     [board_number], rax
    
    ; 8. Уменьшаем счетчик вспышек L1
    lock dec dword [lamp1_flash]
    
    ; 9. Увеличиваем счетчик обработанных вспышек
    lock inc qword [flashes_processed]
    
    ; 10. Показываем статус записи
    call    show_write_status
    
    ; 11. Освобождаем семафор доски
    call    signal_board_sem
    
    jmp     a1_loop

a1_no_flash:
    ; Нет вспышек - небольшая пауза перед следующей проверкой
    mov     rdi, 500000        ; 0.5ms
    call    delay_ns
    jmp     a1_loop

a1_exit:
    xor     edi, edi
    mov     eax, SYS_exit
    syscall

; ==============================================
; Человек A2 (L2)
; ==============================================
person_a2:
a2_loop:
    ; Проверяем флаг остановки
    cmp     dword [stop_threads], 0
    jne     a2_exit
    
    ; Проверяем, была ли вспышка L2
    cmp     dword [lamp2_flash], 0
    je      a2_no_flash
    
    ; Была вспышка - начинаем обработку
    
    ; 1. Берем семафор доски (ждем доступа)
    call    wait_board_sem
    
    ; 2. Читаем число с доски и запоминаем
    mov     rax, [board_number]
    mov     [remembered_a2], rax
    mov     byte [last_reader], 2  ; Отмечаем что A2 читал
    
    ; 3. Показываем что прочитали
    call    show_read_status
    
    ; 4. Освобождаем семафор доски
    call    signal_board_sem
    
    ; 5. Имитация "выключения лампочки" - задержка
    call    random_delay_short
    
    ; 6. Снова берем семафор доски
    call    wait_board_sem
    
    ; 7. Записываем новое значение (запомненное + 1)
    mov     rax, [remembered_a2]
    inc     rax
    mov     [board_number], rax
    
    ; 8. Уменьшаем счетчик вспышек L2
    lock dec dword [lamp2_flash]
    
    ; 9. Увеличиваем счетчик обработанных вспышек
    lock inc qword [flashes_processed]
    
    ; 10. Показываем статус записи
    call    show_write_status
    
    ; 11. Освобождаем семафор доски
    call    signal_board_sem
    
    jmp     a2_loop

a2_no_flash:
    ; Нет вспышек - небольшая пауза перед следующей проверкой
    mov     rdi, 500000        ; 0.5ms
    call    delay_ns
    jmp     a2_loop

a2_exit:
    xor     edi, edi
    mov     eax, SYS_exit
    syscall

; ==============================================
; Семафор для доски - ожидание
; ==============================================
wait_board_sem:
wait_sem_retry:
    ; Пытаемся уменьшить семафор с 1 до 0
    mov     eax, -1
    lock xadd [board_sem], eax
    mov     ebx, eax          ; Старое значение
    
    ; Если было > 0, доступ получен
    cmp     ebx, 0
    jg      sem_acquired
    
    ; Если было <= 0, ждем
    lock inc dword [board_sem]  ; Восстанавливаем
    
    ; Ожидание
    mov     edi, board_sem
    mov     esi, FUTEX_WAIT or FUTEX_PRIVATE
    mov     edx, ebx
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    
    jmp     wait_sem_retry

sem_acquired:
    ret

; ==============================================
; Семафор для доски - освобождение
; ==============================================
signal_board_sem:
    ; Увеличиваем семафор
    lock inc dword [board_sem]
    
    ; Будим одного ждущего
    mov     edi, board_sem
    mov     esi, FUTEX_WAKE or FUTEX_PRIVATE
    mov     edx, 1
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    ret

; ==============================================
; Показать статус вспышки
; ==============================================
show_flash_status:
    push    r15
    push    r14
    
    ; Очищаем буфер
    mov     rdi, buffer
    mov     rcx, 256
    xor     al, al
    rep stosb
    
    ; Формируем строку
    mov     rdi, buffer
    
    ; Проверяем, какая лампочка зажглась
    mov     al, [current_lamp]
    cmp     al, 1
    je      .lamp1
    cmp     al, 2
    je      .lamp2
    jmp     .done
    
.lamp1:
    ; "[L1 FLASH!] "
    mov     rsi, lamp1_flash_msg
    mov     rcx, lamp1_flash_len
    rep movsb
    jmp     .add_status
    
.lamp2:
    ; "[L2 FLASH!] "
    mov     rsi, lamp2_flash_msg
    mov     rcx, lamp2_flash_len
    rep movsb

.add_status:
    mov     al, ' '
    stosb
    
    ; "Board: "
    mov     rsi, board_msg
    mov     rcx, board_msg_len
    rep movsb
    
    ; Число на доске
    mov     rax, [board_number]
    call    num_to_str
    
    ; "  Created: "
    mov     rsi, created_msg
    mov     rcx, created_msg_len
    rep movsb
    
    ; Количество созданных вспышек
    mov     rax, [flashes_created]
    call    num_to_str
    
    ; "  Processed: "
    mov     rsi, processed_msg
    mov     rcx, processed_msg_len
    rep movsb
    
    ; Количество обработанных вспышек
    mov     rax, [flashes_processed]
    call    num_to_str
    
    ; Перевод строки
    mov     al, 10
    stosb
    
.done:
    ; Вычисляем длину
    lea     rax, [buffer]
    sub     rdi, rax
    mov     rsi, rdi
    
    ; Выводим
    mov     rdi, buffer
    call    print_string
    
    pop     r14
    pop     r15
    ret

; ==============================================
; Показать статус чтения
; ==============================================
show_read_status:
    push    r15
    push    r14
    
    ; Очищаем буфер
    mov     rdi, buffer
    mov     rcx, 256
    xor     al, al
    rep stosb
    
    ; Формируем строку
    mov     rdi, buffer
    
    mov     al, ' '
    stosb
    stosb
    stosb
    
    ; Кто читает
    cmp     byte [last_reader], 1
    je      .a1_reads
    cmp     byte [last_reader], 2
    je      .a2_reads
    jmp     .unknown
    
.a1_reads:
    mov     al, 'A'
    stosb
    mov     al, '1'
    stosb
    jmp     .continue
    
.a2_reads:
    mov     al, 'A'
    stosb
    mov     al, '2'
    stosb

.unknown:
.continue:
    mov     al, ' '
    stosb
    mov     al, 'r'
    stosb
    mov     al, 'e'
    stosb
    mov     al, 'a'
    stosb
    mov     al, 'd'
    stosb
    stosb
    mov     al, ':'
    stosb
    mov     al, ' '
    stosb
    
    ; Число
    mov     al, [last_reader]
    cmp     al, 1
    je      .show_a1
    cmp     al, 2
    je      .show_a2
    mov     rax, 0
    jmp     .show_num
    
.show_a1:
    mov     rax, [remembered_a1]
    jmp     .show_num
    
.show_a2:
    mov     rax, [remembered_a2]

.show_num:
    call    num_to_str
    
    ; Показать оба запомненных значения (для отладки race condition)
    mov     al, ' '
    stosb
    mov     al, '('
    stosb
    mov     al, 'A'
    stosb
    mov     al, '1'
    stosb
    mov     al, '='
    stosb
    mov     rax, [remembered_a1]
    call    num_to_str
    
    mov     al, ','
    stosb
    mov     al, ' '
    stosb
    mov     al, 'A'
    stosb
    mov     al, '2'
    stosb
    mov     al, '='
    stosb
    mov     rax, [remembered_a2]
    call    num_to_str
    
    mov     al, ')'
    stosb
    
    ; Перевод строки
    mov     al, 10
    stosb
    
    ; Вычисляем длину
    lea     rax, [buffer]
    sub     rdi, rax
    mov     rsi, rdi
    
    ; Выводим
    mov     rdi, buffer
    call    print_string
    
    pop     r14
    pop     r15
    ret

; ==============================================
; Показать статус записи
; ==============================================
show_write_status:
    push    r15
    push    r14
    
    ; Очищаем буфер
    mov     rdi, buffer
    mov     rcx, 256
    xor     al, al
    rep stosb
    
    ; Формируем строку
    mov     rdi, buffer
    
    mov     al, ' '
    stosb
    stosb
    stosb
    
    ; Кто пишет
    cmp     byte [last_reader], 1
    je      .a1_writes
    cmp     byte [last_reader], 2
    je      .a2_writes
    jmp     .unknown
    
.a1_writes:
    mov     al, 'A'
    stosb
    mov     al, '1'
    stosb
    jmp     .continue
    
.a2_writes:
    mov     al, 'A'
    stosb
    mov     al, '2'
    stosb

.unknown:
.continue:
    mov     al, ' '
    stosb
    mov     al, 'w'
    stosb
    mov     al, 'r'
    stosb
    mov     al, 'o'
    stosb
    mov     al, 't'
    stosb
    mov     al, 'e'
    stosb
    mov     al, ':'
    stosb
    mov     al, ' '
    stosb
    
    ; Число на доске
    mov     rax, [board_number]
    call    num_to_str
    
    ; Перевод строки
    mov     al, 10
    stosb
    
    ; Вычисляем длину
    lea     rax, [buffer]
    sub     rdi, rax
    mov     rsi, rdi
    
    ; Выводим
    mov     rdi, buffer
    call    print_string
    
    pop     r14
    pop     r15
    ret

; ==============================================
; Генератор случайных чисел
; ==============================================
random:
    mov     rax, [seed]
    mov     rbx, 1103515245
    mul     rbx
    add     rax, 12345
    mov     [seed], rax
    ret

; ==============================================
; Случайная задержка (главный поток)
; ==============================================
random_delay:
    push    rcx
    call    random
    
    ; Диапазон [MIN_DELAY, MAX_DELAY]
    mov     rbx, MAX_DELAY - MIN_DELAY + 1
    xor     rdx, rdx
    div     rbx
    add     rdx, MIN_DELAY
    
    mov     rdi, rdx
    call    delay_ns
    
    pop     rcx
    ret

; ==============================================
; Короткая случайная задержка (потоки A1/A2)
; ==============================================
random_delay_short:
    push    rcx
    call    random
    
    ; Диапазон 20-100ms
    mov     rbx, 80000000     ; 80ms диапазон
    xor     rdx, rdx
    div     rbx
    add     rdx, 20000000     ; минимум 20ms
    
    mov     rdi, rdx
    call    delay_ns
    
    pop     rcx
    ret

; ==============================================
; Задержка в наносекундах
; ==============================================
delay_ns:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16
    
    xor     rax, rax
    mov     [rsp], rax        ; seconds
    mov     [rsp+8], rdi      ; nanoseconds
    
    mov     rdi, rsp          ; req
    xor     rsi, rsi          ; rem = NULL
    mov     rax, SYS_nanosleep
    syscall
    
    mov     rsp, rbp
    pop     rbp
    ret

; ==============================================
; Преобразование числа в строку
; ==============================================
num_to_str:
    push    rbx
    push    rcx
    push    rdx
    
    ; Создаем временный буфер на стеке
    sub     rsp, 32
    mov     rbx, rsp
    add     rbx, 31
    mov     byte [rbx], 0
    
    ; Особый случай: 0
    test    rax, rax
    jnz     .convert
    
    dec     rbx
    mov     byte [rbx], '0'
    jmp     .copy_to_output

.convert:
    mov     rcx, 10
.convert_loop:
    xor     rdx, rdx
    div     rcx
    add     dl, '0'
    dec     rbx
    mov     [rbx], dl
    test    rax, rax
    jnz     .convert_loop

.copy_to_output:
    ; Копируем из временного буфера в выходной
    mov     rsi, rbx
.copy_loop:
    mov     al, [rsi]
    test    al, al
    jz      .done
    mov     [rdi], al
    inc     rdi
    inc     rsi
    jmp     .copy_loop

.done:
    add     rsp, 32
    pop     rdx
    pop     rcx
    pop     rbx
    ret

; ==============================================
; Вывод строки
; ==============================================
print_string:
    push    rdx
    mov     rdx, rsi
    mov     rsi, rdi
    mov     rdi, 1
    mov     rax, SYS_write
    syscall
    pop     rdx
    ret