format ELF executable
entry _start

segment readable writeable
    msg1 db '1489: ', 0
    len1 = $ - msg1
    
    msg2 db '4632: ', 0
    len2 = $ - msg2
    
    yes db 'Yes', 0xA
    leny = $ - yes
    
    no db 'No', 0xA
    lenn = $ - no
    
    buffer rb 10

segment readable executable
_start:
    ; Проверяем 1489
    mov eax, 4
    mov ebx, 1
    mov ecx, msg1
    mov edx, len1
    int 0x80
    
    mov eax, 1489
    call check_non_decreasing
    test eax, eax
    jz .no1
    
    ; Выводим Yes
    mov eax, 4
    mov ebx, 1
    mov ecx, yes
    mov edx, leny
    int 0x80
    jmp .check2
    
.no1:
    ; Выводим No
    mov eax, 4
    mov ebx, 1
    mov ecx, no
    mov edx, lenn
    int 0x80

.check2:
    ; Проверяем 4632
    mov eax, 4
    mov ebx, 1
    mov ecx, msg2
    mov edx, len2
    int 0x80
    
    mov eax, 4632
    call check_non_decreasing
    test eax, eax
    jz .no2
    
    ; Выводим Yes
    mov eax, 4
    mov ebx, 1
    mov ecx, yes
    mov edx, leny
    int 0x80
    jmp .exit
    
.no2:
    ; Выводим No
    mov eax, 4
    mov ebx, 1
    mov ecx, no
    mov edx, lenn
    int 0x80

.exit:
    ; Завершение
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ----------------------------------------------------------
; Проверка: цифры в НЕУБЫВАЮЩЕМ порядке слева направо
; Правильный алгоритм:
; 1. Извлекаем цифры и сохраняем в массив (в обратном порядке)
; 2. Проверяем массив от конца к началу
; Вход: EAX = число
; Выход: EAX = 1 (да), 0 (нет)
; ----------------------------------------------------------
check_non_decreasing:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; 1. Сохраняем число
    mov esi, eax
    
    ; 2. Извлекаем цифры и сохраняем в стек (в обратном порядке)
    mov ebx, 10
    mov ecx, 0          ; счетчик цифр
    
.extract_digits:
    xor edx, edx
    div ebx             ; EDX = цифра
    push edx            ; сохраняем в стек
    inc ecx             ; увеличиваем счетчик
    test eax, eax       ; проверяем, остались ли цифры
    jnz .extract_digits
    
    ; 3. Теперь цифры в стеке в обратном порядке
    ; Например для 1489: в стеке [1, 4, 8, 9] (9 наверху)
    ; Нужно проверять от первой цифры к последней
    
    ; Извлекаем первую цифру (самую левую в исходном числе)
    pop eax             ; EAX = первая цифра
    dec ecx             ; уменьшаем счетчик
    
    ; 4. Проверяем остальные цифры
.check_loop:
    test ecx, ecx       ; если больше нет цифр
    jz .success
    
    pop edx             ; следующая цифра
    dec ecx
    
    ; Сравниваем: предыдущая должна быть <= текущей
    cmp eax, edx
    jg .failure         ; если предыдущая > текущей
    
    mov eax, edx        ; обновляем предыдущую цифру
    jmp .check_loop

.success:
    mov eax, 1
    jmp .done

.failure:
    ; Очищаем стек от оставшихся цифр
    test ecx, ecx
    jz .clean_done
    pop edx
    dec ecx
    jmp .failure

.clean_done:
    xor eax, eax

.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret