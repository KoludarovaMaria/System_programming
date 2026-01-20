format ELF64

section '.text' executable

public main

extrn initscr
extrn endwin
extrn cbreak
extrn noecho
extrn curs_set
extrn printw
extrn refresh
extrn getch
extrn move
extrn napms
extrn clear

main:
    push    rbp
    mov     rbp, rsp
    
    ; Инициализация ncurses
    call    initscr
    call    cbreak
    call    noecho
    
    ; Делаем курсор видимым
    mov     rdi, 1
    call    curs_set
    
    ; Очищаем экран
    call    clear
    
    ; Выводим инструкции
    mov     rdi, 0
    mov     rsi, 0
    call    move
    
    mov     rdi, instructions
    call    printw
    call    refresh
    
    ; Ждем 2 секунды
    mov     rdi, 2000
    call    napms
    
    call    clear
    
    ; Движение из левого верхнего в правый нижний угол
    mov     ebx, 0
.move1:
    cmp     ebx, 20
    jge     .move2
    
    mov     rdi, rbx    ; y
    mov     rsi, rbx    ; x
    call    move
    
    mov     rdi, char1
    call    printw
    call    refresh
    
    ; Задержка (имитация регулировки скорости)
    mov     edi, [delay]
    call    napms
    
    inc     ebx
    jmp     .move1

.move2:
    ; Пауза
    mov     rdi, 1000
    call    napms
    
    ; Движение из левого нижнего в правый верхний угол
    mov     ebx, 20
.move2_loop:
    test    ebx, ebx
    js      .done
    
    mov     rdi, 20     ; y = 20 (низ)
    sub     rdi, rbx
    mov     rsi, rbx    ; x
    call    move
    
    mov     rdi, char2
    call    printw
    call    refresh
    
    ; Задержка
    mov     edi, [delay]
    call    napms
    
    dec     ebx
    jmp     .move2_loop

.done:
    ; Выводим сообщение
    mov     rdi, 22
    mov     rsi, 0
    call    move
    
    mov     rdi, done_msg
    call    printw
    
    mov     rdi, 23
    mov     rsi, 0
    call    move
    
    mov     rdi, speed_msg
    call    printw
    
    mov     rdi, speed_value
    mov     esi, [delay]
    call    printw
    
    call    refresh
    
    ; Ждем нажатия клавиши
    call    getch
    
    ; Завершение
    call    endwin
    
    xor     rax, rax
    pop     rbp
    ret

section '.data' writeable

instructions db 'Cursor moving...',0
char1        db '*',0
char2        db '#',0
done_msg     db 'Done! Press any key to exit.',0
speed_msg    db 'Current delay: ',0
speed_value  db '%d ms',0
delay        dd 100  ; начальная задержка 100 мс

section '.idata' import

library ncurses,'libncurses.so.6'

import ncurses,\
    initscr,'initscr',\
    endwin,'endwin',\
    cbreak,'cbreak',\
    noecho,'noecho',\
    curs_set,'curs_set',\
    printw,'printw',\
    refresh,'refresh',\
    getch,'getch',\
    move,'move',\
    napms,'napms',\
    clear,'clear'