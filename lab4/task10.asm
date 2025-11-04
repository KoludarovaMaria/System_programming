format ELF64

section '.data' writable
    prompt db "Введите пароль: ", 0
    prompt_len = $ - prompt
    correct db "password123", 0
    success db "Вошли", 10, 0
    success_len = $ - success
    wrong db "Неверный пароль", 10, 0
    wrong_len = $ - wrong
    failure db "Неудача", 10, 0
    failure_len = $ - failure
    attempt_msg db " (попытка ", 0
    attempt_msg_len = $ - attempt_msg
    slash db "/5)", 10, 0
    slash_len = $ - slash

section '.bss' writable
    input rb 50
    attempts rd 1

section '.text' executable
public _start

_start:
    mov dword [attempts], 0                  ; Инициализация счетчика попыток

auth_loop:
    mov eax, [attempts]                      ; Загружаем текущее количество попыток
    cmp eax, 5                               ; Сравниваем с 5
    jge auth_failure                         ; Если >= 5, переходим к блокировке

    ; Вывод приглашения для ввода пароля
    mov eax, 4                               ; sys_write
    mov ebx, 1                               ; stdout
    mov ecx, prompt                          ; строка приглашения
    mov edx, prompt_len                      ; длина строки
    int 0x80

    ; Вывод сообщения о номере попытки
    mov eax, 4                               ; sys_write
    mov ebx, 1                               ; stdout
    mov ecx, attempt_msg                     ; строка " (попытка "
    mov edx, attempt_msg_len                 ; длина строки
    int 0x80

    ; Вывод номера текущей попытки
    mov eax, [attempts]                      ; загружаем номер попытки
    inc eax                                  ; увеличиваем на 1
    add al, '0'                              ; преобразуем число в символ
    mov [input], al                          ; сохраняем символ в буфер
    mov eax, 4                               ; sys_write
    mov ebx, 1                               ; stdout
    mov ecx, input                           ; буфер с символом
    mov edx, 1                               ; длина 1 символ
    int 0x80

    ; Вывод информации о максимальном количестве попыток
    mov eax, 4                               ; sys_write
    mov ebx, 1                               ; stdout
    mov ecx, slash                           ; строка "/5)"
    mov edx, slash_len                       ; длина строки
    int 0x80

    ; Чтение ввода пользователя
    mov eax, 3                               ; sys_read
    mov ebx, 0                               ; stdin
    mov ecx, input                           ; буфер для ввода
    mov edx, 50                              ; максимальная длина
    int 0x80

    ; Удаление символа новой строки из ввода
    mov esi, input                           ; указатель на начало буфера
find_newline:
    cmp byte [esi], 10                       ; ищем символ новой строки
    je remove_newline                        ; если нашли - удаляем
    inc esi                                  ; следующий символ
    jmp find_newline                         ; продолжаем поиск
remove_newline:
    mov byte [esi], 0                        ; заменяем символ новой строки на нулевой

    ; Сравнение введенного пароля с правильным
    mov esi, input                           ; указатель на введенную строку
    mov edi, correct                         ; указатель на правильный пароль
compare_loop:
    mov al, [esi]                            ; символ из ввода
    mov bl, [edi]                            ; символ из правильного пароля
    cmp al, bl                               ; сравниваем символы
    jne password_wrong                       ; если не равны - неверный пароль
    cmp al, 0                                ; проверяем конец строки
    je password_correct                      ; если конец - пароль верный
    inc esi                                  ; следующий символ ввода
    inc edi                                  ; следующий символ пароля
    jmp compare_loop                         ; продолжаем сравнение

password_correct:
    ; Вывод сообщения об успешном входе
    mov eax, 4                               ; sys_write
    mov ebx, 1                               ; stdout
    mov ecx, success                         ; строка "Вошли"
    mov edx, success_len                     ; длина строки
    int 0x80
    jmp exit_success                         ; переходим к успешному завершению

password_wrong:
    ; Вывод сообщения о неверном пароле
    mov eax, 4                               ; sys_write
    mov ebx, 1                               ; stdout
    mov ecx, wrong                           ; строка "Неверный пароль"
    mov edx, wrong_len                       ; длина строки
    int 0x80
    inc dword [attempts]                     ; увеличиваем счетчик попыток
    jmp auth_loop                            ; возвращаемся к началу цикла

auth_failure:
    ; Вывод сообщения о блокировке
    mov eax, 4                               ; sys_write
    mov ebx, 1                               ; stdout
    mov ecx, failure                         ; строка "Неудача"
    mov edx, failure_len                     ; длина строки
    int 0x80

exit_success:
    ; Завершение программы
    mov eax, 1                               ; sys_exit
    xor ebx, ebx                             ; код возврата 0
    int 0x80