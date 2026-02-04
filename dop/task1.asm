format ELF64 executable 3
entry start

; Системные вызовы
SYS_READ = 0
SYS_WRITE = 1
SYS_OPEN = 2
SYS_CLOSE = 3
SYS_EXIT = 60
SYS_BRK = 12

; Флаги открытия файла
O_RDONLY = 0
O_WRONLY = 1
O_CREAT = 64
O_TRUNC = 512

; Права доступа к файлу
S_IRUSR = 256   ; 0400
S_IWUSR = 128   ; 0200

STDIN = 0
STDOUT = 1
STDERR = 2

BUFFER_SIZE = 4096

segment readable executable

start:
    ; Проверяем количество аргументов
    pop rcx                     ; argc
    cmp rcx, 2
    jl .error_args
    
    ; Получаем имя входного файла
    pop rsi                     ; argv[0] - имя программы
    pop rsi                     ; argv[1] - имя входного файла
    mov [input_filename], rsi
    
    ; Открываем входной файл
    mov rax, SYS_OPEN
    mov rdi, [input_filename]
    mov rsi, O_RDONLY
    syscall
    cmp rax, 0
    jl .error_open_input
    mov [input_fd], rax
    
    ; Читаем файл и парсим числа
    call read_numbers
    
    ; Закрываем входной файл
    mov rax, SYS_CLOSE
    mov rdi, [input_fd]
    syscall
    
    ; Сортируем числа
    mov rsi, [numbers_count]
    cmp rsi, 0
    je .no_numbers
    call bubble_sort
    
.no_numbers:
    ; Запрашиваем имя выходного файла
    mov rdi, prompt_msg
    call print_string
    
    ; Читаем имя файла от пользователя
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, output_filename
    mov rdx, 255
    syscall
    
    ; Убираем символ новой строки
    mov rsi, output_filename
    add rsi, rax
    dec rsi
    mov byte [rsi], 0
    
    ; Создаем/открываем выходной файл
    mov rax, SYS_OPEN
    mov rdi, output_filename
    mov rsi, O_WRONLY or O_CREAT or O_TRUNC
    mov rdx, S_IRUSR or S_IWUSR
    syscall
    cmp rax, 0
    jl .error_open_output
    mov [output_fd], rax
    
    ; Записываем отсортированные числа
    call write_numbers
    
    ; Закрываем выходной файл
    mov rax, SYS_CLOSE
    mov rdi, [output_fd]
    syscall
    
    ; Выводим сообщение об успехе
    mov rdi, success_msg
    call print_string
    
    ; Завершаем программу
    jmp .exit

.error_args:
    mov rdi, error_args_msg
    call print_string
    jmp .exit

.error_open_input:
    mov rdi, error_open_input_msg
    call print_string
    jmp .exit

.error_open_output:
    mov rdi, error_open_output_msg
    call print_string
    jmp .exit

.exit:
    ; Освобождаем память
    mov rax, SYS_BRK
    mov rdi, [heap_start]
    syscall
    
    ; Завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; ---------------------------------------------------------
; Чтение чисел из файла
; ---------------------------------------------------------
read_numbers:
    push rbx
    push r12
    push r13
    
    ; Запрашиваем память для чисел
    mov rax, SYS_BRK
    xor rdi, rdi
    syscall
    mov [heap_start], rax
    mov [numbers_ptr], rax
    
    add rax, 1024 * 1024 * 8    ; 8MB для чисел (1 млн чисел)
    mov rdi, rax
    mov rax, SYS_BRK
    syscall
    
    mov r12, [numbers_ptr]      ; Текущий указатель
    xor r13, r13                ; Счетчик чисел
    mov rbx, buffer             ; Буфер для чтения
    
.read_loop:
    ; Читаем порцию данных
    mov rax, SYS_READ
    mov rdi, [input_fd]
    mov rsi, rbx
    mov rdx, BUFFER_SIZE
    syscall
    
    cmp rax, 0
    jle .read_done
    
    mov rcx, rax                ; Количество прочитанных байт
    mov rsi, rbx                ; Указатель на данные
    
.process_buffer:
    cmp rcx, 0
    je .read_loop
    
    ; Пропускаем пробелы и переводы строк
    mov al, [rsi]
    cmp al, ' '
    je .skip_char
    cmp al, 9                   ; TAB
    je .skip_char
    cmp al, 10                  ; LF
    je .skip_char
    cmp al, 13                  ; CR
    je .skip_char
    
    ; Проверяем, что это цифра или минус
    cmp al, '-'
    je .start_number
    cmp al, '0'
    jb .invalid_char
    cmp al, '9'
    ja .invalid_char
    
.start_number:
    xor edx, edx                ; Отрицательный флаг
    cmp al, '-'
    jne .parse_digit
    mov dl, 1                   ; Устанавливаем флаг отрицательного
    inc rsi
    dec rcx
    jz .read_loop
    mov al, [rsi]
    
.parse_digit:
    xor r8d, r8d                ; Накопленное число
    
.digit_loop:
    sub al, '0'
    jb .number_done
    cmp al, 9
    ja .number_done
    
    imul r8, 10
    add r8, rax
    
    inc rsi
    dec rcx
    jz .store_number
    
    mov al, [rsi]
    jmp .digit_loop
    
.number_done:
    test rdx, rdx
    jz .store_number
    neg r8
    
.store_number:
    mov [r12], r8
    add r12, 8
    inc r13
    
    ; Пропускаем остальные символы до разделителя
    jmp .skip_after_number

.skip_char:
    inc rsi
    dec rcx
    jmp .process_buffer

.skip_after_number:
    cmp rcx, 0
    je .process_buffer
    mov al, [rsi]
    cmp al, ' '
    je .skip_char
    cmp al, 9
    je .skip_char
    cmp al, 10
    je .skip_char
    cmp al, 13
    je .skip_char
    ; Если не разделитель, то это начало нового числа
    jmp .process_buffer

.invalid_char:
    ; Просто пропускаем недопустимый символ
    inc rsi
    dec rcx
    jmp .process_buffer

.read_done:
    mov [numbers_count], r13
    mov [numbers_ptr_end], r12
    
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------
; Сортировка пузырьком
; ---------------------------------------------------------
bubble_sort:
    push rbx
    push r12
    push r13
    
    mov r12, [numbers_ptr]      ; Начало массива
    mov r13, [numbers_count]    ; Количество элементов
    dec r13                     ; i = n-1
    
.outer_loop:
    cmp r13, 0
    jle .sort_done
    
    mov rcx, 0                  ; j = 0
    
.inner_loop:
    cmp rcx, r13
    jge .inner_done
    
    ; Получаем числа[j] и числа[j+1]
    mov rax, [r12 + rcx*8]
    mov rbx, [r12 + rcx*8 + 8]
    
    ; Сравниваем
    cmp rax, rbx
    jle .no_swap
    
    ; Меняем местами
    mov [r12 + rcx*8], rbx
    mov [r12 + rcx*8 + 8], rax
    
.no_swap:
    inc rcx
    jmp .inner_loop
    
.inner_done:
    dec r13
    jmp .outer_loop

.sort_done:
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------
; Запись чисел в файл
; ---------------------------------------------------------
write_numbers:
    push rbx
    push r12
    push r13
    
    ; Инициализируем буфер
    mov qword [buffer_ptr], buffer
    
    mov r12, [numbers_ptr]
    mov r13, [numbers_count]
    xor rbx, rbx                ; Индекс
    
.write_loop:
    cmp rbx, r13
    jge .write_done
    
    ; Конвертируем число в строку
    mov rax, [r12 + rbx*8]
    mov rdi, number_buffer
    call int_to_string
    
    ; Копируем в буфер
    mov rsi, number_buffer
    mov rdi, [buffer_ptr]
    call copy_string
    mov [buffer_ptr], rdi
    
    ; Добавляем пробел
    mov rdi, [buffer_ptr]
    mov byte [rdi], ' '
    inc qword [buffer_ptr]
    
    ; Проверяем, не заполнен ли буфер
    mov rax, [buffer_ptr]
    sub rax, buffer
    cmp rax, BUFFER_SIZE - 256
    jl .next_number
    
    ; Записываем буфер в файл
    call flush_buffer
    
.next_number:
    inc rbx
    jmp .write_loop

.write_done:
    ; Убираем последний пробел и добавляем перевод строки
    mov rdi, [buffer_ptr]
    dec rdi
    mov byte [rdi], 10
    mov [buffer_ptr], rdi
    inc qword [buffer_ptr]
    
    ; Записываем остаток буфера
    call flush_buffer
    
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------
; Сброс буфера в файл
; ---------------------------------------------------------
flush_buffer:
    push rdi
    push rsi
    push rdx
    
    mov rax, [buffer_ptr]
    sub rax, buffer
    cmp rax, 0
    je .done
    
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, [output_fd]
    mov rsi, buffer
    syscall
    
    ; Сбрасываем указатель буфера
    mov qword [buffer_ptr], buffer
    
.done:
    pop rdx
    pop rsi
    pop rdi
    ret

; ---------------------------------------------------------
; Конвертация целого числа в строку
; Вход: RAX - число, RDI - буфер для строки
; ---------------------------------------------------------
int_to_string:
    push rbx
    push r12
    push rdi
    
    mov rbx, rdi                ; Сохраняем начало буфера
    
    ; Проверяем знак
    test rax, rax
    jns .positive
    
    ; Отрицательное число
    neg rax
    mov byte [rdi], '-'
    inc rdi
    
.positive:
    ; Используем стек для хранения цифр
    mov r12, 10
    xor rcx, rcx
    
.divide_loop:
    xor rdx, rdx
    div r12
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .divide_loop
    
    ; Извлекаем цифры из стека
.pop_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .pop_loop
    
    mov byte [rdi], 0           ; Завершающий ноль
    
    pop rdi
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------
; Копирование строки
; Вход: RSI - источник, RDI - приемник
; Выход: RDI - новый указатель
; ---------------------------------------------------------
copy_string:
    push rax
    
.copy_loop:
    lodsb
    test al, al
    jz .copy_done
    mov [rdi], al
    inc rdi
    jmp .copy_loop
    
.copy_done:
    pop rax
    ret

; ---------------------------------------------------------
; Вывод строки
; Вход: RDI - указатель на строку
; ---------------------------------------------------------
print_string:
    push rsi
    push rdx
    push rax
    push rdi
    
    ; Находим длину строки
    mov rsi, rdi
    xor rdx, rdx
    
.length_loop:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .length_loop
    
.print:
    test rdx, rdx
    jz .done
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    
.done:
    pop rdi
    pop rax
    pop rdx
    pop rsi
    ret

segment readable writeable

; Переменные
input_filename dq 0
output_filename rb 256
input_fd dq 0
output_fd dq 0
numbers_ptr dq 0
numbers_ptr_end dq 0
numbers_count dq 0
heap_start dq 0
buffer_ptr dq buffer

; Буферы
buffer rb BUFFER_SIZE
number_buffer rb 32

; Сообщения
error_args_msg db "Использование: program <input_file>", 10, 0
error_open_input_msg db "Ошибка открытия входного файла", 10, 0
error_open_output_msg db "Ошибка создания выходного файла", 10, 0
prompt_msg db "Введите имя выходного файла: ", 0
success_msg db "Числа успешно отсортированы и сохранены", 10, 0