format ELF executable
entry _start

segment readable executable
_start:
    ; РЕВЕРС СТРОКИ
    mov ecx, str_len          ; Загружаем длину строки в ECX для цикла (22)
    mov esi, string + str_len - 1  ; ESI указывает на последний символ строки 'g'
    mov edi, reversed          ; EDI указывает на начало буфера для результата
    
reverse_loop:
    std                        ; Установить флаг направления (идём назад по исходной строке)
    lodsb                      ; Загрузить символ из [ESI] в AL, ESI уменьшается
    cld                        ; Сбросить флаг направления (идём вперёд по результату)
    stosb                      ; Записать AL в [EDI], EDI увеличивается
    loop reverse_loop          ; Повторить 22 раза
    
    ; ВЫВОД "Original: "
    mov eax, 4                 ; Системный вызов write
    mov ebx, 1                 ; stdout (экран)
    mov ecx, msg_original      ; Адрес строки "Original: "
    mov edx, msg_original_len  ; Длина строки (10 символов)
    int 0x80                   ; Выполнить системный вызов
    
    ; ВЫВОД ИСХОДНОЙ СТРОКИ
    mov eax, 4                 ; write
    mov ebx, 1                 ; stdout
    mov ecx, string            ; Адрес строки 'FLVHIfsCdaXtJEzRKmmBidg'
    mov edx, str_len           ; Длина (22 символа)
    int 0x80                   ; Вывести строку
    
    ; ПЕРЕВОД СТРОКИ
    mov eax, 4                 ; write
    mov ebx, 1                 ; stdout
    mov ecx, newline           ; Адрес символа перевода строки
    mov edx, 1                 ; Длина 1 символ
    int 0x80                   ; Вывести \n
    
    ; ВЫВОД "Reversed: "
    mov eax, 4                 ; write
    mov ebx, 1                 ; stdout
    mov ecx, msg_reversed      ; Адрес строки "Reversed: "
    mov edx, msg_reversed_len  ; Длина строки (9 символов)
    int 0x80                   ; Вывести "Reversed: "
    
    ; ВЫВОД ПЕРЕВЁРНУТОЙ СТРОКИ
    mov eax, 4                 ; write
    mov ebx, 1                 ; stdout
    mov ecx, reversed          ; Адрес перевёрнутой строки
    mov edx, str_len           ; Длина (22 символа)
    int 0x80                   ; Вывести перевёрнутую строку
    
    ; ПЕРЕВОД СТРОКИ
    mov eax, 4                 ; write
    mov ebx, 1                 ; stdout
    mov ecx, newline           ; Адрес символа перевода строки
    mov edx, 1                 ; Длина 1 символ
    int 0x80                   ; Вывести \n
    
    ; ЗАВЕРШЕНИЕ ПРОГРАММЫ
    mov eax, 1                 ; Системный вызов exit
    xor ebx, ebx               ; Код возврата 0
    int 0x80                   ; Завершить программу

segment readable writeable
    string db 'FLVHIfsCdaXtJEzRKmmBidg', 0  ; Исходная строка с нулём в конце
    str_len = $ - string - 1                ; Вычисляем длину: 23 - 1 = 22
    msg_original db 'Original: '            ; Текст для вывода перед исходной строкой
    msg_original_len = $ - msg_original     ; Длина текста "Original: " = 10
    msg_reversed db 'Reversed: '            ; Текст для вывода перед перевёрнутой строкой
    msg_reversed_len = $ - msg_reversed     ; Длина текста "Reversed: " = 9
    newline db 10                           ; Символ перевода строки (\n)
    reversed rb 30                          ; Резервируем 30 байт для перевёрнутой строки