format ELF64
public _start

extrn initscr
extrn start_color
extrn init_pair
extrn getmaxx
extrn getmaxy
extrn raw
extrn noecho
extrn keypad
extrn stdscr
extrn move
extrn getch
extrn addch
extrn refresh
extrn endwin
extrn timeout
extrn usleep
extrn printw
extrn mvaddch
extrn erase
extrn curs_set
extrn waddnstr
extrn addstr



KEY_FAST  = 'w'
KEY_SLOW  = 's'
KEY_QUIT  = 'q'

section '.bss' writable
    x           dq 0
    y           dq 0
    xmax        dq 1
    ymax        dq 1
    xmid        dq 1
    ymid        dq 1
    palette     dq 1
    delay       dq 60000
    buf         db ?
    f           db "/dev/random", 0
    rnd         dq ?

    phase       dq 1
    speed_level dq 3

section '.data' writable
    cursor_char db '*'

    usage_msg   db 'Upravlenie: F - Bystree, S - Medlennee, Q - Vyhod', 0

section '.text' executable

_start:
    call initscr

    mov rdi, [stdscr]
    call getmaxx
    mov [xmax], rax
    dec qword [xmax]

    call getmaxy
    mov [ymax], rax
    dec qword [ymax]

    mov rax, [xmax]
    xor rdx, rdx
    mov rcx, 2
    div rcx
    mov [xmid], rax

    mov rax, [ymax]
    xor rdx, rdx
    mov rcx, 2
    div rcx
    mov [ymid], rax

    xor rdi, rdi
    call curs_set

    call start_color
    mov rdi, 1
    mov rsi, 2
    mov rdx, 2
    call init_pair
    mov rdi, 2
    mov rsi, 3
    mov rdx, 3
    call init_pair

    call refresh
    call noecho
    call raw

    mov rdi, 0
    mov rsi, 0
    call move

    lea rdi, [usage_msg]
    call addstr
    call refresh

    ; mov rdi, 10000000
    ; call usleep

    ; call erase
    ; call refresh

    mov qword [x], 0
    mov qword [y], 0
    mov qword [phase], 1

    mov rdi, 1
    call timeout

.begin:

    ;1. Обработка ввода (getch)
    call getch

    cmp rax, KEY_QUIT
    je .end

    cmp rax, KEY_FAST
    je .increase_speed

    cmp rax, KEY_SLOW
    je .decrease_speed

    jmp .start_movement

.increase_speed:
    cmp qword [speed_level], 5
    jge .start_movement

    inc qword [speed_level]
    jmp .calculate_speed

.decrease_speed:
    cmp qword [speed_level], 1
    jle .start_movement

    dec qword [speed_level]

.calculate_speed:
    mov rax, 6
    sub rax, [speed_level]
    imul rax, 20000
    mov [delay], rax
    jmp .start_movement

    ;2. Очистка и Обновление координат
.start_movement:
    ;Стираем символ на текущей позиции
    mov rdi, [y]
    mov rsi, [x]
    mov rdx, ' '
    call mvaddch

    ;Вычисляем новые координаты
    mov rax, [phase]
    cmp rax, 1
    je .phase1_move

    cmp rax, 2
    je .phase2_move

    jmp .check_boundaries

.phase1_move:
    inc qword [x]
    inc qword [y]
    jmp .check_boundaries

.phase2_move:
    inc qword [x]
    dec qword [y]
    jmp .check_boundaries

    ;3. Проверка границ и смена фазы
.check_boundaries:
    mov rax, [phase]
    cmp rax, 1
    je .check_phase1

    cmp rax, 2
    je .check_phase2

    jmp .draw_and_refresh

.check_phase1:
    mov rbx, [xmax]
    cmp qword [x], rbx
    jg .switch_to_phase2

    mov rbx, [ymax]
    cmp qword [y], rbx
    jg .switch_to_phase2

    jmp .draw_and_refresh

.switch_to_phase2:
    mov qword [phase], 2
    mov qword [x], 0
    mov rbx, [ymax]
    mov [y], rbx
    jmp .draw_and_refresh

.check_phase2:
    mov rbx, [xmax]
    cmp qword [x], rbx
    jg .switch_to_phase1

    cmp qword [y], 0
    jl .switch_to_phase1

    jmp .draw_and_refresh

.switch_to_phase1:
    mov qword [phase], 1
    mov qword [x], 0
    mov qword [y], 0

    ;4. Отрисовка, Задержка и Повтор
.draw_and_refresh:
    mov rdi, [y]
    mov rsi, [x]
    movzx rdx, byte [cursor_char]
    call mvaddch

    call refresh

    mov rdi, [delay]
    call usleep

    jmp .begin

.end:
    mov rdi, 1
    call curs_set
    call endwin

    mov rax, 60
    xor rdi, rdi
    syscall