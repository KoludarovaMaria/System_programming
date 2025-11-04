section .data
    number dq 5277616985
    result_msg db 'Sum of digits: '
    result_value db 0, 10

section .text
    global _start

_start:
    mov eax, [number]
    mov edx, [number+4]
    mov ebx, 10
    xor ecx, ecx
    
sum_loop:
    push eax
    push edx
    mov eax, [number]
    mov edx, [number+4]
    mov esi, 10
    xor edi, edi
    
    div esi
    mov [number], eax
    mov [number+4], edx
    
    add ecx, edx
    pop edx
    pop eax
    
    mov eax, [number]
    mov edx, [number+4]
    or eax, edx
    jnz sum_loop
    
    mov eax, ecx
    add al, '0'
    mov [result_value], al
    
    mov eax, 4
    mov ebx, 1
    mov ecx, result_msg
    mov edx, 15
    int 0x80
    
    mov eax, 1
    xor ebx, ebx
    int 0x80