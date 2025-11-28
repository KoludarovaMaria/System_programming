format ELF64 executable  ; Формат для 64-битного Linux ELF исполняемого файла

segment readable executable  ; Сегмент для исполняемого кода
entry _start                 ; Точка входа в программу

_start:
    pop rcx                 ; Получить количество аргументов (argc) из стека
    cmp rcx, 3              ; Сравнить с ожидаемым количеством (3: program, input, output)
    jne error_arguments     ; Если не равно, перейти к ошибке аргументов

    pop rdi                 ; Пропустить первый аргумент (имя программы)
    pop rdi                 ; Получить второй аргумент (имя входного файла)

    ; Открытие входного файла
    mov rax, 2              ; Номер системного вызова sys_open
    mov rsi, 0              ; Флаги: O_RDONLY (только чтение)
    mov rdx, 0              ; Режим доступа (не используется для чтения)
    syscall                 ; Вызов системного вызова
    
    cmp rax, 0              ; Проверить результат открытия файла
    jl error_open_input_file ; Если отрицательный (ошибка), перейти к обработке ошибки
    mov [input_fd], rax     ; Сохранить файловый дескриптор входного файла
    
    pop rdi                 ; Получить третий аргумент (имя выходного файла)

    ; Открытие выходного файла
    mov rax, 2              ; Номер системного вызова sys_open
    mov rsi, 0x41           ; Флаги: O_CREAT | O_WRONLY | O_TRUNC (создать, запись, очистить)
    mov rdx, 0644o          ; Режим доступа: rw-r--r-- (в восьмеричной системе)
    syscall                 ; Вызов системного вызова
    
    cmp rax, 0              ; Проверить результат открытия файла
    jl error_open_output_file ; Если отрицательный (ошибка), перейти к обработке ошибки
    mov [output_fd], rax    ; Сохранить файловый дескриптор выходного файла
    
    mov byte [in_number], 0 ; Инициализировать флаг "в числе" в 0 (false)
    
read_loop:
    ; Чтение данных из входного файла
    mov rax, 0              ; Номер системного вызова sys_read
    mov rdi, [input_fd]     ; Файловый дескриптор входного файла
    mov rsi, buffer         ; Указатель на буфер для чтения
    mov rdx, 1024           ; Размер буфера (1024 байта)
    syscall                 ; Вызов системного вызова
    
    cmp rax, 0              ; Проверить количество прочитанных байтов
    jle process_final_number ; Если <= 0 (конец файла или ошибка), обработать последнее число
    
    mov rcx, rax            ; Сохранить количество прочитанных байтов в RCX
    mov rsi, buffer         ; Указатель на начало буфера
    
process_buffer:
    mov al, [rsi]           ; Загрузить текущий символ из буфера
    
    ; Проверка является ли символ цифрой (0-9)
    cmp al, '0'             ; Сравнить с '0'
    jb not_digit            ; Если меньше, это не цифра
    cmp al, '9'             ; Сравнить с '9'
    ja not_digit            ; Если больше, это не цифра

    call add_to_number      ; Вызов функции добавления цифры к текущему числу
    jmp next_char           ; Перейти к следующему символу
    
not_digit:
    cmp byte [in_number], 1 ; Проверить флаг "в числе"
    jne next_char           ; Если не в числе, перейти к следующему символу
    call finish_number      ; Если был в числе, завершить число
    
next_char:
    inc rsi                 ; Перейти к следующему символу в буфере
    loop process_buffer     ; Повторить для всех символов в буфере (RCX раз)
    jmp read_loop           ; Продолжить чтение файла

process_final_number:
    cmp byte [in_number], 1 ; Проверить, обрабатывалось ли число в конце
    jne exit_program        ; Если нет, выйти из программы
    call finish_number      ; Завершить последнее число

exit_program:
    ; Закрытие входного файла
    mov rax, 3              ; Номер системного вызова sys_close
    mov rdi, [input_fd]     ; Файловый дескриптор входного файла
    syscall                 ; Вызов системного вызова
    
    ; Закрытие выходного файла
    mov rax, 3              ; Номер системного вызова sys_close
    mov rdi, [output_fd]    ; Файловый дескриптор выходного файла
    syscall                 ; Вызов системного вызова
    
    ; Завершение программы
    mov rax, 60             ; Номер системного вызова sys_exit
    mov rdi, 0              ; Код возврата 0 (успех)
    syscall                 ; Вызов системного вызова

; Функция добавления цифры к текущему числу
add_to_number:
    push rsi                ; Сохранить регистры
    push rcx
    
    mov rdi, number_buffer  ; Указатель на буфер числа
    cmp byte [in_number], 0 ; Проверить, это первая цифра числа?
    je .first_digit         ; Если да, перейти к обработке первой цифры
    
.find_end:
    cmp byte [rdi], 0       ; Найти конец текущего числа (нулевой байт)
    je .add_digit           ; Если найден, добавить цифру
    inc rdi                 ; Перейти к следующему байту
    jmp .find_end           ; Продолжить поиск
    
.first_digit:
    mov byte [in_number], 1 ; Установить флаг "в числе" в 1 (true)
    
.add_digit:
    mov [rdi], al           ; Добавить цифру в буфер числа
    inc rdi                 ; Переместить указатель на следующую позицию
    mov byte [rdi], 0       ; Добавить нулевой байт (терминатор строки)
    
    pop rcx                 ; Восстановить регистры
    pop rsi
    ret                     ; Возврат из функции

; Функция завершения обработки числа
finish_number:
    push rsi                ; Сохранить регистры
    push rcx
    
    cmp byte [number_buffer], 0 ; Проверить, есть ли число в буфере
    je .done                ; Если нет, завершить
    
    mov rdi, [output_fd]    ; Файловый дескриптор выходного файла
    mov rsi, number_buffer  ; Указатель на буфер числа
    call write_string       ; Записать число в файл
    
    mov rdi, [output_fd]    ; Файловый дескриптор выходного файла
    mov rsi, space          ; Указатель на строку с пробелом
    call write_string       ; Записать пробел после числа
    
    ; Очистка буфера числа
    mov rdi, number_buffer  ; Указатель на буфер числа
    mov rcx, 32             ; Количество байтов для очистки
    xor al, al              ; AL = 0 (значение для заполнения)
    rep stosb               ; Повторно заполнить буфер нулями (RCX раз)
    
.done:
    mov byte [in_number], 0 ; Сбросить флаг "в числе" в 0 (false)
    pop rcx                 ; Восстановить регистры
    pop rsi
    ret                     ; Возврат из функции

; Функция записи строки в файл
write_string:
    push rcx                ; Сохранить регистры
    push rdx
    push rsi

    mov rdx, rsi            ; Начало строки для вычисления длины
.find_length:
    cmp byte [rdx], 0       ; Поиск нулевого байта (конца строки)
    je .found_length        ; Если найден, перейти к вычислению длины
    inc rdx                 ; Перейти к следующему байту
    jmp .find_length        ; Продолжить поиск
    
.found_length:
    sub rdx, rsi            ; Вычислить длину строки (конец - начало)
    mov rax, 1              ; Номер системного вызова sys_write
    syscall                 ; Вызов системного вызова
    
    pop rsi                 ; Восстановить регистры
    pop rdx
    pop rcx
    ret                     ; Возврат из функции

; Функция записи сообщения об ошибке в stderr
write_error:
    push rcx                ; Сохранить регистры
    push rdx
    
    mov rdx, rsi            ; Начало строки для вычисления длины
.find_error_length:
    cmp byte [rdx], 0       ; Поиск нулевого байта (конца строки)
    je .found_error_length  ; Если найден, перейти к вычислению длины
    inc rdx                 ; Перейти к следующему байту
    jmp .find_error_length  ; Продолжить поиск
    
.found_error_length:
    sub rdx, rsi            ; Вычислить длину строки (конец - начало)
    mov rax, 1              ; Номер системного вызова sys_write
    mov rdi, 2              ; Файловый дескриптор stderr (стандартный вывод ошибок)
    syscall                 ; Вызов системного вызова
    
    pop rdx                 ; Восстановить регистры
    pop rcx
    ret                     ; Возврат из функции

; Обработчики ошибок
error_arguments:
    mov rsi, error_argc     ; Указатель на сообщение об ошибке аргументов
    call write_error        ; Вывод сообщения об ошибке
    jmp exit_error          ; Переход к завершению с ошибкой

error_open_input_file:
    mov rsi, error_open_input ; Указатель на сообщение об ошибке открытия входного файла
    call write_error        ; Вывод сообщения об ошибке
    jmp exit_error          ; Переход к завершению с ошибкой

error_open_output_file:
    mov rsi, error_open_output ; Указатель на сообщение об ошибке открытия выходного файла
    call write_error        ; Вывод сообщения об ошибке
    jmp exit_error          ; Переход к завершению с ошибкой

exit_error:
    mov rax, 60             ; Номер системного вызова sys_exit
    mov rdi, 1              ; Код возврата 1 (ошибка)
    syscall                 ; Вызов системного вызова

; Сегмент данных
segment readable writeable

; Сообщения об ошибках и служебные строки
error_argc db "Usage: ./program input_file output_file", 10, 0  ; Сообщение о неправильном использовании
error_open_input db "Error: Cannot open input file", 10, 0      ; Ошибка открытия входного файла
error_open_output db "Error: Cannot open output file", 10, 0    ; Ошибка открытия выходного файла
space db " ", 0               ; Строка с пробелом для разделения чисел
newline db 10, 0              ; Строка с переводом строки

; Файловые дескрипторы
input_fd dq 1                 ; Дескриптор входного файла
output_fd dq 1                ; Дескриптор выходного файла

; Буферы
buffer rb 1024                ; Буфер для чтения из файла (1024 байта)
number_buffer rb 32           ; Буфер для сборки числа (32 байта)
in_number rb 1                ; Флаг: 1 = обрабатывается число, 0 = нет