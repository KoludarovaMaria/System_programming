format ELF executable
entry _start

segment readable executable

_start:
    mov ebp, esp
    
main_loop:
    ; Вывод приглашения
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt
    mov edx, prompt_len
    int 0x80
    
    ; Чтение ввода
    mov eax, 3
    mov ebx, 0
    mov ecx, input
    mov edx, 255
    int 0x80
    
    ; Проверка на EOF (когда ввод из pipe)
    test eax, eax
    jz exit_program
    
    ; Проверка на пустую строку
    cmp eax, 1
    jle main_loop
    
    ; Убираем символ новой строки
    mov esi, input
    add esi, eax
    dec esi
    mov byte [esi], 0
    
    ; Проверка на exit
    mov edi, input
    cmp byte [edi], 'e'
    jne .not_exit
    cmp byte [edi+1], 'x'
    jne .not_exit
    cmp byte [edi+2], 'i'
    jne .not_exit
    cmp byte [edi+3], 't'
    jne .not_exit
    cmp byte [edi+4], 0
    je exit_program
    
.not_exit:
    ; Создаем дочерний процесс
    mov eax, 2
    int 0x80
    
    test eax, eax
    jz .child_process
    
    ; Родительский процесс - ждем завершения
    push eax
    mov eax, 7
    pop ebx
    mov ecx, 0
    mov edx, 0
    int 0x80
    
    jmp main_loop

.child_process:
    ; Загружаем программу
    mov eax, 11
    mov ebx, input
    mov ecx, 0
    mov edx, 0
    int 0x80
    
    ; Если дошли сюда - ошибка
    mov eax, 1
    mov ebx, 1
    int 0x80

exit_program:
    mov eax, 1
    mov ebx, 0
    int 0x80

segment readable writeable
    prompt db "Введите команду: ", 0
    prompt_len = $ - prompt
    input rb 256