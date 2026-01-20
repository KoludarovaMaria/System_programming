format ELF64
public _start

section '.data' writeable
    prompt      db "Введите команду (например, /bin/ls или program1): ", 0
    prompt_len  = $ - prompt

    error_msg   db "Ошибка: не удалось запустить программу", 10, 0
    error_len   = $ - error_msg

    input_buffer rb 256

    align 8
    ; Выделяем место под 10 указателей (80 байт) + NULL в конце
    argv        dq 11 dup(0)
    envp_addr   dq 0
    status      dd 0

section '.text' executable
_start:
    ; 1. Получаем envp из стека при запуске
    ; На вершине стека argc, затем argv[], затем NULL, затем envp[]
    mov rax, [rsp]          ; rax = argc
    lea rsi, [rsp + rax*8 + 16] ; Пропускаем argc, argv и NULL
    mov [envp_addr], rsi    ; Сохраняем адрес массива окружения

main_loop:
    ; 2. Вывод приглашения
    mov rax, 1              ; sys_write
    mov rdi, 1
    lea rsi, [prompt]
    mov rdx, prompt_len
    syscall

    ; 3. Чтение ввода
    mov rax, 0              ; sys_read
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 255
    syscall

    ; Если ошибка или пустой ввод (только \n)
    cmp rax, 1
    jle main_loop

    ; 4. Удаляем символ новой строки \n в конце
    mov rcx, rax
    dec rcx                 ; Индекс последнего символа
    mov byte [input_buffer + rcx], 0

    ; 5. Создание процесса (fork)
    mov rax, 57             ; sys_fork
    syscall

    test rax, rax
    js main_loop            ; Ошибка fork
    jz child_process        ; Если 0 — мы в потомке

parent_process:
    ; 6. Ожидание завершения потомка
    mov rdi, rax            ; PID потомка
    mov rax, 61             ; sys_wait4
    lea rsi, [status]
    xor rdx, rdx
    xor r10, r10
    syscall
    jmp main_loop

child_process:
    lea rsi, [input_buffer]
    lea rdi, [argv]
    xor rcx, rcx            ; Счетчик найденных аргументов

.parse_loop:
    ; Пропускаем пробелы перед аргументом
    cmp byte [rsi], ' '
    jne .check_end
    inc rsi
    jmp .parse_loop

.check_end:
    cmp byte [rsi], 0
    je .execute

    ; Сохраняем указатель на начало слова
    mov [rdi + rcx*8], rsi
    inc rcx

    ; Ищем конец слова (пробел или ноль)
.find_word_end:
    cmp byte [rsi], 0
    je .execute
    cmp byte [rsi], ' '
    je .terminate_word
    inc rsi
    jmp .find_word_end

.terminate_word:
    mov byte [rsi], 0       ; Ставим маркер конца строки
    inc rsi
    cmp rcx, 10             ; Защита от переполнения argv
    jl .parse_loop

.execute:
    mov qword [rdi + rcx*8], 0 ; Завершаем argv значением NULL

    ; --- ЗАПУСК ПРОГРАММЫ ---
    mov rax, 59             ; sys_execve
    mov rdi, [argv]         ; Путь к файлу (argv[0])
    lea rsi, [argv]         ; Весь массив аргументов
    mov rdx, [envp_addr]    ; Переменные окружения
    syscall

    ; Если execve вернул управление — значит произошла ошибка
    mov rax, 1
    mov rdi, 1
    lea rsi, [error_msg]
    mov rdx, error_len
    syscall

    mov rax, 60             ; sys_exit
    mov rdi, 1
    syscall
