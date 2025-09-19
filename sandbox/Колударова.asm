section .data
    surname db 'Колударова', 0xA
    surname_len equ $ - surname
    
    name db 'Мария', 0xA
    name_len equ $ - name
    
    patronymic db 'Алексеевна', 0xA
    patronymic_len equ $ - patronymic

section .text
    global _start

_start:
    ; вывод фамилии
    mov eax, 4
    mov ebx, 1
    mov ecx, surname
    mov edx, surname_len
    int 0x80

    ; вывод имени
    mov eax, 4
    mov ebx, 1
    mov ecx, name
    mov edx, name_len
    int 0x80

    ; вывод отчества
    mov eax, 4
    mov ebx, 1
    mov ecx, patronymic
    mov edx, patronymic_len
    int 0x80

    ; выход
    mov eax, 1
    xor ebx, ebx
    int 0x80