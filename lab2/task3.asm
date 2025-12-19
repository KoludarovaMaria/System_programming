format ELF executable
entry _start

segment readable executable
_start:
    ; Вывод заголовка "Triangle:"
    mov eax, 4                  ; write
    mov ebx, 1                  ; stdout
    mov ecx, msg_triangle       ; "Triangle:"
    mov edx, msg_triangle_len   ; длина строки
    int 0x80                    ; вывести заголовок
    
    mov edi, buffer             ; EDI указывает на начало буфера
    mov ecx, 1                  ; начинаем с 1 символа в строке
    
triangle_loop:
    push ecx                    ; сохраняем счётчик символов
    mov al, [symbol]            ; AL = '8'
    
    ; Заполнение строки символами '8'
    mov ebx, ecx                ; EBX = количество символов в текущей строке
fill_line:
    mov [edi], al               ; записываем '8' в буфер
    inc edi                     ; переходим к следующей ячейке
    dec ebx                     ; уменьшаем счётчик символов
    jnz fill_line               ; повторяем, пока не заполним строку
    
    ; Добавление перевода строки
    mov byte [edi], 10          ; добавляем символ \n
    inc edi                     ; переходим к следующей позиции
    
    pop ecx                     ; восстанавливаем счётчик символов
    inc ecx                     ; увеличиваем для следующей строки
    cmp ecx, total_lines        ; сравниваем с общим числом строк (6)
    jle triangle_loop           ; если <= 6, продолжаем цикл
    
    ; Вывод треугольника из буфера
    mov eax, 4                  ; write
    mov ebx, 1                  ; stdout
    mov ecx, buffer             ; начало буфера
    mov edx, edi                ; текущая позиция в буфере
    sub edx, buffer             ; вычисляем длину (EDX = EDI - buffer)
    int 0x80                    ; выводим весь треугольник
    
    ; Завершение программы
    mov eax, 1                  ; exit
    xor ebx, ebx                ; код возврата 0
    int 0x80                    ; завершить

segment readable writeable
    symbol db '8'               ; символ для построения треугольника
    total_lines = 6             ; всего строк в треугольнике
    msg_triangle db 'Triangle:', 10  ; заголовок
    msg_triangle_len = $ - msg_triangle  ; длина заголовка
    buffer rb 100               ; буфер для хранения треугольника