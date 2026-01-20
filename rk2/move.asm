format ELF64 executable

entry start

SYS_write = 1
SYS_exit = 60
SYS_nanosleep = 35
STDOUT = 1

section readable executable

start:
    ; Очистка экрана
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, clear
    mov rdx, clear_len
    syscall
    
    ; Движение из левого верхнего в правый нижний
    mov r12, 0
diag1:
    cmp r12, 10
    jge pause1
    
    ; Позиционируем курсор
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, esc
    mov rdx, esc_len
    syscall
    
    ; Преобразуем координату Y в ASCII
    mov rax, r12
    inc rax
    mov rbx, 10
    div bl
    add ah, '0'
    add al, '0'
    mov [pos + 4], al
    mov [pos + 5], ah
    
    ; Координата X такая же
    mov [pos + 1], al
    mov [pos + 2], ah
    
    ; Устанавливаем позицию
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, pos
    mov rdx, pos_len
    syscall
    
    ; Выводим символ
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, char1
    mov rdx, 1
    syscall
    
    ; Задержка
    mov rax, SYS_nanosleep
    mov rdi, timespec
    mov qword [rdi], 0
    mov qword [rdi + 8], 100000000  ; 100ms
    xor rsi, rsi
    syscall
    
    inc r12
    jmp diag1

pause1:
    ; Пауза
    mov rax, SYS_nanosleep
    mov rdi, timespec
    mov qword [rdi], 0
    mov qword [rdi + 8], 500000000  ; 500ms
    xor rsi, rsi
    syscall
    
    ; Движение из нижнего левого в правый верхний
    mov r12, 10
diag2:
    cmp r12, 0
    jl exit
    
    ; Вычисляем y = 10 - r12, x = r12
    mov rax, 10
    sub rax, r12
    
    ; Преобразуем y в ASCII
    inc rax  ; +1 для ANSI
    mov rbx, 10
    div bl
    add ah, '0'
    add al, '0'
    mov [pos + 4], al
    mov [pos + 5], ah
    
    ; Преобразуем x в ASCII
    mov rax, r12
    inc rax
    mov rbx, 10
    div bl
    add ah, '0'
    add al, '0'
    mov [pos + 1], al
    mov [pos + 2], ah
    
    ; Устанавливаем позицию
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, pos
    mov rdx, pos_len
    syscall
    
    ; Выводим символ
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, char2
    mov rdx, 1
    syscall
    
    ; Задержка
    mov rax, SYS_nanosleep
    mov rdi, timespec
    mov qword [rdi], 0
    mov qword [rdi + 8], 100000000  ; 100ms
    xor rsi, rsi
    syscall
    
    dec r12
    jmp diag2

exit:
    ; Новая строка
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ; Выход
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

section readable writeable

clear   db 27,'[2J',27,'[H'  ; Очистка и домой
clear_len = $ - clear

esc     db 27,'['             ; Начало escape последовательности
esc_len = $ - esc

pos     db '00;00H'           ; Позиция yy;xxH
pos_len = $ - pos

char1   db '*'
char2   db '#'
newline db 10

timespec dq 0, 0