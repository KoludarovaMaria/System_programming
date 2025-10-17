section .data
    prompt db "Введите пароль: ", 0
    prompt_len equ $ - prompt
    correct db "password123", 0
    success db "Вошли", 10, 0
    success_len equ $ - success
    wrong db "Неверный пароль", 10, 0
    wrong_len equ $ - wrong
    failure db "Неудача", 10, 0
    failure_len equ $ - failure
    attempt_msg db " (попытка ", 0
    attempt_msg_len equ $ - attempt_msg
    slash db "/5)", 10, 0
    slash_len equ $ - slash

section .bss
    input resb 50
    attempts resd 1

section .text
    global _start

_start:
    mov dword [attempts], 0

auth_loop:
    mov eax, [attempts]
    cmp eax, 5
    jge auth_failure

    mov eax, 4
    mov ebx, 1
    mov ecx, prompt
    mov edx, prompt_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, attempt_msg
    mov edx, attempt_msg_len
    int 0x80

    mov eax, [attempts]
    inc eax
    add al, '0'
    mov [input], al
    mov eax, 4
    mov ebx, 1
    mov ecx, input
    mov edx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, slash
    mov edx, slash_len
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, input
    mov edx, 50
    int 0x80

    mov esi, input
find_newline:
    cmp byte [esi], 10
    je remove_newline
    inc esi
    jmp find_newline
remove_newline:
    mov byte [esi], 0

    mov esi, input
    mov edi, correct
compare_loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne password_wrong
    cmp al, 0
    je password_correct
    inc esi
    inc edi
    jmp compare_loop

password_correct:
    mov eax, 4
    mov ebx, 1
    mov ecx, success
    mov edx, success_len
    int 0x80
    jmp exit_success

password_wrong:
    mov eax, 4
    mov ebx, 1
    mov ecx, wrong
    mov edx, wrong_len
    int 0x80
    inc dword [attempts]
    jmp auth_loop

auth_failure:
    mov eax, 4
    mov ebx, 1
    mov ecx, failure
    mov edx, failure_len
    int 0x80

exit_success:
    mov eax, 1
    xor ebx, ebx
    int 0x80