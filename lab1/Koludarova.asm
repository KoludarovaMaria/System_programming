; Формат файла: ELF для Linux
format ELF executable
entry start                ; Точка входа в программу

; Сегмент кода
segment readable executable

start:
    ; Вывод фамилии
    mov eax, 4             ; sys_write
    mov ebx, 1             ; stdout
    mov ecx, surname       ; указатель на строку
    mov edx, surname_len   ; длина строки
    int 0x80               ; системный вызов
    
    ; Вывод имени
    mov eax, 4             ; sys_write
    mov ebx, 1             ; stdout
    mov ecx, name          ; указатель на строку
    mov edx, name_len      ; длина строки
    int 0x80               ; системный вызов
    
    ; Вывод отчества
    mov eax, 4             ; sys_write
    mov ebx, 1             ; stdout
    mov ecx, patronymic    ; указатель на строку
    mov edx, patronymic_len ; длина строки
    int 0x80               ; системный вызов
    
    ; Завершение программы
    mov eax, 1             ; sys_exit
    xor ebx, ebx           ; код возврата 0
    int 0x80               ; системный вызов

; Сегмент данных
segment readable writeable

; Данные: строки с символами новой строки
surname db 'Koludarova', 0xA    ; Фамилия + \n
surname_len = $-surname         ; Автоматический расчет длины

name db 'Maria', 0xA            ; Имя + \n
name_len = $-name               ; Автоматический расчет длины

patronymic db 'Alekseevna', 0xA ; Отчество + \n
patronymic_len = $-patronymic   ; Автоматический расчет длины
