section .data
    s1 db 'AMVtdiYVETHnNhuYwnWDVBqL',0
    len equ $ - s1 - 1

section .bss
    buffer resb 30

section .text
    global _start

_start:
    mov ecx, len
    mov esi, s1
    mov edi, buffer
    add esi, len - 1

reverse_loop:
    mov al, [esi]
    mov [edi], al
    dec esi
    inc edi
    loop reverse_loop

    mov byte [edi], 10
    inc edi
    mov byte [edi], 0

    mov eax, 4
    mov ebx, 1
    mov ecx, buffer
    mov edx, len + 1
    int 0x80

    mov eax, 1
    xor ebx, ebx
    int 0x80