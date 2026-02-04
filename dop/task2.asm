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
    board_lock       dd 0      ; Мьютекс для доски
    lamp1_sem        dd 0      ; Семафор лампочки 1
    lamp2_sem        dd 0      ; Семафор лампочки 2
    
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
    header           db 'Лампочки и доска - с отображением зажигания',10
    header_len       = $ - header
    
    board_msg        db 'Доска: '
    board_msg_len    = $ - board_msg
    
    created_msg      db '  Создано: '
    created_msg_len  = $ - created_msg
    
    processed_msg    db '  Обработано: '
    processed_msg_len = $ - processed_msg
    
    lamp1_flash_msg  db '[L1]',0
    lamp1_flash_len  = 4
    lamp2_flash_msg  db '[L2]',0
    lamp2_flash_len  = 4
    
    final_msg        db '=== РЕЗУЛЬТАТ ===',10
    final_msg_len    = $ - final_msg
    
    success_msg      db 'УСПЕХ: Все 20 вспышек учтены!',10
    success_msg_len  = $ - success_msg
    
    fail_msg         db 'ОШИБКА: Доска показывает ',0
    fail_msg2        db ', а должно быть 20',10
    fail_msg2_len    = $ - fail_msg2
    
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

create_flashes:
    ; Случайно выбираем лампочку
    call    random
    and     rax, 1
    jz      flash_lamp1
    
flash_lamp2:
    ; Вспышка L2
    mov     byte [current_lamp], 2  ; Устанавливаем флаг лампочки 2
    
    ; Вспышка L2 - увеличиваем семафор
    mov     eax, 1
    lock xadd [lamp2_sem], eax
    
    ; Будим поток A2
    mov     edi, lamp2_sem
    mov     esi, FUTEX_WAKE or FUTEX_PRIVATE
    mov     edx, 1
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    jmp     flash_done

flash_lamp1:
    ; Вспышка L1
    mov     byte [current_lamp], 1  ; Устанавливаем флаг лампочки 1
    
    ; Вспышка L1 - увеличиваем семафор
    mov     eax, 1
    lock xadd [lamp1_sem], eax
    
    ; Будим поток A1
    mov     edi, lamp1_sem
    mov     esi, FUTEX_WAKE or FUTEX_PRIVATE
    mov     edx, 1
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall

flash_done:
    ; Увеличиваем счетчик созданных вспышек
    lock inc qword [flashes_created]
    
    ; Показываем состояние с информацией о лампочке
    call    show_status_with_lamp
    
    ; Пауза между вспышками
    call    random_delay
    
    dec     r15
    jnz     create_flashes
    
    ; Все 20 вспышек созданы
    ; Ждем пока ВСЕ будут обработаны
    mov     r14, 1000          ; Максимум 1000 попыток

wait_loop:
    mov     rax, [flashes_created]
    mov     rbx, [flashes_processed]
    cmp     rax, rbx
    je      all_processed
    
    ; Короткая пауза
    mov     rdi, 10000000      ; 10ms
    call    delay_ns
    
    dec     r14
    jnz     wait_loop
    
    ; Если слишком долго ждем, выходим
    jmp     force_stop

all_processed:
    ; Все обработано, останавливаем потоки
    mov     dword [stop_threads], 1
    
    ; Будим потоки чтобы они вышли из ожидания
    mov     eax, 1
    lock xadd [lamp1_sem], eax
    mov     edi, lamp1_sem
    mov     esi, FUTEX_WAKE or FUTEX_PRIVATE
    mov     edx, 1
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    
    mov     eax, 1
    lock xadd [lamp2_sem], eax
    mov     edi, lamp2_sem
    mov     esi, FUTEX_WAKE or FUTEX_PRIVATE
    mov     edx, 1
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    
    ; Ждем завершения потоков
    mov     rdi, 200000000     ; 200ms
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
    
    ; "Доска: "
    mov     rsi, board_msg
    mov     rcx, board_msg_len
    rep movsb
    
    ; Число на доске
    mov     rax, [board_number]
    call    num_to_str
    
    mov     al, 10
    stosb
    
    ; "Создано: "
    mov     rsi, created_msg
    mov     rcx, created_msg_len
    rep movsb
    
    ; Количество созданных вспышек
    mov     rax, [flashes_created]
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
    
    ; Ошибка - показываем какое число на доске
    mov     rdi, fail_msg
    mov     rsi, 24
    call    print_string
    
    ; Число с доски
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
    
    ; Вторая часть сообщения
    mov     rdi, fail_msg2
    mov     rsi, fail_msg2_len
    call    print_string
    
    jmp     exit

force_stop:
    ; Принудительная остановка
    mov     dword [stop_threads], 1
    mov     dword [program_active], 0
    
    ; Будим потоки
    mov     eax, 1
    lock xadd [lamp1_sem], eax
    mov     edi, lamp1_sem
    mov     esi, FUTEX_WAKE or FUTEX_PRIVATE
    mov     edx, 1
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    
    mov     eax, 1
    lock xadd [lamp2_sem], eax
    mov     edi, lamp2_sem
    mov     esi, FUTEX_WAKE or FUTEX_PRIVATE
    mov     edx, 1
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    
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
    mov     eax, [stop_threads]
    test    eax, eax
    jnz     a1_exit
    
    ; Ждем вспышку L1
a1_wait:
    ; Проверяем флаг остановки
    mov     eax, [stop_threads]
    test    eax, eax
    jnz     a1_exit
    
    ; Пытаемся взять семафор
    mov     eax, -1
    lock xadd [lamp1_sem], eax
    mov     ebx, eax          ; Старое значение
    
    ; Если было <= 0, то ждем
    cmp     ebx, 0
    jle     a1_sleep
    
    ; Семафор был > 0, обрабатываем
    jmp     a1_process

a1_sleep:
    ; Восстанавливаем семафор
    lock inc dword [lamp1_sem]
    
    ; Еще раз проверяем флаг
    mov     eax, [stop_threads]
    test    eax, eax
    jnz     a1_exit
    
    ; Ожидание
    mov     edi, lamp1_sem
    mov     esi, FUTEX_WAIT or FUTEX_PRIVATE
    mov     edx, ebx
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    jmp     a1_wait

a1_process:
    ; КРИТИЧЕСКАЯ СЕКЦИЯ
    call    lock_board
    
    ; Читаем текущее значение
    mov     rax, [board_number]
    
    ; Задержка внутри критической секции
    push    rax
    call    short_delay
    pop     rax
    
    ; Увеличиваем и записываем
    inc     rax
    mov     [board_number], rax
    
    ; Увеличиваем счетчик обработанных
    lock inc qword [flashes_processed]
    
    ; Показываем, что лампочка 1 обработана
    call    show_processing_status
    mov     byte [current_lamp], 0  ; Сбрасываем флаг
    
    call    unlock_board
    
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
    mov     eax, [stop_threads]
    test    eax, eax
    jnz     a2_exit
    
    ; Ждем вспышку L2
a2_wait:
    ; Проверяем флаг остановки
    mov     eax, [stop_threads]
    test    eax, eax
    jnz     a2_exit
    
    ; Пытаемся взять семафор
    mov     eax, -1
    lock xadd [lamp2_sem], eax
    mov     ebx, eax          ; Старое значение
    
    ; Если было <= 0, то ждем
    cmp     ebx, 0
    jle     a2_sleep
    
    ; Семафор был > 0, обрабатываем
    jmp     a2_process

a2_sleep:
    ; Восстанавливаем семафор
    lock inc dword [lamp2_sem]
    
    ; Еще раз проверяем флаг
    mov     eax, [stop_threads]
    test    eax, eax
    jnz     a2_exit
    
    ; Ожидание
    mov     edi, lamp2_sem
    mov     esi, FUTEX_WAIT or FUTEX_PRIVATE
    mov     edx, ebx
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    jmp     a2_wait

a2_process:
    ; КРИТИЧЕСКАЯ СЕКЦИЯ
    call    lock_board
    
    ; Читаем текущее значение
    mov     rax, [board_number]
    
    ; Задержка внутри критической секции
    push    rax
    call    short_delay
    pop     rax
    
    ; Увеличиваем и записываем
    inc     rax
    mov     [board_number], rax
    
    ; Увеличиваем счетчик обработанных
    lock inc qword [flashes_processed]
    
    ; Показываем, что лампочка 2 обработана
    call    show_processing_status
    mov     byte [current_lamp], 0  ; Сбрасываем флаг
    
    call    unlock_board
    
    jmp     a2_loop

a2_exit:
    xor     edi, edi
    mov     eax, SYS_exit
    syscall

; ==============================================
; Вывод состояния с информацией о лампочке
; ==============================================
show_status_with_lamp:
    push    r15
    push    r14
    push    r13
    
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
    jmp     .no_lamp
    
.lamp1:
    ; "[L1] "
    mov     rsi, lamp1_flash_msg
    mov     rcx, lamp1_flash_len
    rep movsb
    mov     al, ' '
    stosb
    jmp     .add_status
    
.lamp2:
    ; "[L2] "
    mov     rsi, lamp2_flash_msg
    mov     rcx, lamp2_flash_len
    rep movsb
    mov     al, ' '
    stosb

.add_status:
    ; "Доска: "
    mov     rsi, board_msg
    mov     rcx, board_msg_len
    rep movsb
    
    ; Число на доске
    mov     rax, [board_number]
    call    num_to_str
    
    ; "  Создано: "
    mov     rsi, created_msg
    mov     rcx, created_msg_len
    rep movsb
    
    ; Количество созданных вспышек
    mov     rax, [flashes_created]
    call    num_to_str
    
    ; "  Обработано: "
    mov     rsi, processed_msg
    mov     rcx, processed_msg_len
    rep movsb
    
    ; Количество обработанных вспышек
    mov     rax, [flashes_processed]
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
    
.no_lamp:
    pop     r13
    pop     r14
    pop     r15
    ret

; ==============================================
; Показать статус обработки
; ==============================================
show_processing_status:
    push    r15
    push    r14
    
    ; Очищаем буфер
    mov     rdi, buffer
    mov     rcx, 256
    xor     al, al
    rep stosb
    
    ; Формируем строку
    mov     rdi, buffer
    
    ; ">>> Обработка "
    mov     al, '>'
    stosb
    stosb
    stosb
    mov     al, ' '
    stosb
    mov     rsi, board_msg
    mov     rcx, board_msg_len
    rep movsb
    
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
; Мьютекс для доски
; ==============================================
lock_board:
lock_retry:
    ; Пытаемся установить lock в 1
    mov     eax, 1
    xchg    [board_lock], eax
    
    ; Проверяем, был ли lock 0
    test    eax, eax
    jz      lock_acquired
    
    ; Lock был занят, ждем
    mov     edi, board_lock
    mov     esi, FUTEX_WAIT or FUTEX_PRIVATE
    mov     edx, eax          ; Ожидаемое значение (1)
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
    jmp     lock_retry

lock_acquired:
    ret

; ==============================================
; Разблокировка доски
; ==============================================
unlock_board:
    ; Сбрасываем lock в 0
    mov     dword [board_lock], 0
    
    ; Будим одного ждущего
    mov     edi, board_lock
    mov     esi, FUTEX_WAKE or FUTEX_PRIVATE
    mov     edx, 1
    xor     r10, r10
    xor     r8, r8
    mov     eax, SYS_futex
    syscall
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
; Короткая задержка (потоки A1/A2)
; ==============================================
short_delay:
    push    rcx
    call    random
    
    ; Фиксированная короткая задержка: 5-15ms
    mov     rbx, 10000000     ; 10ms диапазон
    xor     rdx, rdx
    div     rbx
    add     rdx, 5000000      ; минимум 5ms
    
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