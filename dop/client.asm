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
    connect_msg    db 'Connecting to server...', 10, 0
    connected_msg  db 'Connected!', 10, 0
    error_socket   db 'Socket creation failed!', 10, 0
    error_connect  db 'Connection failed!', 10, 0
    ; Убираем лишнее приглашение, оставляем только серверное
    ; prompt_msg     db 'Enter numbers separated by spaces (end with #): ', 0

    buffer         rb 256
    server_addr:
        dw AF_INET
        db 0x15, 0xB3    ; Port 5555
        db 127, 0, 0, 1  ; localhost
        dq 0

    socket_fd      dq 0

section '.text' executable
_start:
    ; Вывод сообщения
    mov rsi, connect_msg
    call print_string

    ; Создание сокета
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl socket_error

    mov [socket_fd], rax

    ; Подключение к серверу
    mov rax, SYS_CONNECT
    mov rdi, [socket_fd]
    mov rsi, server_addr
    mov rdx, 16
    syscall

    cmp rax, 0
    jl connect_error

    mov rsi, connected_msg
    call print_string

    ; Чтение с сервера
    mov rax, SYS_READ
    mov rdi, [socket_fd]
    mov rsi, buffer
    mov rdx, 255
    syscall

    ; Вывод с сервера
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall

    ; Убираем вывод дополнительного приглашения
    ; mov rsi, prompt_msg
    ; call print_string

    ; Чтение чисел
    mov rax, SYS_READ
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 255
    syscall

    ; Проверяем, что мы что-то ввели
    cmp rax, 0
    je no_input

    ; Отправляем данные на сервер (убедимся, что есть символ '#' в конце)
    mov rbx, rax  ; сохраняем длину ввода

    ; Проверяем, есть ли уже '#' в конце
    mov rcx, rbx
    dec rcx
    cmp byte [buffer + rcx], '#'
    je has_hash

    ; Добавляем '#' если его нет
    cmp rbx, 254
    jge skip_hash  ; если буфер полный
    mov byte [buffer + rbx], '#'
    inc rbx
    jmp send_data

skip_hash:
    ; Если буфер полный, просто используем его как есть
    mov rbx, 255
    jmp send_data

has_hash:
    inc rbx  ; включаем символ # в отправку

send_data:
    ; Отправляем данные на сервер
    mov rdx, rbx
    mov rax, SYS_WRITE
    mov rdi, [socket_fd]
    syscall

    ; Читаем результаты от сервера
read_results:
    mov rax, SYS_READ
    mov rdi, [socket_fd]
    mov rsi, buffer
    mov rdx, 255
    syscall

    cmp rax, 0
    jle disconnect

    ; Выводим результаты
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall

    ; Проверяем, есть ли еще данные
    jmp read_results

no_input:
    ; Если пользователь не ввел ничего, просто закрываем соединение
    jmp disconnect

disconnect:
    ; Close socket
    mov rax, SYS_CLOSE
    mov rdi, [socket_fd]
    syscall

    ; Exit
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

socket_error:
    mov rsi, error_socket
    call print_string
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

connect_error:
    mov rsi, error_connect
    call print_string
    mov rax, SYS_CLOSE
    mov rdi, [socket_fd]
    syscall
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

print_string:
    ; Print string at rsi
    push rdi
    push rsi
    push rdx
    push rax

    mov rdi, rsi
    call strlen

    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall

    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

strlen:
    ; Длина строки в rdi
    xor rax, rax
strlen_loop:
    cmp byte [rdi + rax], 0
    je strlen_done
    inc rax
    jmp strlen_loop
strlen_done:
    ret