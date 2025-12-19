format ELF executable
entry _start

segment readable executable

_start:
    ; Вычисляем сумму цифр числа "3469816182"
    mov esi, num_str       ; ESI указывает на начало строки с цифрами
    mov ecx, 10            ; ECX = 10 (количество цифр для обработки)
    xor ebx, ebx           ; EBX = 0 (здесь будет накапливаться сумма)
    
sum_loop:
    mov al, [esi]          ; AL = текущий символ (например, '3')
    sub al, '0'            ; Преобразуем символ в число (например, '3' → 3)
    add bl, al             ; Добавляем цифру к сумме в BL
    inc esi                ; Переходим к следующей цифре
    loop sum_loop          ; Повторяем для всех 10 цифр

    ; Преобразуем результат (число в BL) в строку
    movzx ax, bl           ; AX = BL (расширяем байт до слова)
    mov edi, result        ; EDI указывает на буфер для результата
    
    cmp al, 10             ; Сравниваем результат с 10
    jb one_digit           ; Если < 10, переходим к обработке однозначного числа
    
    ; Двузначное число (10 и больше)
    mov cl, 10             ; CL = 10 (делитель)
    div cl                 ; Делим AL на 10: AH = остаток, AL = частное
    add al, '0'            ; Преобразуем десятки в символ
    mov [edi], al          ; Сохраняем символ десятков
    inc edi                ; Переходим к следующей позиции
    mov al, ah             ; AL = остаток (единицы)
    
one_digit:
    add al, '0'            ; Преобразуем единицы в символ
    mov [edi], al          ; Сохраняем символ единиц
    inc edi                ; Переходим к следующей позиции
    
    ; Добавляем символ новой строки
    mov byte [edi], 10     ; Добавляем \n в конец строки

    ; Вывод текста "Sum of digits: "
    mov eax, 4             ; write
    mov ebx, 1             ; stdout
    mov ecx, output_text   ; "Sum of digits: "
    mov edx, output_text_len ; длина текста
    int 0x80               ; выводим текст

    ; Вывод результата (суммы цифр)
    mov eax, 4             ; write
    mov ebx, 1             ; stdout
    mov ecx, result        ; буфер с результатом (например, "48\n")
    mov edx, 3             ; длина вывода (2 цифры + \n)
    int 0x80               ; выводим результат

    ; Завершение программы
    mov eax, 1             ; exit
    xor ebx, ebx           ; код возврата 0
    int 0x80               ; завершаем программу

segment readable writeable
    num_str db '3469816182'         ; строка с цифрами
    output_text db 'Sum of digits: ' ; текст для вывода
    output_text_len = $ - output_text ; длина текста (15)
    result rb 3                     ; буфер для результата (2 цифры + \n)