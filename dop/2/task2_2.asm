format ELF64 executable 3

sys_write       equ 1
sys_mmap        equ 9
sys_nanosleep   equ 35
sys_clone       equ 56
sys_exit        equ 60

CLONE_FLAGS     equ 0x00010f00 

segment readable executable

entry start

start:
    ; Точка входа: вывод приветствия и запуск потоков
    mov rdi, msg_start
    call print_string

    mov rdi, worker_wrapper_1
    call spawn_thread
    
    mov rdi, worker_wrapper_2
    call spawn_thread

    ; Цикл ожидания завершения всех потоков-работников
wait_loop:
    cmp byte [threads_done], 2
    je .done
    mov rdi, 0
    mov rsi, 10000000 
    call sleep_custom
    jmp wait_loop

.done:
    ; Вывод итогового состояния доски
    mov rdi, msg_final
    call print_string
    mov rdi, [board_p]
    call print_int_simple
    mov rdi, msg_newline
    call print_string

    mov rax, sys_exit
    xor rdi, rdi
    syscall

; Обертки для идентификации работников A1 и A2
worker_wrapper_1:
    mov r13, '1'
    jmp worker_logic

worker_wrapper_2:
    mov r13, '2'
    jmp worker_logic

; Основной цикл работника: реакция на вспышку и обновление доски
worker_logic:
    mov r14, 5
.loop:
    mov rdi, 0
    mov rsi, 50000000
    call sleep_custom
    
    call acquire_print_lock
    mov rdi, msg_p1_flash
    call print_with_id
    call release_print_lock

    ; Вход в критическую секцию (захват семафора доски)
    call acquire_board_lock
    
    call acquire_print_lock
    mov rdi, msg_p2_lock
    call print_with_id
    call release_print_lock

    ; Чтение значения, имитация задержки и запись P + 1
    mov rax, [board_p]
    push rax
    mov rdi, 0
    mov rsi, 100000000
    call sleep_custom
    pop rax
    
    inc rax
    mov [board_p], rax
    
    mov rsi, rax
    mov rdi, msg_p3_write
    call acquire_print_lock
    call print_with_id_and_num_reg
    call release_print_lock

    ; Выход из критической секции
    call release_board_lock
    
    dec r14
    jnz .loop

    lock inc byte [threads_done]
    mov rax, sys_exit
    xor rdi, rdi
    syscall

; Функции синхронизации (Spinlocks)
acquire_board_lock:
.spin:
    lock bts word [sema_board], 0
    jnc .ok
    pause
    jmp .spin
.ok:
    ret

release_board_lock:
    mov word [sema_board], 0
    ret

acquire_print_lock:
.spin:
    lock bts word [sema_print], 0
    jnc .ok
    pause
    jmp .spin
.ok:
    ret

release_print_lock:
    mov word [sema_print], 0
    ret

; Функции вывода сообщений в консоль
print_with_id:
    push rdi
    mov rdi, msg_worker_prefix
    call print_string
    mov [tmp_char], r13b
    mov rax, sys_write
    mov rdi, 1
    mov rsi, tmp_char
    mov rdx, 1
    syscall
    mov rdi, msg_colon
    call print_string
    pop rdi
    call print_string
    ret

print_with_id_and_num_reg:
    push rsi
    push rdi
    mov rdi, msg_worker_prefix
    call print_string
    mov [tmp_char], r13b
    mov rax, sys_write
    mov rdi, 1
    mov rsi, tmp_char
    mov rdx, 1
    syscall
    mov rdi, msg_colon
    call print_string
    pop rdi
    call print_string
    pop rdi
    call print_int_simple
    mov rdi, msg_newline
    call print_string
    ret

print_string:
    mov rsi, rdi
    xor rdx, rdx
.len:
    cmp byte [rsi+rdx], 0
    je .out
    inc rdx
    jmp .len
.out:
    mov rax, sys_write
    mov rdi, 1
    syscall
    ret

print_int_simple:
    push rbx
    mov rax, rdi
    mov rbx, 10
    xor rdx, rdx
    div rbx
    add al, '0'
    add dl, '0'
    mov [tmp_buf], al
    mov [tmp_buf+1], dl
    mov rax, sys_write
    mov rdi, 1
    mov rsi, tmp_buf
    mov rdx, 2
    syscall
    pop rbx
    ret

; Создание нового потока с выделением памяти под стек
spawn_thread:
    push rdi
    mov rax, sys_mmap
    xor rdi, rdi
    mov rsi, 4096
    mov rdx, 0x3
    mov r10, 0x22
    mov r8, -1
    xor r9, r9
    syscall
    lea rsi, [rax + 4096]
    pop r12
    mov rax, sys_clone
    mov rdi, CLONE_FLAGS
    syscall
    test rax, rax
    jz .child
    ret
.child:
    call r12
    mov rax, sys_exit
    syscall

sleep_custom:
    mov [tv_sec], rdi
    mov [tv_nsec], rsi
    mov rax, sys_nanosleep
    mov rdi, timespec
    xor rsi, rsi
    syscall
    ret

segment readable writeable

board_p      dq 0
sema_board   dw 0
sema_print   dw 0
threads_done db 0

timespec:
  tv_sec     dq 0
  tv_nsec    dq 0

; Русские сообщения
msg_start         db 'НАЧАЛО СИМУЛЯЦИИ', 10, 0
msg_final         db 'СИМУЛЯЦИЯ ЗАВЕРШЕНА', 10, 'Финальное значение на доске P: ', 0
msg_worker_prefix db 'Работник A', 0
msg_colon         db ': ', 0
msg_newline       db 10, 0
msg_p1_flash      db 'Вспышка! Направляюсь к лампе...', 10, 0
msg_p2_lock       db 'Доска заблокирована. Читаю P...', 10, 0
msg_p3_write      db 'Вернулся от лампы. Обновил P до: ', 0

tmp_char     db 0
tmp_buf      db 0, 0