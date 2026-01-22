format ELF64

section '.data' writeable align 16
    ; Строки
    prompt_x    db "Enter x value: ", 0
    prompt_eps  db "Enter precision (e.g. 0.0000001): ", 0
    scan_fmt    db "%lf", 0
    out_fmt     db "x: %.5f | My cos (SSE): %.10f | Lib cos: %.10f | Iterations: %d", 10, 0

    ; Константы (double)
    align 16
    one         dq 1.0
    four        dq 4.0
    pi_sq       dq 9.869604401089358      ; π²
    pi          dq 3.14159265358979323846 ; π
    pi_half     dq 1.57079632679489661923 ; π/2
    two_pi      dq 6.28318530717958647692 ; 2π
   
    ; Маски
    align 16
    abs_mask        dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF     ; обнуление знакового бита
    sign_bit_mask   dq 0x8000000000000000, 0x8000000000000000     ; только знаковый бит

section '.bss' writeable align 16
    x           dq ?
    eps         dq ?
    my_res      dq ?
    fpu_res     dq ?
    x_reduced   dq ?
    sign_flag   dq ?
    iteration_count dq ?

section '.text' executable
    extrn printf
    extrn scanf
    extrn exit

    public main

main:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32       

    ; --- Ввод данных (стандартный) ---
    lea     rdi, [prompt_x]
    xor     rax, rax
    call    printf

    lea     rdi, [scan_fmt]
    lea     rsi, [x]
    xor     rax, rax
    call    scanf

    lea     rdi, [prompt_eps]
    xor     rax, rax
    call    printf

    lea     rdi, [scan_fmt]
    lea     rsi, [eps]
    xor     rax, rax
    call    scanf

    ; =============================================================
    ; Range Reduction (Приведение аргумента) с использованием SSE
    ; x_new = x - floor(x / 2π) * 2π
    ; =============================================================
    
    ; Загрузка x и взятие модуля
    movsd   xmm0, [x]           ; Команда movsd 
    movq    xmm1, [abs_mask]    ; Используем movq для загрузки маски
    andpd   xmm0, xmm1          ; Побитовое И (логика SSE)

    ; x = |x| % 2π
    movapd  xmm1, xmm0          ; movapd - копирование выровненных данных 
    divsd   xmm1, [two_pi]      ; divsd - деление 
    
    ; Конвертация float -> int -> float 
    cvttsd2si rax, xmm1         ; Округление до целого с отбрасыванием дробной части
    cvtsi2sd  xmm2, rax         ; Обратно в double
    
    mulsd   xmm2, [two_pi]      ; mulsd - умножение
    subsd   xmm0, xmm2          ; subsd - вычитание: xmm0 = остаток

    ; Корректировка, если результат стал < 0 из-за погрешности
    xorpd   xmm1, xmm1          ; Обнуление xmm1
    comisd xmm0, xmm1
    jae     .positive_rem       ; Если не равно, прыгаем
    addsd   xmm0, [two_pi]      ; Иначе корректируем
.positive_rem:

    ;Обработка квадрантов
    mov     qword [sign_flag], 0

    ; Проверка x > π
    comisd xmm0, [pi]
    jne     .check_half
    
    ; x = 2π - x
    movsd   xmm1, [two_pi]
    subsd   xmm1, xmm0
    movapd  xmm0, xmm1

.check_half:
    ; Проверка x > π/2
    comisd  xmm0, [pi_half]
    jbe     .store_x
    
    ; x = π - x, sign = 1
    movsd   xmm1, [pi]
    subsd   xmm1, xmm0
    movapd  xmm0, xmm1
    mov     qword [sign_flag], 1

.store_x:
    movsd   [x_reduced], xmm0

    ; =============================================================
    ; Вычисление ряда
    ; =============================================================
    
    ; Подготовка константы: Const = 4 * x^2 / pi^2
    movsd   xmm0, [x_reduced]
    mulsd   xmm0, xmm0          
    mulsd   xmm0, [four]
    divsd   xmm0, [pi_sq]       ; xmm0 = Const

    movsd   xmm1, [one]         ; xmm1 = Результат (Product)
    mov     rcx, 1              ; Счетчик n
    movsd xmm6, [eps]

.loop:
    ; (2n - 1)^2
    mov     rax, rcx
    shl     rax, 1
    dec     rax
    cvtsi2sd xmm2, rax
    mulsd   xmm2, xmm2 ; (2n-1)^2 - это denominator

    ; term = Const / denominator
    movapd  xmm3, xmm7
    divsd   xmm3, xmm2

    ; factor = 1 - term
    movsd   xmm4, [one]
    subsd   xmm4, xmm3

    ; Сохраняем предыдущий результат
    movapd  xmm5, xmm1
    
    ; Обновляем результат
    mulsd   xmm1, xmm4

    ; --- Проверка точности  ---
    subsd   xmm5, xmm1          ; diff = old - new
    movq    xmm2, [abs_mask]
    andpd   xmm5, xmm2          ; abs(diff)

    ; Проверяем abs(diff) < eps
    comisd  xmm5, xmm6
    jb      .done_loop          ; Если diff < eps, выходим

    inc     rcx
    cmp     rcx, 10000000
    jl      .loop

    ;превысили максимальное число итераций
    mov     rcx, 10000000

.done_loop:
    ; Сохраняем количество итераций
    mov     [iteration_count], rcx

    ; Применение знака (для x в [pi/2, pi])
    cmp     qword [sign_flag], 1
    jne     .store_result

    movq    xmm2, [sign_bit_mask]
    xorpd   xmm1, xmm2          ; Меняем знак

.store_result:
    movsd   [my_res], xmm1

    ; =============================================================
    ; Вычисление косинуса с помощью математического сопроцессора (FCOS)
    ; =============================================================
    
    ; Загружаем исходное значение x в стек FPU
    fld     qword [x]           ; Загружаем x в st(0)
    
    ; Применяем инструкцию FCOS
    fcos                        ; Вычисляем cos(st(0)), результат в st(0)
    
    ; Сохраняем результат из стека FPU в память
    fstp    qword [fpu_res]     ; Сохраняем результат и выталкиваем из стека

    ; Вывод результатов
    lea     rdi, [out_fmt]
    movsd   xmm0, [x]
    movsd   xmm1, [my_res]
    movsd   xmm2, [fpu_res]     ; Используем результат от FPU
    mov     rsi, [iteration_count]
    mov     rax, 3              ; 3 числа с плавающей точкой
    call    printf

    xor     rdi, rdi
    call    exit
