format ELF64

section '.text' executable

public array_create_asm
public array_fill_random_asm
public array_sum_asm
public array_count_even_asm
public array_get_odd_numbers_asm
public array_count_primes_asm
public array_reverse_asm

extrn rand

; void array_create_asm(DynamicArray *arr, size_t size)
array_create_asm:
    push rbp
    mov rbp, rsp
    
    ; rdi = arr, rsi = size
    mov rax, [rdi + 8]       ; arr->capacity
    cmp rsi, rax
    jg .create_error         ; если size > capacity
    
    mov [rdi], rsi           ; arr->size = size
    
.create_error:
    pop rbp
    ret

; void array_fill_random_asm(DynamicArray *arr)
array_fill_random_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    ; rdi = arr
    mov r12, rdi             ; сохраняем arr
    mov r13, [r12]           ; arr->size
    
    test r13, r13
    jz .fill_done
    
    mov r14, [r12 + 8]       ; arr->data
    xor rcx, rcx             ; индекс i = 0
    
.fill_loop:
    ; Генерируем случайное число от 1 до 100
    call rand
    and eax, 0x7FFFFFFF      ; делаем положительным
    mov ebx, 100
    xor edx, edx
    div ebx
    mov eax, edx             ; остаток от деления
    inc eax                  ; от 1 до 100
    
    mov [r14 + rcx * 4], eax ; arr->data[i] = random
    
    inc rcx
    cmp rcx, r13
    jl .fill_loop
    
.fill_done:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; int array_sum_asm(DynamicArray *arr)
array_sum_asm:
    push rbp
    mov rbp, rsp
    push r12
    
    ; rdi = arr
    mov rcx, [rdi]           ; arr->size
    test rcx, rcx
    jz .sum_zero
    
    mov r8, [rdi + 8]        ; arr->data
    xor eax, eax             ; сумма = 0
    xor r9, r9               ; индекс = 0
    
.sum_loop:
    add eax, [r8 + r9 * 4]
    inc r9
    cmp r9, rcx
    jl .sum_loop
    jmp .sum_done
    
.sum_zero:
    xor eax, eax
    
.sum_done:
    pop r12
    pop rbp
    ret

; size_t array_count_even_asm(DynamicArray *arr)
array_count_even_asm:
    push rbp
    mov rbp, rsp
    push r12
    
    ; rdi = arr
    mov rcx, [rdi]           ; arr->size
    test rcx, rcx
    jz .count_even_zero
    
    mov r8, [rdi + 8]        ; arr->data
    xor rax, rax             ; счетчик = 0
    xor r9, r9               ; индекс = 0
    
.count_even_loop:
    mov r10d, [r8 + r9 * 4]
    test r10d, 1             ; проверяем младший бит
    jnz .not_even
    inc rax                  ; увеличиваем счетчик если четное
    
.not_even:
    inc r9
    cmp r9, rcx
    jl .count_even_loop
    jmp .count_even_done
    
.count_even_zero:
    xor rax, rax
    
.count_even_done:
    pop r12
    pop rbp
    ret

; void array_get_odd_numbers_asm(DynamicArray *arr, int *result, size_t *count)
array_get_odd_numbers_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    
    ; rdi = arr, rsi = result, rdx = count
    mov r12, rdi             ; arr
    mov r13, rsi             ; result
    mov r14, rdx             ; &count
    xor r15, r15             ; счетчик нечетных = 0
    
    mov rcx, [r12]           ; arr->size
    test rcx, rcx
    jz .get_odd_done
    
    mov r8, [r12 + 8]        ; arr->data
    xor r9, r9               ; индекс = 0
    
.get_odd_loop:
    mov eax, [r8 + r9 * 4]
    test eax, 1              ; проверяем младший бит
    jz .not_odd
    
    ; Сохраняем нечетное число
    mov [r13 + r15 * 4], eax
    inc r15
    
.not_odd:
    inc r9
    cmp r9, rcx
    jl .get_odd_loop
    
.get_odd_done:
    mov [r14], r15           ; *count = количество нечетных
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; size_t array_count_primes_asm(DynamicArray *arr)
array_count_primes_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    ; rdi = arr
    mov r12, rdi             ; arr
    mov r13, [r12]           ; arr->size
    xor r14, r14             ; счетчик простых = 0
    
    test r13, r13
    jz .count_primes_done
    
    mov r15, [r12 + 8]       ; arr->data
    xor rcx, rcx             ; индекс = 0
    
.count_primes_loop:
    mov edi, [r15 + rcx * 4] ; число для проверки
    
    ; Проверка на простоту
    cmp edi, 1
    jle .not_prime
    
    ; Проверка делимости на 2
    mov eax, edi
    and eax, 1
    jz .check_two            ; если четное
    
    ; Для нечетных чисел проверяем делители
    mov r8d, 3               ; делитель = 3
    
.prime_check_loop:
    mov eax, r8d
    mul r8d
    cmp eax, edi
    jg .is_prime_number      ; если делитель^2 > числа
    
    mov eax, edi
    xor edx, edx
    div r8d
    test edx, edx
    jz .not_prime            ; если делится
    
    add r8d, 2               ; следующий нечетный делитель
    jmp .prime_check_loop
    
.check_two:
    cmp edi, 2
    jne .not_prime
    
.is_prime_number:
    inc r14
    
.not_prime:
    inc rcx
    cmp rcx, r13
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

; void array_reverse_asm(DynamicArray *arr)
array_reverse_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    
    ; rdi = arr
    mov rcx, [rdi]           ; arr->size
    cmp rcx, 1
    jle .reverse_done        ; если size <= 1
    
    mov r8, [rdi + 8]        ; arr->data
    xor r9, r9               ; left = 0
    mov r10, rcx
    dec r10                  ; right = size - 1
    
.reverse_loop:
    cmp r9, r10
    jge .reverse_done
    
    ; Меняем местами arr[left] и arr[right]
    mov eax, [r8 + r9 * 4]   ; temp = arr[left]
    mov r11d, [r8 + r10 * 4]
    mov [r8 + r9 * 4], r11d  ; arr[left] = arr[right]
    mov [r8 + r10 * 4], eax  ; arr[right] = temp
    
    inc r9                   ; left++
    dec r10                  ; right--
    jmp .reverse_loop
    
.reverse_done:
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
