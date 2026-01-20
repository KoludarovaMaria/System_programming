;;My library of useful functions named func.asm

;Function exit
exit:
     mov rax, 60
     mov rdi, 0
     syscall

;Function printing of string
;input rsi - place of memory of begin string
print_str:
    push rax
    push rdi
    push rdx
    push rcx
    mov rax, rsi
    call len_str
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

;The function makes new line
new_line:
   push rax
   push rdi
   push rsi
   push rdx
   push rcx
   mov rax, 0xA
   push rax
   mov rdi, 1
   mov rsi, rsp
   mov rdx, 1
   mov rax, 1
   syscall
   pop rax
   pop rcx
   pop rdx
   pop rsi
   pop rdi
   pop rax
   ret


;The function finds the length of a string
;input rax - place of memory of begin string
;output rax - length of the string
len_str:
  push rdx
  mov rdx, rax
  .iter:
      cmp byte [rax], 0
      je .next
      inc rax
      jmp .iter
  .next:
     sub rax, rdx
     pop rdx
     ret

print_char:
    push rdi
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, rsp         ; адрес символа в стеке
    mov rdx, 1           ; длина 1
    syscall
    pop rdi
    ret

; Функция print_number
; Вход: RDI - число для вывода
print_number:
    push rbp
    mov rbp, rsp
    sub rsp, 32          ; выделяем место в стеке для буфера (20 символов + \n + выравнивание)

    ; Проверяем знак числа
    test rdi, rdi
    jns .positive
    ; Отрицательное число
    push rdi             ; сохраняем число
    mov dil, '-'
    call print_char      ; выводим минус
    pop rdi
    neg rdi              ; делаем число положительным

.positive:
    ; Преобразуем число в строку (обратный порядок)
    mov rax, rdi
    lea rsi, [rbp - 1]   ; будем заполнять справа налево
    mov byte [rsi], 0    ; терминирующий ноль
    mov rbx, 10          ; основание системы

.convert_loop:
    dec rsi
    xor rdx, rdx
    div rbx              ; RDX = остаток, RAX = частное
    add dl, '0'          ; преобразуем цифру в символ
    mov [rsi], dl
    test rax, rax        ; если частное = 0, закончили
    jnz .convert_loop

    ; Выводим строку
    mov rdi, rsi
    call print_str

    mov rsp, rbp
    pop rbp
    ret

;Function converting the string to the number
;input rsi - place of memory of begin string
;output rax - the number from the string
str_number:
    push rcx
    push rbx

    xor rax,rax
    xor rcx,rcx
.loop:
    xor     rbx, rbx
    mov     bl, byte [rsi+rcx]
    cmp     bl, 48
    jl      .finished
    cmp     bl, 57
    jg      .finished

    sub     bl, 48
    add     rax, rbx
    mov     rbx, 10
    mul     rbx
    inc     rcx
    jmp     .loop

.finished:
    cmp     rcx, 0
    je      .restore
    mov     rbx, 10
    div     rbx

.restore:
    pop rbx
    pop rcx
    ret

;The function converts the nubmer to string
;input rax - number
;rsi -address of begin of string
number_str:
  push rbx
  push rcx
  push rdx
  xor rcx, rcx
  mov rbx, 10
  .loop_1:
    xor rdx, rdx
    div rbx
    add rdx, 48
    push rdx
    inc rcx
    cmp rax, 0
    jne .loop_1
  xor rdx, rdx
  .loop_2:
    pop rax
    mov byte [rsi+rdx], al
    inc rdx
    dec rcx
    cmp rcx, 0
  jne .loop_2
  mov byte [rsi+rdx], 0
  pop rdx
  pop rcx
  pop rbx
  ret


;The function realizates user input from the keyboard
;input: rsi - place of memory saved input string
input_keyboard:
  push rax
  push rdi
  push rdx

  mov rax, 0
  mov rdi, 0
  mov rdx, 255
  syscall

  xor rcx, rcx
  .loop:
     mov al, [rsi+rcx]
     inc rcx
     cmp rax, 0x0A
     jne .loop
  dec rcx
  mov byte [rsi+rcx], 0

  pop rdx
  pop rdi
  pop rax
  ret


; Функция выделения памяти
; Вход: RDI - размер в байтах
; Выход: RAX - указатель на память или 0 при ошибке
my_malloc:
    push rdi
    push rsi
    push rdx
    push r10
    push r8
    push r9

    ; Сохраняем исходный размер
    mov r8, rdi

    ; Выравниваем размер до границы страницы
    add rdi, 4095
    and rdi, 0xFFFFFFFFFFFFF000  ; ~4095 = 0xFFFFFFFFFFFFF000

    ; Системный вызов mmap
    mov rax, 9          ; sys_mmap
    xor rdi, rdi        ; адрес (0 = ядро выбирает)
    mov rsi, r8         ; размер
    add rsi, 4095       ; выравниваем
    and rsi, 0xFFFFFFFFFFFFF000
    mov rdx, 3          ; PROT_READ | PROT_WRITE
    mov r10, 0x22       ; MAP_ANONYMOUS | MAP_PRIVATE
    mov r8, -1          ; файловый дескриптор (-1 для анонимного)
    xor r9, r9          ; смещение = 0
    syscall

    pop r9
    pop r8
    pop r10
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция освобождения памяти
; Вход: RDI - указатель на память
my_free:
    push rdi
    push rsi
    push rdx
    push r10
    push r8
    push r9

    ; Для простоты освобождаем целую страницу
    ; В реальном приложении нужно хранить размер выделения
    mov rsi, 4096       ; размер одной страницы

    ; Системный вызов munmap
    mov rax, 11         ; sys_munmap
    ; RDI уже содержит указатель
    ; RSI уже содержит размер
    syscall

    pop r9
    pop r8
    pop r10
    pop rdx
    pop rsi
    pop rdi
    ret
