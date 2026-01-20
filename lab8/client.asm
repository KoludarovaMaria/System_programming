format ELF64
public _start

SYS_READ        = 0
SYS_WRITE       = 1
SYS_CLOSE       = 3
SYS_SOCKET      = 41
SYS_CONNECT     = 42
SYS_EXIT        = 60
AF_INET         = 2
SOCK_STREAM     = 1

section '.data' writeable
    msg_conn        db 'Connecting to localhost...', 10, 0

    serv_addr:
        dw AF_INET
        db 0x1E, 0x61       ; Port 7777
        db 127,0,0,1        ; IP 127.0.0.1
        dq 0

    sockfd          dq 0
    recv_buf        rb 512
    input_char      db 0

section '.text' executable
_start:
    mov rsi, msg_conn
    call print_string

    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    syscall
    mov [sockfd], rax

    mov rax, SYS_CONNECT
    mov rdi, [sockfd]
    mov rsi, serv_addr
    mov rdx, 16
    syscall

loop_game:
    ; 1. Читаем что прислал сервер
    mov byte [recv_buf], 0
    mov rax, SYS_READ
    mov rdi, [sockfd]
    mov rsi, recv_buf
    mov rdx, 511
    syscall

    cmp rax, 0
    jle do_exit         ; Если 0 байт - сервер закрыл игру (конец)

    ; Печатаем ответ сервера
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall

    ; 2. Читаем ввод с клавиатуры
    mov rax, SYS_READ
    mov rdi, 0          ; stdin
    mov rsi, input_char
    mov rdx, 2          ; символ + энтер
    syscall

    ; 3. Отправляем на сервер только первый байт
    mov rax, SYS_WRITE
    mov rdi, [sockfd]
    mov rsi, input_char
    mov rdx, 1
    syscall

    jmp loop_game

do_exit:
    mov rax, SYS_CLOSE
    mov rdi, [sockfd]
    syscall
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Хелперы
print_string:
    push rdi
    push rax
    push rdx
    push rcx
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rax
    pop rdi
    ret

strlen:
    xor rax, rax
.L: cmp byte [rdi + rax], 0
    je .D
    inc rax
    jmp .L
.D: ret
