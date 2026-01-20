format ELF64 executable
entry start

SYS_write = 1
SYS_exit = 60
SYS_nanosleep = 35
STDOUT = 1

start:
    ; Просто выводим диагональ пробелов и звездочек
    mov r12, 0
print_diag:
    cmp r12, 10
    jge done
    
    ; Выводим пробелы
    mov r13, r12
spaces:
    test r13, r13
    jz print_star
    
    push r12
    push r13
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, space
    mov rdx, 1
    syscall
    pop r13
    pop r12
    
    dec r13
    jmp spaces

print_star:
    push r12
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, star
    mov rdx, 2  ; звездочка + новая строка
    syscall
    pop r12
    
    ; Задержка
    push r12
    mov rax, SYS_nanosleep
    mov rdi, ts
    mov qword [rdi], 0
    mov qword [rdi + 8], 100000000  ; 100ms
    xor rsi, rsi
    syscall
    pop r12
    
    inc r12
    jmp print_diag

done:
    ; Вторая диагональ (обратная)
    mov r12, 10
print_diag2:
    cmp r12, 0
    jl exit
    
    ; Выводим пробелы
    mov r13, r12
spaces2:
    test r13, r13
    jz print_hash
    
    push r12
    push r13
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, space
    mov rdx, 1
    syscall
    pop r13
    pop r12
    
    dec r13
    jmp spaces2

print_hash:
    push r12
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, hash
    mov rdx, 2  # + новая строка
    syscall
    pop r12
    
    ; Задержка
    push r12
    mov rax, SYS_nanosleep
    mov rdi, ts
    mov qword [rdi], 0
    mov qword [rdi + 8], 100000000  ; 100ms
    xor rsi, rsi
    syscall
    pop r12
    
    dec r12
    jmp print_diag2

exit:
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

space db ' '
star  db '*',10
hash  db '#',10
ts    dq 0, 0