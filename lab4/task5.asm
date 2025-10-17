section .data
    prompt db "Введите n: ", 0
    prompt_len equ $ - prompt
    result db "Количество чисел: ", 0
    result_len equ $ - result
    newline db 10

section .bss
    n resd 1
    count resd 1
    buffer resb 10

section .text
    global _start

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt
    mov edx, prompt_len
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, buffer
    mov edx, 10
    int 0x80

    mov esi, buffer
    xor eax, eax
    xor ebx, ebx
convert_loop:
    mov bl, [esi]
    cmp bl, 10
    je convert_done
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp convert_loop
convert_done:
    mov [n], eax

    mov ecx, 1
    mov dword [count], 0

main_loop:
    cmp ecx, [n]
    jg done

    mov eax, ecx
    xor edx, edx
    mov ebx, 11
    div ebx
    cmp edx, 0
    je next_number

    mov eax, ecx
    xor edx, edx
    mov ebx, 5
    div ebx
    cmp edx, 0
    je next_number

    inc dword [count]

next_number:
    inc ecx
    jmp main_loop

done:
    mov eax, 4
    mov ebx, 1
    mov ecx, result
    mov edx, result_len
    int 0x80

    mov eax, [count]
    mov edi, buffer + 9
    mov byte [edi], 0
    mov ebx, 10

convert_to_string:
    dec edi
    xor edx, edx
    div ebx
    add dl, '0'
    mov [edi], dl
    test eax, eax
    jnz convert_to_string

    mov ecx, edi
    mov edx, buffer + 10
    sub edx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    mov eax, 1
    xor ebx, ebx
    int 0x80