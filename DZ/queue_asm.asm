format ELF64

; Системные вызовы Linux
SYS_MMAP    = 9
SYS_MUNMAP  = 11
MAP_ANONYMOUS = 0x20
MAP_PRIVATE = 0x02
PROT_READ   = 1
PROT_WRITE  = 2

; Смещения в структуре Queue (должны совпадать с C)
QUEUE_DATA     = 0
QUEUE_FRONT    = 8
QUEUE_REAR     = 16
QUEUE_SIZE     = 24
QUEUE_CAPACITY = 32

section '.text' executable

public queue_init_asm
public queue_free_asm
public queue_enqueue_asm
public queue_dequeue_asm
public queue_fill_random_asm
public queue_count_even_asm
public queue_get_odd_numbers_asm
public queue_count_primes_asm
public queue_count_ends_with_1_asm
public queue_remove_even_asm

; Queue* queue_init_asm(size_t capacity)
queue_init_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    
    ; rdi = capacity
    mov r12, rdi             ; сохраняем capacity
    
    ; Вычисляем общий размер: sizeof(Queue) + capacity * sizeof(int)
    ; sizeof(Queue) = 40 байт (5 полей * 8 байт)
    mov rax, r12
    shl rax, 2               ; capacity * 4 (sizeof(int))
    add rax, 40              ; + sizeof(Queue) = 40 байт
    mov r13, rax             ; сохраняем total_size
    
    ; Вызываем mmap
    ; void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)
    xor edi, edi             ; addr = NULL (пусть система сама выберет)
    mov rsi, r13             ; length = total_size
    mov edx, PROT_READ or PROT_WRITE
    mov r10, MAP_PRIVATE or MAP_ANONYMOUS
    mov r8d, -1              ; fd = -1 (для MAP_ANONYMOUS)
    xor r9d, r9d             ; offset = 0
    mov eax, SYS_MMAP
    syscall
    
    cmp rax, -1              ; проверка на ошибку (MAP_FAILED = -1)
    je .init_error
    
    ; Инициализация структуры Queue
    mov r14, rax             ; сохраняем указатель на выделенную память
    
    ; Устанавливаем поля структуры
    ; q->data = (int*)((char*)memory + sizeof(Queue))
    mov rbx, r14
    add rbx, 40
    mov [r14 + QUEUE_DATA], rbx
    
    ; q->front = 0
    mov qword [r14 + QUEUE_FRONT], 0
    
    ; q->rear = 0
    mov qword [r14 + QUEUE_REAR], 0
    
    ; q->size = 0
    mov qword [r14 + QUEUE_SIZE], 0
    
    ; q->capacity = capacity
    mov [r14 + QUEUE_CAPACITY], r12
    
    mov rax, r14             ; возвращаем указатель на Queue
    jmp .init_done
    
.init_error:
    xor eax, eax             ; возвращаем NULL при ошибке
    
.init_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; void queue_free_asm(Queue *q)
queue_free_asm:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; rdi = q
    test rdi, rdi
    jz .free_done            ; если указатель NULL, ничего не делаем
    
    ; Вычисляем общий размер для освобождения
    mov rbx, [rdi + QUEUE_CAPACITY] ; capacity
    shl rbx, 2               ; capacity * 4
    add rbx, 40              ; + sizeof(Queue) = 40 байт
    
    ; Вызываем munmap
    ; int munmap(void *addr, size_t length)
    mov rsi, rbx             ; length = total_size
    mov eax, SYS_MUNMAP
    syscall
    
.free_done:
    pop rbx
    pop rbp
    ret

; void queue_enqueue_asm(Queue *q, int value)
queue_enqueue_asm:
    push rbp
    mov rbp, rsp
    
    ; rdi = q, esi = value
    mov r8, [rdi + QUEUE_CAPACITY]
    mov r9, [rdi + QUEUE_SIZE]
    
    cmp r9, r8
    jge .enqueue_full        ; если очередь полна
    
    ; Добавляем элемент в конец
    mov r10, [rdi + QUEUE_DATA]  ; q->data
    mov r11, [rdi + QUEUE_REAR]  ; q->rear
    
    mov [r10 + r11 * 4], esi ; q->data[rear] = value
    
    ; Обновляем rear и size
    inc r11
    cmp r11, r8
    jl .no_wrap_rear
    xor r11, r11             ; обнуляем если достигли capacity
.no_wrap_rear:
    mov [rdi + QUEUE_REAR], r11  ; q->rear = new_rear
    
    mov r9, [rdi + QUEUE_SIZE]
    inc r9
    mov [rdi + QUEUE_SIZE], r9   ; q->size++
    
.enqueue_full:
    pop rbp
    ret

; int queue_dequeue_asm(Queue *q)
queue_dequeue_asm:
    push rbp
    mov rbp, rsp
    
    ; rdi = q
    mov r9, [rdi + QUEUE_SIZE]
    test r9, r9
    jz .dequeue_empty        ; если очередь пуста
    
    ; Извлекаем элемент из начала
    mov r10, [rdi + QUEUE_DATA]   ; q->data
    mov r11, [rdi + QUEUE_FRONT]  ; q->front
    mov eax, [r10 + r11 * 4]      ; возвращаемое значение
    
    ; Обновляем front и size
    inc r11
    mov r8, [rdi + QUEUE_CAPACITY]
    cmp r11, r8
    jl .no_wrap_front
    xor r11, r11             ; обнуляем если достигли capacity
.no_wrap_front:
    mov [rdi + QUEUE_FRONT], r11  ; q->front = new_front
    
    mov r9, [rdi + QUEUE_SIZE]
    dec r9
    mov [rdi + QUEUE_SIZE], r9    ; q->size--
    jmp .dequeue_done
    
.dequeue_empty:
    xor eax, eax             ; возвращаем 0 если очередь пуста
    
.dequeue_done:
    pop rbp
    ret

; void queue_fill_random_asm(Queue *q, size_t count)
queue_fill_random_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; rdi = q, rsi = count
    mov r12, rdi             ; сохраняем q
    mov r13, rsi             ; сохраняем count
    
    ; Используем простую псевдослучайную последовательность
    mov ebx, 42              ; начальное значение (seed)
    
.fill_loop:
    test r13, r13
    jz .fill_done
    
    ; Генерируем псевдослучайное число
    imul ebx, 1103515245
    add ebx, 12345
    and ebx, 0x7FFF          ; ограничиваем диапазон
    add ebx, 1               ; от 1 до 32768
    
    ; Добавляем число в очередь
    mov rdi, r12
    mov esi, ebx
    call queue_enqueue_asm
    
    dec r13
    jmp .fill_loop
    
.fill_done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; size_t queue_count_even_asm(Queue *q)
queue_count_even_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    
    ; rdi = q
    mov r12, rdi             ; сохраняем q
    mov r13, [r12 + QUEUE_SIZE]  ; q->size
    xor r14, r14             ; счетчик четных = 0
    
    test r13, r13
    jz .count_even_done
    
    mov r8, [r12 + QUEUE_DATA]    ; q->data
    mov r9, [r12 + QUEUE_FRONT]   ; q->front
    mov r10, [r12 + QUEUE_CAPACITY] ; q->capacity
    xor r11, r11             ; пройденные элементы
    
.count_even_loop:
    mov eax, [r8 + r9 * 4]   ; текущий элемент
    test eax, 1              ; проверяем четность
    jnz .not_even
    inc r14                  ; увеличиваем счетчик если четное
    
.not_even:
    ; Переходим к следующему элементу
    inc r9
    cmp r9, r10
    jl .no_wrap_count
    xor r9, r9
.no_wrap_count:
    
    inc r11
    cmp r11, r13
    jl .count_even_loop
    
.count_even_done:
    mov rax, r14
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; void queue_get_odd_numbers_asm(Queue *q, int *result, size_t *count)
queue_get_odd_numbers_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; rdi = q, rsi = result, rdx = count
    mov r12, rdi             ; q
    mov r13, rsi             ; result
    mov r14, rdx             ; &count
    xor r15, r15             ; счетчик нечетных = 0
    
    mov rcx, [r12 + QUEUE_SIZE] ; q->size
    test rcx, rcx
    jz .get_odd_done
    
    mov r8, [r12 + QUEUE_DATA]   ; q->data
    mov r9, [r12 + QUEUE_FRONT]  ; q->front
    mov r10, [r12 + QUEUE_CAPACITY] ; q->capacity
    xor r11, r11             ; пройденные элементы
    
.get_odd_loop:
    mov eax, [r8 + r9 * 4]   ; текущий элемент
    test eax, 1              ; проверяем нечетность
    jz .not_odd
    
    ; Сохраняем нечетное число
    mov [r13 + r15 * 4], eax
    inc r15
    
.not_odd:
    ; Переходим к следующему элементу
    inc r9
    cmp r9, r10
    jl .no_wrap_odd
    xor r9, r9
.no_wrap_odd:
    
    inc r11
    cmp r11, rcx
    jl .get_odd_loop
    
.get_odd_done:
    mov [r14], r15           ; *count = количество нечетных
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; size_t queue_count_primes_asm(Queue *q)
queue_count_primes_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; rdi = q
    mov r12, rdi             ; q
    mov r13, [r12 + QUEUE_SIZE] ; q->size
    xor r14, r14             ; счетчик простых = 0
    
    test r13, r13
    jz .count_primes_done
    
    mov r8, [r12 + QUEUE_DATA]   ; q->data
    mov r9, [r12 + QUEUE_FRONT]  ; q->front
    mov r10, [r12 + QUEUE_CAPACITY] ; q->capacity
    xor r11, r11             ; пройденные элементы
    
.count_primes_loop:
    mov ebx, [r8 + r9 * 4]   ; число для проверки
    
    ; Проверка на простоту
    cmp ebx, 1
    jle .not_prime
    
    ; Проверка делимости на 2
    mov eax, ebx
    and eax, 1
    jz .check_two            ; если четное
    
    ; Для нечетных чисел проверяем делители
    mov r15d, 3              ; делитель = 3
    
.prime_check_loop:
    mov eax, r15d
    mul r15d
    cmp eax, ebx
    jg .is_prime_number      ; если делитель^2 > числа
    
    mov eax, ebx
    xor edx, edx
    div r15d
    test edx, edx
    jz .not_prime            ; если делится
    
    add r15d, 2              ; следующий нечетный делитель
    jmp .prime_check_loop
    
.check_two:
    cmp ebx, 2
    jne .not_prime
    
.is_prime_number:
    inc r14
    
.not_prime:
    ; Переходим к следующему элементу
    inc r9
    cmp r9, r10
    jl .no_wrap_prime
    xor r9, r9
.no_wrap_prime:
    
    inc r11
    cmp r11, r13
    jl .count_primes_loop
    
.count_primes_done:
    mov rax, r14
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; size_t queue_count_ends_with_1_asm(Queue *q)
queue_count_ends_with_1_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    
    ; rdi = q
    mov r12, rdi             ; q
    mov r13, [r12 + QUEUE_SIZE] ; q->size
    xor r14, r14             ; счетчик = 0
    
    test r13, r13
    jz .count_ends_done
    
    mov r8, [r12 + QUEUE_DATA]   ; q->data
    mov r9, [r12 + QUEUE_FRONT]  ; q->front
    mov r10, [r12 + QUEUE_CAPACITY] ; q->capacity
    xor r11, r11             ; пройденные элементы
    
.count_ends_loop:
    mov eax, [r8 + r9 * 4]   ; текущий элемент
    
    ; Проверяем оканчивается ли на 1 (abs(value) % 10 == 1)
    mov ebx, eax
    test ebx, ebx
    jns .positive
    neg ebx                  ; берем модуль
.positive:
    mov eax, ebx
    mov ecx, 10
    xor edx, edx
    div ecx
    cmp edx, 1               ; остаток == 1?
    jne .not_ends_with_1
    inc r14
    
.not_ends_with_1:
    ; Переходим к следующему элементу
    inc r9
    cmp r9, r10
    jl .no_wrap_ends
    xor r9, r9
.no_wrap_ends:
    
    inc r11
    cmp r11, r13
    jl .count_ends_loop
    
.count_ends_done:
    mov rax, r14
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; void queue_remove_even_asm(Queue *q)
queue_remove_even_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    
    ; rdi = q
    mov r12, rdi             ; q
    mov r13, [r12 + QUEUE_SIZE] ; q->size
    xor r14, r14             ; обработанные элементы
    
    test r13, r13
    jz .remove_done
    
.process_loop:
    cmp r14, r13
    jge .remove_done
    
    ; Извлекаем элемент из начала
    mov rdi, r12
    call queue_dequeue_asm
    
    ; Проверяем четность
    test eax, 1
    jz .even_number
    
    ; Нечетное число - добавляем обратно в конец
    mov rdi, r12
    mov esi, eax
    call queue_enqueue_asm
    jmp .continue_loop
    
.even_number:
    ; Четное число - не возвращаем в очередь
    
.continue_loop:
    inc r14
    jmp .process_loop
    
.remove_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret