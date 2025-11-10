format ELF64

section '.text' executable

public queue_enqueue_asm
public queue_dequeue_asm
public queue_fill_random_asm
public queue_count_even_asm
public queue_get_odd_numbers_asm
public queue_count_primes_asm
public queue_count_ends_with_1_asm
public queue_remove_even_asm

; void queue_enqueue_asm(Queue *q, int value)
queue_enqueue_asm:
    push rbp
    mov rbp, rsp
    
    ; rdi = q, esi = value
    mov r8, [rdi + 32]       ; q->capacity (смещение 32)
    mov r9, [rdi + 24]       ; q->size (смещение 24)
    
    cmp r9, r8
    jge .enqueue_full        ; если очередь полна
    
    ; Добавляем элемент в конец
    mov r10, [rdi]           ; q->data (смещение 0)
    mov r11, [rdi + 16]      ; q->rear (смещение 16)
    
    mov [r10 + r11 * 4], esi ; q->data[rear] = value
    
    ; Обновляем rear и size
    inc r11
    cmp r11, r8
    jl .no_wrap_rear
    xor r11, r11             ; обнуляем если достигли capacity
.no_wrap_rear:
    mov [rdi + 16], r11      ; q->rear = new_rear
    
    mov r9, [rdi + 24]
    inc r9
    mov [rdi + 24], r9       ; q->size++
    
.enqueue_full:
    pop rbp
    ret

; int queue_dequeue_asm(Queue *q)
queue_dequeue_asm:
    push rbp
    mov rbp, rsp
    
    ; rdi = q
    mov r9, [rdi + 24]       ; q->size
    test r9, r9
    jz .dequeue_empty        ; если очередь пуста
    
    ; Извлекаем элемент из начала
    mov r10, [rdi]           ; q->data
    mov r11, [rdi + 8]       ; q->front (смещение 8)
    mov eax, [r10 + r11 * 4] ; возвращаемое значение
    
    ; Обновляем front и size
    inc r11
    mov r8, [rdi + 32]       ; q->capacity
    cmp r11, r8
    jl .no_wrap_front
    xor r11, r11             ; обнуляем если достигли capacity
.no_wrap_front:
    mov [rdi + 8], r11       ; q->front = new_front
    
    mov r9, [rdi + 24]
    dec r9
    mov [rdi + 24], r9       ; q->size--
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
    push r12
    push r13
    push r14
    
    ; rdi = q, rsi = count
    mov r12, rdi             ; сохраняем q
    mov r13, rsi             ; сохраняем count
    
    ; Используем простую последовательность для демонстрации
    mov r14d, 1              ; начальное значение
    
.fill_loop:
    test r13, r13
    jz .fill_done
    
    ; Добавляем число в очередь
    mov rdi, r12
    mov esi, r14d
    call queue_enqueue_asm
    
    ; Увеличиваем значение для следующего числа
    add r14d, 7
    cmp r14d, 100
    jle .no_reset
    mov r14d, 2              ; сбрасываем если больше 100
.no_reset:
    
    dec r13
    jmp .fill_loop
    
.fill_done:
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; size_t queue_count_even_asm(Queue *q)
queue_count_even_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    
    ; rdi = q
    mov r12, rdi             ; сохраняем q
    mov r13, [r12 + 24]      ; q->size
    xor r14, r14             ; счетчик четных = 0
    
    test r13, r13
    jz .count_even_done
    
    mov r8, [r12]            ; q->data
    mov r9, [r12 + 8]        ; q->front
    mov r10, [r12 + 32]      ; q->capacity
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
    pop rbp
    ret

; void queue_get_odd_numbers_asm(Queue *q, int *result, size_t *count)
queue_get_odd_numbers_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    
    ; rdi = q, rsi = result, rdx = count
    mov r12, rdi             ; q
    mov r13, rsi             ; result
    mov r14, rdx             ; &count
    xor r15, r15             ; счетчик нечетных = 0
    
    mov rcx, [r12 + 24]      ; q->size
    test rcx, rcx
    jz .get_odd_done
    
    mov r8, [r12]            ; q->data
    mov r9, [r12 + 8]        ; q->front
    mov r10, [r12 + 32]      ; q->capacity
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
    pop rbp
    ret

; size_t queue_count_primes_asm(Queue *q)
queue_count_primes_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    ; rdi = q
    mov r12, rdi             ; q
    mov r13, [r12 + 24]      ; q->size
    xor r14, r14             ; счетчик простых = 0
    
    test r13, r13
    jz .count_primes_done
    
    mov r8, [r12]            ; q->data
    mov r9, [r12 + 8]        ; q->front
    mov r10, [r12 + 32]      ; q->capacity
    xor r11, r11             ; пройденные элементы
    
.count_primes_loop:
    mov edi, [r8 + r9 * 4]   ; число для проверки
    
    ; Проверка на простоту
    cmp edi, 1
    jle .not_prime
    
    ; Проверка делимости на 2
    mov eax, edi
    and eax, 1
    jz .check_two            ; если четное
    
    ; Для нечетных чисел проверяем делители
    mov r15d, 3              ; делитель = 3
    
.prime_check_loop:
    mov eax, r15d
    mul r15d
    cmp eax, edi
    jg .is_prime_number      ; если делитель^2 > числа
    
    mov eax, edi
    xor edx, edx
    div r15d
    test edx, edx
    jz .not_prime            ; если делится
    
    add r15d, 2              ; следующий нечетный делитель
    jmp .prime_check_loop
    
.check_two:
    cmp edi, 2
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
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; size_t queue_count_ends_with_1_asm(Queue *q)
queue_count_ends_with_1_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    
    ; rdi = q
    mov r12, rdi             ; q
    mov r13, [r12 + 24]      ; q->size
    xor r14, r14             ; счетчик = 0
    
    test r13, r13
    jz .count_ends_done
    
    mov r8, [r12]            ; q->data
    mov r9, [r12 + 8]        ; q->front
    mov r10, [r12 + 32]      ; q->capacity
    xor r11, r11             ; пройденные элементы
    
.count_ends_loop:
    mov eax, [r8 + r9 * 4]   ; текущий элемент
    
    ; Проверяем оканчивается ли на 1 (abs(value) % 10 == 1)
    mov ecx, eax
    test ecx, ecx
    jns .positive
    neg ecx                  ; берем модуль
.positive:
    mov r15d, 10
    xor edx, edx
    div r15d
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
    pop rbp
    ret

; void queue_remove_even_asm(Queue *q)
queue_remove_even_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    
    ; rdi = q
    mov r12, rdi             ; q
    mov r13, [r12 + 24]      ; q->size
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
    
.even_number:
    inc r14
    jmp .process_loop
    
.remove_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret