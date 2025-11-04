format ELF64

section '.data' writable
    prompt db "Введите n: ", 0
    prompt_len = $ - prompt
    result_msg db "Автоморфные числа:", 10, 0
    result_msg_len = $ - result_msg
    separator db " - ", 0
    separator_len = $ - separator
    newline db 10

section '.bss' writable
    n rd 1
    i rd 1
    digits rd 1
    power rq 1
    square rq 1
    temp rd 1
    buffer rb 20
    num_buf rb 20

section '.text' executable
public _start

_start:
    ; Вывод приглашения
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Чтение числа n
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 20
    syscall

    ; Преобразование строки в число
    mov rsi, buffer
    xor rax, rax
    xor rbx, rbx
convert_loop:
    mov bl, [rsi]
    cmp bl, 10
    je convert_done
    sub bl, '0'
    imul rax, 10
    add rax, rbx
    inc rsi
    jmp convert_loop
convert_done:
    mov [n], eax

    ; Вывод заголовка
    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall

    ; Инициализация цикла
    mov dword [i], 1

main_loop:
    mov eax, [i]
    cmp eax, [n]
    jg program_end

    ; Вычисление квадрата
    mov eax, [i]
    movsxd rax, eax
    imul rax, rax
    mov [square], rax

    ; Подсчет цифр
    mov eax, [i]
    mov [temp], eax
    mov dword [digits], 0

count_digits:
    mov eax, [temp]
    test eax, eax
    jz digits_done
    inc dword [digits]
    xor edx, edx
    mov ecx, 10
    div ecx
    mov [temp], eax
    jmp count_digits

digits_done:
    ; Вычисление 10^digits
    mov qword [power], 1
    mov ecx, [digits]
    test ecx, ecx
    jz check_automorphic

compute_power:
    mov rax, [power]
    mov rbx, 10
    mul rbx
    mov [power], rax
    dec ecx
    jnz compute_power

check_automorphic:
    ; Проверка условия
    mov rax, [square]
    mov rbx, [power]
    test rbx, rbx
    jz next_number
    xor rdx, rdx
    div rbx
    mov eax, [i]
    cmp edx, eax
    jne next_number

    ; Вывод найденного числа (простой способ)
    call print_simple_number

next_number:
    inc dword [i]
    jmp main_loop

print_simple_number:
    ; Простой вывод через системные вызовы для каждого символа
    ; Вывод числа i
    mov eax, [i]
    call print_number
    
    ; Вывод разделителя
    mov rax, 1
    mov rdi, 1
    mov rsi, separator
    mov rdx, separator_len
    syscall
    
    ; Вывод квадрата
    mov rax, [square]
    call print_number64
    
    ; Новая строка
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

; Печать 32-битного числа
print_number:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    mov rcx, num_buf + 19
    mov byte [rcx], 0
    dec rcx
    
    test eax, eax
    jnz .convert
    mov byte [rcx], '0'
    dec rcx
    jmp .print
    
.convert:
    xor edx, edx
    mov ebx, 10
    div ebx
    add dl, '0'
    mov [rcx], dl
    dec rcx
    test eax, eax
    jnz .convert
    
.print:
    inc rcx
    mov rsi, rcx
    mov rdx, num_buf + 20
    sub rdx, rcx
    mov rax, 1
    mov rdi, 1
    syscall
    
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Печать 64-битного числа
print_number64:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    mov rcx, num_buf + 19
    mov byte [rcx], 0
    dec rcx
    
    test rax, rax
    jnz .convert
    mov byte [rcx], '0'
    dec rcx
    jmp .print
    
.convert:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add dl, '0'
    mov [rcx], dl
    dec rcx
    test rax, rax
    jnz .convert
    
.print:
    inc rcx
    mov rsi, rcx
    mov rdx, num_buf + 20
    sub rdx, rcx
    mov rax, 1
    mov rdi, 1
    syscall
    
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

program_end:
    mov rax, 60
    xor rdi, rdi
    syscall