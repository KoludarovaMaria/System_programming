section .data
    prompt db "Введите n: ", 0
    prompt_len equ $ - prompt
    result db "Числа, совпадающие с последними разрядами своих квадратов:", 10, 0
    result_len equ $ - result
    format db " (квадрат: ", 0
    format_len equ $ - format
    closing db ")", 10, 0
    closing_len equ $ - closing

section .bss
    n resd 1
    i resd 1
    digits resd 1
    power resd 1
    buffer resb 20
    num_buffer resb 10

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

    mov eax, 4
    mov ebx, 1
    mov ecx, result
    mov edx, result_len
    int 0x80

    mov dword [i], 1

main_loop:
    mov eax, [i]
    cmp eax, [n]
    jg exit_program

    mov eax, [i]
    mul eax
    mov ebx, eax

    mov eax, [i]
    mov dword [digits], 0
    mov ecx, eax
count_digits:
    cmp ecx, 0
    je count_done
    inc dword [digits]
    mov eax, ecx
    mov ebx, 10
    xor edx, edx
    div ebx
    mov ecx, eax
    jmp count_digits
count_done:
    mov dword [power], 1
    mov ecx, [digits]
calc_power:
    cmp ecx, 0
    je calc_done
    mov eax, [power]
    mov ebx, 10
    mul ebx
    mov [power], eax
    dec ecx
    jmp calc_power
calc_done:
    mov eax, [i]
    mul eax
    mov ebx, [power]
    xor edx, edx
    div ebx
    mov eax, edx
    cmp eax, [i]
    jne next_number

    mov eax, [i]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, format
    mov edx, format_len
    int 0x80

    mov eax, [i]
    mul eax
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, closing
    mov edx, closing_len
    int 0x80

next_number:
    inc dword [i]
    jmp main_loop

print_number:
    mov edi, num_buffer + 9
    mov byte [edi], 0
    mov ebx, 10
print_loop:
    dec edi
    xor edx, edx
    div ebx
    add dl, '0'
    mov [edi], dl
    test eax, eax
    jnz print_loop

    mov ecx, edi
    mov edx, num_buffer + 10
    sub edx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80