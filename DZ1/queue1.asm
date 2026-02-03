format ELF64

section '.text' executable

; Экспортируем функции
public queue_create
public queue_destroy
public queue_enqueue
public queue_dequeue
public queue_fill_random
public queue_remove_even
public queue_count_ends_with_one
public queue_get_odd_numbers

; Импортируем из libc
extrn malloc
extrn free

; Структура Queue:
;   data:       8 bytes (pointer)
;   capacity:   8 bytes
;   front:      8 bytes
;   rear:      8 bytes
;   size:       8 bytes
;   min_capacity: 8 bytes

; Константы
MIN_CAPACITY = 4
GROW_FACTOR = 2
SHRINK_THRESHOLD = 4

; Константы для ГПСЧ
RAND_A = 1103515245
RAND_C = 12345
RAND_MOD = 0x7FFFFFFF

section '.data' writeable
rand_seed dq 1  ; начальное значение seed

section '.text' executable

; Внутренняя функция: ГПСЧ на ассемблере
my_rand:
    ; Xn+1 = (a * Xn + c) mod m
    mov     rax, [rand_seed]
    mov     rcx, RAND_A
    mul     rcx              ; a * Xn
    add     rax, RAND_C      ; + c
    adc     rdx, 0
    mov     rcx, RAND_MOD
    div     rcx              ; (a*Xn + c) / m
    mov     [rand_seed], rdx ; остаток - новое seed
    mov     rax, rdx         ; возвращаем случайное число
    ret

; Внутренняя функция: инициализация ГПСЧ
init_random:
    ; Используем счётчик времени процессора
    rdtsc                   ; читаем Time Stamp Counter
    shl     rdx, 32
    or      rax, rdx
    mov     [rand_seed], rax
    ret

; Queue* queue_create(size_t initial_capacity)
queue_create:
    push    rbx
    push    r12
    
    ; Проверяем и корректируем начальную емкость
    mov     r12, rdi
    cmp     r12, MIN_CAPACITY
    jge     .valid_cap
    mov     r12, MIN_CAPACITY
    
.valid_cap:
    ; Выделяем память под структуру Queue (48 байт)
    mov     rdi, 48
    call    malloc
    test    rax, rax
    jz      .error
    
    mov     rbx, rax        ; сохраняем указатель на структуру
    
    ; Выделяем память под данные
    mov     rdi, r12
    shl     rdi, 2          ; * sizeof(int32_t)
    call    malloc
    test    rax, rax
    jz      .free_struct
    
    ; Инициализируем структуру
    mov     [rbx], rax              ; data
    mov     [rbx + 8], r12          ; capacity
    mov     qword [rbx + 16], 0     ; front
    mov     qword [rbx + 24], 0     ; rear
    mov     qword [rbx + 32], 0     ; size
    mov     qword [rbx + 40], MIN_CAPACITY ; min_capacity
    
    ; Инициализируем генератор случайных чисел
    call    init_random
    
    mov     rax, rbx
    jmp     .done
    
.free_struct:
    mov     rdi, rbx
    call    free
.error:
    xor     rax, rax
.done:
    pop     r12
    pop     rbx
    ret

; void queue_destroy(Queue* q)
queue_destroy:
    push    rbx
    
    test    rdi, rdi
    jz      .exit
    
    mov     rbx, rdi
    
    ; Освобождаем данные
    mov     rdi, [rbx]
    call    free
    
    ; Освобождаем структуру
    mov     rdi, rbx
    call    free
    
.exit:
    pop     rbx
    ret

; Внутренняя функция: перераспределение памяти
; bool queue_reallocate(Queue* q, size_t new_capacity)
queue_reallocate:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    
    mov     rbx, rdi        ; q
    mov     r12, rsi        ; new_capacity
    
    ; Проверяем, что new_capacity >= size
    cmp     rsi, [rdi + 32]
    jl      .failure
    
    ; Создаем новый массив
    mov     rdi, r12
    shl     rdi, 2
    call    malloc
    test    rax, rax
    jz      .failure
    
    mov     r13, rax        ; новый массив
    mov     r14, [rbx]      ; старый массив
    mov     r15, [rbx + 32] ; size
    
    ; Копируем элементы
    mov     rcx, r15        ; счетчик
    mov     r8, [rbx + 16]  ; front
    mov     r9, [rbx + 8]   ; старая capacity
    
    xor     r10, r10        ; индекс в новом массиве
    
.copy_loop:
    test    rcx, rcx
    jz      .copy_done
    
    ; Копируем элемент
    mov     eax, [r14 + r8*4]
    mov     [r13 + r10*4], eax
    
    ; Увеличиваем индексы
    inc     r8
    cmp     r8, r9
    jl      .no_wrap_old
    xor     r8, r8
.no_wrap_old:
    inc     r10
    dec     rcx
    jmp     .copy_loop
    
.copy_done:
    ; Освобождаем старый массив
    mov     rdi, r14
    call    free
    
    ; Обновляем структуру
    mov     [rbx], r13           ; data
    mov     [rbx + 8], r12       ; capacity
    mov     qword [rbx + 16], 0  ; front
    mov     [rbx + 24], r15      ; rear
    
    mov     rax, 1
    jmp     .exit
    
.failure:
    xor     rax, rax
.exit:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; bool queue_enqueue(Queue* q, int32_t value)
queue_enqueue:
    push    rbx
    push    r12
    
    mov     rbx, rdi
    mov     r12d, esi
    
    ; Проверяем, нужно ли увеличить емкость
    mov     rax, [rdi + 32]
    cmp     rax, [rdi + 8]
    jl      .has_space
    
    ; Увеличиваем емкость
    mov     rdi, rbx
    mov     rsi, [rbx + 8]
    shl     rsi, 1
    call    queue_reallocate
    test    rax, rax
    jz      .failure
    
.has_space:
    ; Добавляем элемент
    mov     rcx, [rbx]
    mov     rdx, [rbx + 24]
    
    mov     [rcx + rdx*4], r12d
    
    ; Обновляем rear
    inc     rdx
    cmp     rdx, [rbx + 8]
    jl      .no_wrap
    xor     rdx, rdx
.no_wrap:
    mov     [rbx + 24], rdx
    
    ; Увеличиваем size
    inc     qword [rbx + 32]
    
    mov     rax, 1
    jmp     .exit
    
.failure:
    xor     rax, rax
.exit:
    pop     r12
    pop     rbx
    ret

; bool queue_dequeue(Queue* q, int32_t *value)
queue_dequeue:
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi
    mov     r12, rsi
    
    ; Проверяем, не пуста ли очередь
    cmp     qword [rdi + 32], 0
    je      .fail_empty
    
    ; Получаем элемент
    mov     rcx, [rbx]
    mov     rdx, [rbx + 16]
    
    mov     eax, [rcx + rdx*4]
    test    r12, r12
    jz      .no_store
    mov     [r12], eax
    
.no_store:
    ; Обновляем front
    inc     rdx
    cmp     rdx, [rbx + 8]
    jl      .no_wrap
    xor     rdx, rdx
.no_wrap:
    mov     [rbx + 16], rdx
    
    ; Уменьшаем size
    dec     qword [rbx + 32]
    
    ; Проверяем, нужно ли уменьшить емкость
    mov     r13, [rbx + 32] ; size
    mov     r14, [rbx + 8]  ; capacity
    
    ; Если capacity > min_capacity И size <= capacity/4
    cmp     r14, [rbx + 40]
    jle     .no_shrink
    
    mov     rcx, r14
    shr     rcx, 2
    cmp     r13, rcx
    jg      .no_shrink
    
    ; Уменьшаем емкость
    mov     rax, r13
    shl     rax, 1
    cmp     rax, [rbx + 40]
    jge     .new_cap_ok
    mov     rax, [rbx + 40]
    
.new_cap_ok:
    cmp     rax, r14
    jge     .no_shrink
    
    mov     rdi, rbx
    mov     rsi, rax
    call    queue_reallocate
    
.no_shrink:
    mov     rax, 1
    jmp     .exit
    
.fail_empty:
    xor     rax, rax
.exit:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; void queue_fill_random(Queue* q, size_t count, int32_t min_val, int32_t max_val)
queue_fill_random:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    
    mov     rbx, rdi        ; q
    mov     r12, rsi        ; count
    mov     r13d, edx       ; min_val
    mov     r14d, ecx       ; max_val
    
    ; Вычисляем range
    mov     r15d, r14d
    sub     r15d, r13d
    inc     r15d
    
.fill_loop:
    test    r12, r12
    jz      .done
    
    ; Генерируем случайное число
    call    my_rand
    
    ; Приводим к диапазону
    xor     rdx, rdx
    mov     ecx, r15d
    div     rcx
    
    mov     eax, edx
    add     eax, r13d
    
    ; Добавляем в очередь
    mov     rdi, rbx
    mov     esi, eax
    push    r12
    push    r13
    push    r14
    push    r15
    call    queue_enqueue
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    
    dec     r12
    jmp     .fill_loop
    
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; void queue_remove_even(Queue* q)
queue_remove_even:
    push    rbx
    push    r12
    push    r13
    
    mov     rbx, rdi
    
    ; Получаем текущий размер
    mov     r12, [rbx + 32]
    test    r12, r12
    jz      .done
    
    mov     r13, r12
    
.process_loop:
    test    r13, r13
    jz      .done
    
    ; Извлекаем элемент
    mov     rdi, rbx
    sub     rsp, 16
    mov     rsi, rsp
    call    queue_dequeue
    test    rax, rax
    jz      .cleanup
    
    ; Получаем значение
    mov     eax, [rsp]
    
    ; Проверяем, четное ли
    test    eax, 1
    jnz     .is_odd
    
    ; Четное - не добавляем обратно
    add     rsp, 16
    jmp     .continue
    
.is_odd:
    ; Нечетное - добавляем обратно
    mov     rdi, rbx
    mov     esi, eax
    push    rax
    push    rcx
    push    rdx
    push    r8
    push    r9
    push    r10
    push    r11
    call    queue_enqueue
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdx
    pop     rcx
    pop     rax
    add     rsp, 16
    
.continue:
    dec     r13
    jmp     .process_loop
    
.cleanup:
    add     rsp, 16
.done:
    pop     r13
    pop     r12
    pop     rbx
    ret

; size_t queue_count_ends_with_one(Queue* q)
queue_count_ends_with_one:
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi
    xor     r12, r12
    
    ; Получаем текущий размер
    mov     r13, [rbx + 32]
    test    r13, r13
    jz      .done
    
    ; Сохраняем front
    mov     r14, [rbx + 16]
    
    ; Проходим по элементам
    mov     rcx, [rbx]
    mov     r8, [rbx + 8]
    mov     r9, r13
    
.check_loop:
    test    r9, r9
    jz      .done
    
    ; Получаем элемент
    mov     eax, [rcx + r14*4]
    
    ; Проверяем, оканчивается ли на 1
    cdq
    xor     eax, edx
    sub     eax, edx
    
    xor     edx, edx
    mov     r10d, 10
    div     r10d
    
    cmp     edx, 1
    jne     .not_ends_with_one
    
    inc     r12
    
.not_ends_with_one:
    ; Переходим к следующему элементу
    inc     r14
    cmp     r14, r8
    jl      .no_wrap_idx
    xor     r14, r14
.no_wrap_idx:
    
    dec     r9
    jmp     .check_loop
    
.done:
    mov     rax, r12
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; size_t queue_get_odd_numbers(Queue* q, int32_t **buffer)
queue_get_odd_numbers:
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi
    mov     r14, rsi
    
    xor     r12, r12
    
    ; Получаем текущий размер
    mov     r13, [rbx + 32]
    test    r13, r13
    jz      .no_elements
    
    ; Выделяем память под результат
    mov     rdi, r13
    shl     rdi, 2
    push    rbx
    push    r12
    push    r13
    push    r14
    call    malloc
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    test    rax, rax
    jz      .error
    
    mov     [r14], rax
    mov     r8, rax
    
    ; Проходим по элементам
    mov     rcx, [rbx]
    mov     r9, [rbx + 16]
    mov     r10, [rbx + 8]
    mov     r11, r13
    
.scan_loop:
    test    r11, r11
    jz      .done_scan
    
    ; Получаем элемент
    mov     eax, [rcx + r9*4]
    
    ; Проверяем, нечетное ли
    test    eax, 1
    jz      .even_number
    
    ; Нечетное - сохраняем
    mov     [r8 + r12*4], eax
    inc     r12
    
.even_number:
    ; Переходим к следующему
    inc     r9
    cmp     r9, r10
    jl      .no_wrap_scan
    xor     r9, r9
.no_wrap_scan:
    
    dec     r11
    jmp     .scan_loop
    
.done_scan:
    mov     rax, r12
    jmp     .exit
    
.no_elements:
    ; Выделяем пустой буфер
    mov     rdi, 4
    push    rbx
    push    r12
    push    r13
    push    r14
    call    malloc
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    test    rax, rax
    jz      .error
    mov     [r14], rax
    xor     rax, rax
    jmp     .exit
    
.error:
    xor     rax, rax
    
.exit:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret