section .data
    symbol db '8'
    newline db 10

section .text
    global _start

_start:
    mov ecx, 6
    mov ebx, 1
    
triangle_rows:
    push ecx
    push ebx
    
    mov ecx, ebx
print_symbols:
    push ecx
    mov eax, 4
    mov ebx, 1
    mov ecx, symbol
    mov edx, 1
    int 0x80
    pop ecx
    loop print_symbols
    
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    pop ebx
    pop ecx
    inc ebx
    loop triangle_rows
    
    mov eax, 1
    xor ebx, ebx
    int 0x80