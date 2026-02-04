format ELF64
public _start

SYS_WRITE       = 1
SYS_READ        = 0
SYS_CLOSE       = 3
SYS_SOCKET      = 41
SYS_ACCEPT      = 43
SYS_BIND        = 49
SYS_LISTEN      = 50
SYS_EXIT        = 60

AF_INET         = 2
SOCK_STREAM     = 1
INADDR_ANY      = 0
MAX_NUMBERS     = 100

section '.data' writeable
    notify_ready    db '[Server started on port 5555]', 10, 0
    notify_client  db '[New connection]', 10, 0
    prompt_msg     db 'Введите числа: ', 0
    result_avg     db 'Average: ', 0
    result_median  db 'Median: ', 0
    newline        db 10, 0
    error_msg      db 'Error: No numbers provided', 10, 0

    ; Буферы
    input_buffer   rb 256
    output_buffer  rb 256

    ; Массив чисел
    numbers        dq MAX_NUMBERS dup(0)
    num_count      dq 0

    ; Для вычислений
    sum            dq 0
    average_int    dq 0
    median_int     dq 0
    median_frac    dq 0

    host_address:
        dw AF_INET
        db 0x15, 0xB3    ; Порт 5555
        dd INADDR_ANY
        dq 0

    main_socket    dq 0
    client_socket  dq 0

section '.text' executable
_start:
    ; Создаем сокет
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
    mov [main_socket], rax

    ; Биндим сокет
    mov rax, SYS_BIND
    mov rdi, [main_socket]
    mov rsi, host_address
    mov rdx, 16
    syscall

    ; Слушаем соединения
    mov rax, SYS_LISTEN
    mov rdi, [main_socket]
    mov rsi, 5
    syscall

    ; Уведомляем о запуске
    mov rsi, notify_ready
    call print_string

server_loop:
    ; Принимаем соединение
    mov rax, SYS_ACCEPT
    mov rdi, [main_socket]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [client_socket], rax

    mov rsi, notify_client
    call print_string

    ; Инициализируем переменные для нового соединения
    mov qword [num_count], 0
    mov qword [sum], 0

    ; Очищаем массив чисел
    mov rdi, numbers          ; Адрес начала массива
    mov rcx, MAX_NUMBERS      ; Количество элементов
    xor rax, rax
.clear_array_loop:
    mov [rdi], rax
    add rdi, 8
    loop .clear_array_loop

    ; Отправляем приглашение
    mov rsi, prompt_msg
    call send_to_client

read_input:
    ; Читаем данные от клиента
    mov rax, SYS_READ
    mov rdi, [client_socket]
    mov rsi, input_buffer
    mov rdx, 255
    syscall

    cmp rax, 0
    jle close_connection

    ; Нуль-терминируем буфер
    mov byte [input_buffer + rax], 0

    ; Ищем символ '#' - конец ввода
    mov rdi, input_buffer     ; Начало буфера
    mov rcx, rax              ; Длина прочитанных данных
    mov al, '#'
    xor rbx, rbx              ; Флаг найден ли символ
.search_hash_loop:
    cmp rcx, 0
    je .search_done
    cmp [rdi], al
    je .hash_found
    inc rdi
    dec rcx
    jmp .search_hash_loop

.hash_found:
    mov rbx, 1                ; Устанавливаем флаг "найдено"

.search_done:
    test rbx, rbx             ; Проверяем флаг
    jnz found_hash            ; Если нашли '#', обрабатываем

    ; Если не нашли, парсим числа и продолжаем чтение
    mov rsi, input_buffer
    call parse_numbers
    jmp read_input

found_hash:
    ; Нашли '#', обрабатываем ввод
    mov byte [rdi], 0         ; Заменяем '#' на 0

    ; Парсим числа
    mov rsi, input_buffer
    call parse_numbers

    ; Вычисляем среднее
    call calculate_average

    ; Вычисляем медиану
    call calculate_median

    ; Отправляем результаты
    call send_results

    ; Закрываем соединение
    jmp close_connection

parse_and_continue:
    ; Парсим текущий буфер и продолжаем чтение
    mov rsi, input_buffer
    call parse_numbers
    jmp read_input

parse_numbers:
    ; Парсит числа из строки в rsi, добавляет в массив numbers
    push rbx
    push r12
    push r13

    xor r12, r12        ; текущее число
    xor bl, bl          ; флаг отрицательности
    xor r13b, r13b      ; флаг: была ли хоть одна цифра в текущем числе

.parse_loop:
    mov al, [rsi]
    test al, al
    jz .end_of_string

    cmp al, '-'
    je .handle_minus

    cmp al, ' '
    je .handle_space

    cmp al, 9           ; табуляция
    je .handle_space

    cmp al, 10          ; новая строка
    je .handle_space

    cmp al, '0'
    jl .not_digit
    cmp al, '9'
    jg .not_digit

    ; Это цифра
    mov r13b, 1
    sub al, '0'
    movzx rdx, al
    imul r12, 10
    add r12, rdx
    jmp .next_char

.handle_minus:
    ; Проверяем, что минус стоит в начале числа
    test r13b, r13b
    jnz .not_digit
    mov bl, 1
    jmp .next_char

.handle_space:
    ; Если это пробельный символ и у нас было число - сохраняем его
    test r13b, r13b
    je .next_char
    call .save_number
    xor r12, r12
    xor bl, bl
    xor r13b, r13b
    jmp .next_char

.not_digit:
    ; Если это не цифра и не минус, и у нас было число - сохраняем его
    test r13b, r13b
    je .next_char

    ; Сохраняем текущее число
    call .save_number
    xor r12, r12
    xor bl, bl
    xor r13b, r13b

.next_char:
    inc rsi
    jmp .parse_loop

.end_of_string:
    ; Если строка закончилась, но у нас было число - сохраняем его
    test r13b, r13b
    je .done
    call .save_number

.done:
    pop r13
    pop r12
    pop rbx
    ret

.save_number:
    ; Сохраняет число в r12 со знаком из bl
    test bl, bl
    jz .positive
    neg r12

.positive:
    ; Проверяем, не превышен ли лимит
    mov rax, [num_count]
    cmp rax, MAX_NUMBERS
    jge .skip

    ; Сохраняем в массив
    mov rcx, rax
    shl rcx, 3
    mov [numbers + rcx], r12
    inc qword [num_count]

    ; Добавляем к сумме
    add [sum], r12

.skip:
    ret

; Сортировка пузырьком для массива чисел
bubble_sort:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rcx, [num_count]
    cmp rcx, 1
    jle .done

    dec rcx  ; внешний цикл

.outer_loop:
    xor rdx, rdx  ; флаг обмена
    mov rsi, 0    ; внутренний индекс
    mov rdi, rcx  ; предел для внутреннего цикла

.inner_loop:
    mov rax, [numbers + rsi*8]
    mov rbx, [numbers + rsi*8 + 8]
    cmp rax, rbx
    jle .no_swap

    ; Обмен
    mov [numbers + rsi*8], rbx
    mov [numbers + rsi*8 + 8], rax
    mov rdx, 1

.no_swap:
    inc rsi
    cmp rsi, rdi
    jl .inner_loop

    test rdx, rdx
    jz .done

    loop .outer_loop

.done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

calculate_average:
    ; Вычисляет среднее значение
    push rbx
    push rcx
    push rdx

    ; Проверяем, есть ли числа
    mov rax, [num_count]
    test rax, rax
    jz .no_numbers

    ; sum * 100
    mov rax, [sum]
    mov rbx, 100
    imul rbx        ; rdx:rax = sum * 100

    ; Делим на количество (знаковое деление)
    mov rcx, [num_count]
    cqo             ; Знаковое расширение rax -> rdx:rax
    idiv rcx        ; rax = (sum * 100) / count

    mov [average_int], rax
    jmp .done

.no_numbers:
    mov qword [average_int], 0

.done:
    pop rdx
    pop rcx
    pop rbx
    ret

calculate_median:
    ; Вычисляет медианное значение
    push rbx
    push rcx
    push rdx
    push rsi

    ; Проверяем, есть ли числа
    mov rax, [num_count]
    test rax, rax
    jz .no_numbers

    cmp rax, 1
    je .single_number

    ; Сортируем массив
    call bubble_sort

    ; Получаем количество элементов
    mov rcx, [num_count]

    ; Проверяем четность количества
    test rcx, 1
    jnz .odd_count

    ; Четное количество: медиана = (numbers[n/2 - 1] + numbers[n/2]) / 2
    shr rcx, 1        ; n/2

    ; Проверяем, что не ноль
    cmp rcx, 0
    je .error

    ; Берем два средних числа
    mov rax, [numbers + (rcx-1)*8]  ; numbers[n/2 - 1]
    mov rbx, [numbers + rcx*8]      ; numbers[n/2]

    ; Складываем и умножаем на 50 (это (a+b)/2 * 100)
    add rax, rbx
    imul rax, 50       ; (a+b) * 50 = (a+b)/2 * 100

    mov [median_int], rax
    jmp .done

.single_number:
    ; Одно число
    mov rax, [numbers]
    imul rax, 100
    mov [median_int], rax
    jmp .done

.odd_count:
    ; Нечетное количество: медиана = numbers[n/2]
    shr rcx, 1        ; n/2

    mov rax, [numbers + rcx*8]
    imul rax, 100
    mov [median_int], rax
    jmp .done

.error:
    mov qword [median_int], 0
    jmp .done

.no_numbers:
    mov qword [median_int], 0

.done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

send_results:
    ; Проверяем, есть ли числа
    mov rax, [num_count]
    test rax, rax
    jz .send_error

    ; 1. Отправляем среднее значение
    mov rsi, result_avg
    call send_to_client

    ; Форматируем среднее
    mov rdi, output_buffer
    mov rax, [average_int]
    call format_number

    ; Отправляем среднее
    mov rsi, output_buffer
    call send_to_client

    ; Перенос строки
    mov rsi, newline
    call send_to_client

    ; 2. Отправляем медианное значение
    mov rsi, result_median
    call send_to_client

    ; Форматируем медиану
    mov rdi, output_buffer
    mov rax, [median_int]
    call format_number

    ; Отправляем медиану
    mov rsi, output_buffer
    call send_to_client

    ; Перенос строки
    mov rsi, newline
    call send_to_client

    ret

.send_error:
    mov rsi, error_msg
    call send_to_client
    ret

format_number:
    ; Форматирует число: rax = число * 100 (уже умноженное на 100)
    ; Результат в rdi
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

    ; Проверяем знак
    test rax, rax
    jns .positive

    ; Отрицательное число
    mov byte [rdi], '-'
    inc rdi
    neg rax

.positive:
    ; rax содержит число * 100
    ; Разделяем на целую и дробную части
    mov rbx, 100
    xor rdx, rdx
    div rbx  ; rax = целая часть, rdx = дробная часть (0-99)

    ; Конвертируем целую часть в строку
    push rdx  ; сохраняем дробную часть

    test rax, rax
    jnz .convert_int

    ; Если целая часть = 0
    mov byte [rdi], '0'
    inc rdi
    jmp .add_decimal

.convert_int:
    mov rbx, 10
    xor rcx, rcx

.int_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .int_loop

.store_int:
    pop rax
    mov [rdi], al
    inc rdi
    loop .store_int

.add_decimal:
    ; Добавляем десятичную точку
    mov byte [rdi], '.'
    inc rdi

    ; Получаем дробную часть
    pop rax  ; получаем дробную часть (0-99)

    ; Конвертируем в 2 цифры
    cmp rax, 10
    jge .two_digits

    ; Одна цифра, добавляем ведущий ноль
    mov byte [rdi], '0'
    inc rdi
    add al, '0'
    mov [rdi], al
    inc rdi
    jmp .done

.two_digits:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add al, '0'
    add dl, '0'
    mov [rdi], al
    inc rdi
    mov [rdi], dl
    inc rdi

.done:
    ; Завершаем строку
    mov byte [rdi], 0

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

send_to_client:
    ; Отправляет строку по адресу rsi клиенту
    push rdi
    push rsi
    push rdx
    push rax
    push rcx
    push r11

    ; Вычисляем длину строки
    mov rdi, rsi
    call strlen

    ; Отправляем данные
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, [client_socket]
    syscall

    pop r11
    pop rcx
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

close_connection:
    ; Закрываем соединение с клиентом
    mov rax, SYS_CLOSE
    mov rdi, [client_socket]
    syscall

    ; Возвращаемся к ожиданию нового соединения
    jmp server_loop

print_string:
    ; Выводит строку по адресу rsi в stdout
    push rdi
    push rsi
    push rdx
    push rax
    push rcx
    push r11

    mov rdi, rsi
    call strlen

    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall

    pop r11
    pop rcx
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

strlen:
    ; Вычисляет длину строки по адресу rdi
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret