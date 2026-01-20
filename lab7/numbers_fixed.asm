format ELF64 executable 3
entry _start

segment readable executable

_start:
    ; Получаем PID для инициализации RNG и определения задачи
    mov rax, 39          ; sys_getpid
    syscall
    mov [rseed], eax     ; Используем младшие 32 бита
    and eax, 3
    mov [task_id], eax
    
    ; Заполняем массив случайными числами
    mov rcx, array_size
    mov rdi, numbers
.fill_loop:
    call rand
    mov [rdi], eax
    add rdi, 4
    loop .fill_loop
    
    ; Выполняем задачу в соответствии с task_id
    mov eax, [task_id]
    cmp eax, 0
    je task1
    cmp eax, 1
    je task2
    cmp eax, 2
    je task3
    cmp eax, 3
    je task4

task1:
    call find_most_frequent
    mov [result], eax
    mov rsi, msg1
    mov rdx, msg1_len
    jmp output_result

task2:
    call count_mult5
    mov [result], eax
    mov rsi, msg2
    mov rdx, msg2_len
    jmp output_result

task3:
    call quantile75
    mov [result], eax
    mov rsi, msg3
    mov rdx, msg3_len
    jmp output_result

task4:
    call fifth_after_min
    mov [result], eax
    mov rsi, msg4
    mov rdx, msg4_len

output_result:
    ; Сначала выводим сообщение
    call print_str
    ; Затем выводим число
    mov eax, [result]
    call print_number
    ; И новую строку
    call print_nl
    
    ; Завершаем процесс
    mov rax, 60          ; sys_exit
    xor rdi, rdi         ; exit code 0
    syscall

; ========== ФУНКЦИИ ==========

rand:
    mov eax, [rseed]
    mov edx, 1103515245
    mul edx
    add eax, 12345
    mov [rseed], eax
    shr eax, 16
    and eax, 32767
    ret

find_most_frequent:
    ; Обнуляем массив подсчета цифр
    mov rcx, 10
    mov rdi, digit_count
    xor rax, rax
    rep stosd
    
    ; Подсчитываем цифры во всех числах
    mov rcx, array_size
    mov rsi, numbers
.count_loop:
    mov eax, [rsi]
    add rsi, 4
    test eax, eax
    jz .next_num
    
.digit_loop:
    xor edx, edx
    mov ebx, 10
    div ebx
    inc dword [digit_count + rdx*4]
    test eax, eax
    jnz .digit_loop
    
.next_num:
    loop .count_loop
    
    ; Находим наиболее частую цифру
    mov rcx, 9
    mov eax, 0
    mov ebx, [digit_count]
    
.find_max:
    mov edx, [digit_count + rcx*4]
    cmp edx, ebx
    jle .next
    mov ebx, edx
    mov eax, ecx
.next:
    loop .find_max
    ret

count_mult5:
    mov rcx, array_size
    mov rsi, numbers
    xor rax, rax
    
.loop:
    mov ebx, [rsi]
    add rsi, 4
    test ebx, ebx
    jz .skip
    
    push rax
    mov eax, ebx
    xor edx, edx
    mov ebx, 5
    div ebx
    pop rax
    test edx, edx
    jnz .skip
    
    inc eax
.skip:
    loop .loop
    ret

quantile75:
    call sort_array
    mov eax, array_size
    mov ebx, 3
    mul ebx
    shr rax, 2
    mov rsi, numbers
    mov eax, [rsi + rax*4]
    ret

fifth_after_min:
    call sort_array
    mov rsi, numbers
    mov eax, [rsi + 5*4]
    ret

sort_array:
    mov rcx, array_size
    dec rcx
    jle .done
    
.outer:
    push rcx
    mov rsi, numbers
    xor rdx, rdx
    
.inner:
    mov eax, [rsi]
    mov ebx, [rsi+4]
    cmp eax, ebx
    jle .no_swap
    mov [rsi], ebx
    mov [rsi+4], eax
    mov rdx, 1
.no_swap:
    add rsi, 4
    loop .inner
    
    pop rcx
    test rdx, rdx
    jz .done
    loop .outer
.done:
    ret

print_str:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall
    ret

print_number:
    mov rdi, num_buf + 11
    mov byte [rdi], 0
    mov rbx, 10
    
    test eax, eax
    jnz .convert
    dec rdi
    mov byte [rdi], '0'
    jmp .print
    
.convert:
    xor edx, edx
    div ebx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test eax, eax
    jnz .convert
    
.print:
    mov rsi, rdi
    mov rdx, num_buf + 12
    sub rdx, rsi
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall
    ret

print_nl:
    mov rsi, nl
    mov rdx, 1
    call print_str
    ret

segment readable writeable
    array_size = 100
    numbers rd array_size
    digit_count rd 10
    rseed rd 1
    task_id rd 1
    result rd 1
    num_buf rb 12
    
    msg1 db "Наиболее часто встречающаяся цифра: ", 0
    msg1_len = $ - msg1
    
    msg2 db "Количество чисел кратных пяти: ", 0
    msg2_len = $ - msg2
    
    msg3 db "0.75 квантиль: ", 0
    msg3_len = $ - msg3
    
    msg4 db "Пятое после миниманого: ", 0
    msg4_len = $ - msg4
    
    nl db 10