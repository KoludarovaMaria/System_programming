format ELF64

section '.data' writable
    prompt db "Введите n: ", 0
    prompt_len = $ - prompt
    result db "Количество чисел: ", 0
    result_len = $ - result
    newline db 10

section '.bss' writable
    n rd 1
    count rd 1
    buffer rb 20

section '.text' executable
public _start

_start:
    ; Вывод приглашения для ввода
    mov rax, 1          ; системный вызов write (64-bit)
    mov rdi, 1          ; файловый дескриптор stdout
    mov rsi, prompt     ; указатель на строку
    mov rdx, prompt_len ; длина строки
    syscall             ; системный вызов (64-bit)

    ; Чтение ввода пользователя
    mov rax, 0          ; системный вызов read (64-bit)
    mov rdi, 0          ; файловый дескриптор stdin
    mov rsi, buffer     ; буфер для ввода
    mov rdx, 20         ; максимальная длина
    syscall             ; системный вызов (64-bit)

    ; Преобразование строки в число
    mov rsi, buffer     ; указатель на начало буфера
    xor rax, rax        ; обнуляем rax (здесь будет результат)
    xor rbx, rbx        ; обнуляем rbx
convert_loop:
    mov bl, [rsi]       ; загружаем текущий символ
    cmp bl, 10          ; проверяем на символ новой строки
    je convert_done     ; если конец строки - выходим
    sub bl, '0'         ; преобразуем символ в цифру
    imul rax, 10        ; умножаем текущий результат на 10
    add rax, rbx        ; добавляем новую цифру
    inc rsi             ; переходим к следующему символу
    jmp convert_loop    ; продолжаем цикл
convert_done:
    mov [n], eax        ; сохраняем результат в n

    ; Инициализация счетчиков
    mov ecx, 1          ; ecx = текущее число (начинаем с 1)
    mov dword [count], 0 ; обнуляем счетчик подходящих чисел

main_loop:
    mov eax, ecx        ; загружаем текущее число для сравнения
    cmp eax, [n]        ; сравниваем текущее число с n
    jg done             ; если ecx > n, завершаем цикл

    ; Проверка делимости на 11
    mov eax, ecx        ; загружаем текущее число
    xor edx, edx        ; обнуляем edx для деления
    mov ebx, 11         ; делитель 11
    div ebx             ; делим eax на ebx
    cmp edx, 0          ; проверяем остаток
    je next_number      ; если делится на 11, пропускаем

    ; Проверка делимости на 5
    mov eax, ecx        ; снова загружаем текущее число
    xor edx, edx        ; обнуляем edx
    mov ebx, 5          ; делитель 5
    div ebx             ; делим eax на ebx
    cmp edx, 0          ; проверяем остаток
    je next_number      ; если делится на 5, пропускаем

    ; Число прошло обе проверки - увеличиваем счетчик
    inc dword [count]   ; увеличиваем счетчик подходящих чисел

next_number:
    inc ecx             ; переходим к следующему числу
    jmp main_loop       ; продолжаем цикл

done:
    ; Вывод результата
    mov rax, 1          ; системный вызов write (64-bit)
    mov rdi, 1          ; stdout
    mov rsi, result     ; строка "Количество чисел: "
    mov rdx, result_len ; длина строки
    syscall             ; системный вызов (64-bit)

    ; Преобразование числа в строку
    mov eax, [count]    ; загружаем число для преобразования
    mov rdi, buffer + 18 ; указываем на конец буфера
    mov byte [rdi], 0   ; добавляем нулевой байт
    mov ebx, 10         ; основание системы счисления

convert_to_string:
    dec rdi             ; перемещаемся назад по буферу
    xor edx, edx        ; обнуляем edx для деления
    div ebx             ; делим eax на 10
    add dl, '0'         ; преобразуем остаток в символ
    mov [rdi], dl       ; сохраняем символ в буфер
    test eax, eax       ; проверяем, осталось ли что-то
    jnz convert_to_string ; если да, продолжаем

    ; Вывод преобразованного числа
    mov rsi, rdi        ; указатель на начало строки
    mov rdx, buffer + 19 ; вычисляем длину строки
    sub rdx, rdi
    mov rax, 1          ; системный вызов write (64-bit)
    mov rdi, 1          ; stdout
    syscall             ; системный вызов (64-bit)

    ; Вывод символа новой строки
    mov rax, 1          ; системный вызов write (64-bit)
    mov rdi, 1          ; stdout
    mov rsi, newline    ; символ новой строки
    mov rdx, 1          ; длина 1
    syscall             ; системный вызов (64-bit)

    ; Завершение программы
    mov rax, 60         ; системный вызов exit (64-bit)
    xor rdi, rdi        ; код возврата 0
    syscall             ; системный вызов (64-bit)