section .data
    symbol db '+'
    rows equ 11
    cols equ 6
    newline db 10

section .bss
    matrix_buffer resb 100

section .text
    global _start

_start:
    call print_matrix
    call print_newline
    call print_triangle
    
    mov eax, 1
    xor ebx, ebx
    int 0x80

print_matrix:
    mov esi, matrix_buffer
    mov ecx, rows
    
row_loop:
    push ecx
    mov ecx, cols
    
col_loop:
    mov al, [symbol]
    mov [esi], al
    inc esi
    loop col_loop
    
    mov byte [esi], 10
    inc esi
    pop ecx
    loop row_loop
    
    mov eax, 4
    mov ebx, 1
    mov ecx, matrix_buffer
    mov edx, rows * (cols + 1)
    int 0x80
    ret

print_triangle:
    mov esi, matrix_buffer
    mov ecx, 1
    mov ebx, rows
    
triangle_loop:
    push ecx
    mov edx, ecx
    
symbol_loop:
    mov al, [symbol]
    mov [esi], al
    inc esi
    dec edx
    jnz symbol_loop
    
    mov byte [esi], 10
    inc esi
    
    pop ecx
    inc ecx
    cmp ecx, ebx
    jle triangle_loop
    
    mov eax, 4
    mov ebx, 1
    mov ecx, matrix_buffer
    mov edx, ebx
    imul edx, ebx
    add edx, ebx
    shr edx, 1
    add edx, ebx
    int 0x80
    ret

print_newline:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret