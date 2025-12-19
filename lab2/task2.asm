format ELF executable
entry _start

segment readable executable
_start:
    ; Вывод заголовка "Matrix 7x15:"
    mov eax, 4              ; Системный вызов write
    mov ebx, 1              ; stdout (экран)
    mov ecx, msg_matrix     ; Адрес строки "Matrix 7x15:"
    mov edx, msg_matrix_len ; Длина строки (13 символов)
    int 0x80                ; Вывести заголовок
    
    ; Заполнение буфера 105 символами '8'
    mov ecx, total_chars    ; Загружаем количество символов (105)
    mov esi, buffer         ; ESI указывает на начало буфера
    mov al, [symbol]        ; Загружаем символ '8' в AL
    
fill_buffer:
    mov [esi], al          ; Записываем '8' в текущую позицию буфера
    inc esi                ; Переходим к следующей ячейке буфера
    loop fill_buffer       ; Повторяем 105 раз
    
    ; Вывод матрицы 7x15 (7 символов в строке, 15 строк)
    mov esi, buffer        ; ESI указывает на начало буфера с символами
    mov ecx, total_lines   ; Загружаем количество строк (15)
    
print_lines:
    push ecx               ; Сохраняем счётчик строк в стек
    
    ; Вывод одной строки матрицы (7 символов)
    mov eax, 4             ; write
    mov ebx, 1             ; stdout
    mov ecx, esi           ; Адрес текущей строки в буфере
    mov edx, chars_per_line ; Длина строки (7 символов)
    int 0x80               ; Вывести 7 символов '8'
    
    ; Переход к следующей строке в буфере
    add esi, chars_per_line ; ESI += 7 (переходим к следующей строке)
    
    ; Вывод перевода строки
    mov eax, 4             ; write
    mov ebx, 1             ; stdout
    mov ecx, newline       ; Адрес символа \n
    mov edx, 1             ; Длина 1 символ
    int 0x80               ; Вывести перевод строки
    
    pop ecx                ; Восстанавливаем счётчик строк из стека
    loop print_lines       ; Повторяем для всех 15 строк
    
    ; Завершение программы
    mov eax, 1             ; Системный вызов exit
    xor ebx, ebx           ; Код возврата 0
    int 0x80               ; Завершить программу

segment readable writeable
    symbol db '8'          ; Символ для заполнения матрицы
    total_chars = 105      ; Всего символов (7×15=105)
    chars_per_line = 7     ; Символов в строке (ширина матрицы)
    total_lines = 15       ; Количество строк (высота матрицы)
    msg_matrix db 'Matrix 7x15:', 10 ; Заголовок с переводом строки
    msg_matrix_len = $ - msg_matrix  ; Длина заголовка (13 байт)
    newline db 10          ; Символ перевода строки
    buffer rb 100          ; Буфер для матрицы (резервируем 100 байт)