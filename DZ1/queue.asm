format ELF64           

section '.text' executable  

; Экспортируем функции (делаем их доступными извне)
public queue_create
public queue_destroy
public queue_enqueue
public queue_dequeue
public queue_fill_random
public queue_remove_even
public queue_count_ends_with_one
public queue_get_odd_numbers

; Импортируем функции из стандартной библиотеки C
extrn malloc          ; Выделение памяти
extrn free            ; Освобождение памяти
extrn time            ; Получение текущего времени
extrn srand           ; Инициализация генератора случайных чисел
extrn rand            ; Генерация случайного числа

; Структура Queue:
;   data:       8 bytes (pointer)    - указатель на массив данных
;   capacity:   8 bytes              - текущая емкость массива
;   front:      8 bytes              - индекс первого элемента
;   rear:       8 bytes              - индекс, куда вставить следующий
;   size:       8 bytes              - текущее количество элементов
;   min_capacity: 8 bytes            - минимальная емкость
; Итого: 48 bytes

; Константы
MIN_CAPACITY = 4      ; Минимальная емкость очереди
GROW_FACTOR = 2       ; Коэффициент увеличения емкости
SHRINK_THRESHOLD = 4  ; Порог уменьшения (уменьшаем если size <= capacity/4)

; Queue* queue_create(size_t initial_capacity)
queue_create:
    push    rbx       ; Сохраняем регистры, которые будем использовать
    push    r12
    
    ; Проверяем и корректируем начальную емкость
    mov     r12, rdi  ; Сохраняем initial_capacity в r12
    cmp     r12, MIN_CAPACITY  ; Сравниваем с минимальной емкостью
    jge     .valid_cap         ; Если >=, пропускаем корректировку
    mov     r12, MIN_CAPACITY  ; Иначе устанавливаем минимальную емкость
    
.valid_cap:
    ; Выделяем память под структуру Queue (48 байт)
    mov     rdi, 48   ; Размер структуры Queue
    call    malloc    ; Выделяем память
    test    rax, rax  ; Проверяем, не вернулся ли NULL
    jz      .error    ; Если NULL, переходим к ошибке
    
    mov     rbx, rax  ; Сохраняем указатель на структуру в rbx
    
    ; Выделяем память под данные
    mov     rdi, r12  ; Размер массива = capacity
    shl     rdi, 2    ; Умножаем на sizeof(int32_t) = * 4
    call    malloc    ; Выделяем память под массив
    test    rax, rax  ; Проверяем на NULL
    jz      .free_struct ; Если NULL, освобождаем структуру и выходим
    
    ; Инициализируем структуру
    mov     [rbx], rax              ; data = указатель на массив
    mov     [rbx + 8], r12          ; capacity = начальная емкость
    mov     qword [rbx + 16], 0     ; front = 0
    mov     qword [rbx + 24], 0     ; rear = 0
    mov     qword [rbx + 32], 0     ; size = 0
    mov     qword [rbx + 40], MIN_CAPACITY ; min_capacity = MIN_CAPACITY
    
    mov     rax, rbx  ; Возвращаем указатель на структуру
    jmp     .done
    
.free_struct:
    mov     rdi, rbx  ; Освобождаем память структуры
    call    free
.error:
    xor     rax, rax  ; Возвращаем NULL (0)
.done:
    pop     r12       ; Восстанавливаем регистры
    pop     rbx
    ret

; void queue_destroy(Queue* q)
queue_destroy:
    push    rbx       ; Сохраняем rbx
    
    test    rdi, rdi  ; Проверяем, не NULL ли указатель
    jz      .exit     ; Если NULL, выходим
    
    mov     rbx, rdi  ; Сохраняем указатель на структуру
    
    ; Освобождаем данные
    mov     rdi, [rbx] ; Получаем указатель на массив данных
    call    free      ; Освобождаем массив
    
    ; Освобождаем структуру
    mov     rdi, rbx  ; Указатель на структуру
    call    free      ; Освобождаем структуру
    
.exit:
    pop     rbx       ; Восстанавливаем rbx
    ret

; Внутренняя функция: перераспределение памяти
; bool queue_reallocate(Queue* q, size_t new_capacity)
queue_reallocate:
    push    rbx       ; Сохраняем регистры
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbp
    mov     rbp, rsp  ; Сохраняем указатель стека
    sub     rsp, 32   ; Резервируем место для локальных переменных
    
    mov     rbx, rdi  ; Сохраняем q в rbx
    mov     [rbp - 8], rsi  ; Сохраняем new_capacity в стеке
    
    ; Проверяем, что new_capacity >= size
    cmp     rsi, [rbx + 32] ; Сравниваем new_capacity с size
    jl      .failure   ; Если new_capacity < size, ошибка
    
    ; Создаем новый массив
    mov     rdi, rsi  ; new_capacity
    shl     rdi, 2    ; new_capacity * 4 (sizeof int32_t)
    call    malloc    ; Выделяем память
    test    rax, rax  ; Проверяем на NULL
    jz      .failure  ; Если NULL, ошибка
    
    mov     [rbp - 16], rax ; Сохраняем указатель на новый массив
    mov     r12, [rbx]      ; Старый массив
    mov     r13, [rbx + 32] ; size (количество элементов)
    
    ; Копируем элементы в правильном порядке
    mov     rcx, r13  ; Счетчик элементов для копирования
    mov     r14, [rbx + 16] ; front index (начало очереди)
    mov     r15, [rbx + 8]  ; Старая capacity
    
    xor     r10, r10  ; Индекс в новом массиве (начинаем с 0)
    
.copy_loop:
    test    rcx, rcx  ; Проверяем, остались ли элементы
    jz      .copy_done ; Если нет, выходим
    
    ; Копируем элемент из старого массива
    mov     eax, [r12 + r14*4] ; data[front]
    mov     r11, [rbp - 16]    ; Указатель на новый массив
    mov     [r11 + r10*4], eax ; new_data[i] = old_data[front]
    
    ; Увеличиваем индексы
    inc     r14       ; Переходим к следующему элементу в старом массиве
    cmp     r14, r15  ; Проверяем, не достигли ли конца массива
    jl      .no_wrap_old ; Если нет, продолжаем
    xor     r14, r14  ; Иначе обнуляем (циклический буфер)
.no_wrap_old:
    inc     r10       ; Увеличиваем индекс в новом массиве
    dec     rcx       ; Уменьшаем счетчик
    jmp     .copy_loop ; Повторяем
    
.copy_done:
    ; Освобождаем старый массив
    mov     rdi, r12  ; Указатель на старый массив
    call    free
    
    ; Обновляем структуру
    mov     r11, [rbp - 16] ; Новый массив
    mov     [rbx], r11      ; q->data = новый массив
    mov     r11, [rbp - 8]  ; Новая capacity
    mov     [rbx + 8], r11  ; q->capacity = new_capacity
    mov     qword [rbx + 16], 0  ; q->front = 0 (всегда с начала в новом)
    mov     [rbx + 24], r13 ; q->rear = size (конец очереди)
    
    mov     rax, 1    ; Возвращаем true (успех)
    jmp     .exit
    
.failure:
    xor     rax, rax  ; Возвращаем false (ошибка)
    
.exit:
    mov     rsp, rbp  ; Восстанавливаем указатель стека
    pop     rbp       ; Восстанавливаем регистры
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; bool queue_enqueue(Queue* q, int32_t value)
queue_enqueue:
    push    rbx
    push    r12
    
    mov     rbx, rdi  ; Сохраняем q
    mov     r12d, esi ; Сохраняем value
    
    ; Проверяем, нужно ли увеличить емкость
    mov     rax, [rbx + 32] ; size
    cmp     rax, [rbx + 8]  ; capacity
    jl      .has_space      ; Если size < capacity, места хватает
    
    ; Увеличиваем емкость
    mov     rdi, rbx        ; q
    mov     rsi, [rbx + 8]  ; текущая capacity
    shl     rsi, 1          ; capacity * 2 (GROW_FACTOR)
    call    queue_reallocate
    test    rax, rax        ; Проверяем успешность
    jz      .failure        ; Если 0, ошибка
    
.has_space:
    ; Добавляем элемент
    mov     rcx, [rbx]      ; Указатель на массив данных
    mov     rdx, [rbx + 24] ; rear index
    
    ; data[rear] = value
    mov     [rcx + rdx*4], r12d ; Сохраняем значение
    
    ; Обновляем rear: rear = (rear + 1) % capacity
    inc     rdx            ; Увеличиваем rear
    cmp     rdx, [rbx + 8] ; Сравниваем с capacity
    jl      .no_wrap       ; Если меньше, не оборачиваем
    xor     rdx, rdx       ; Иначе обнуляем (0)
.no_wrap:
    mov     [rbx + 24], rdx ; Сохраняем новый rear
    
    ; Увеличиваем size
    inc     qword [rbx + 32]
    
    mov     rax, 1          ; Возвращаем true
    jmp     .exit
    
.failure:
    xor     rax, rax        ; Возвращаем false
.exit:
    pop     r12
    pop     rbx
    ret

; bool queue_dequeue(Queue* q, int32_t *value)
queue_dequeue:
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi        ; q
    mov     r12, rsi        ; указатель для сохранения значения
    
    ; Проверяем, не пуста ли очередь
    cmp     qword [rbx + 32], 0 ; size == 0?
    je      .fail_empty     ; Если да, очередь пуста
    
    ; Получаем data[front]
    mov     rcx, [rbx]      ; указатель на массив
    mov     rdx, [rbx + 16] ; front index
    
    ; *value = data[front]
    mov     eax, [rcx + rdx*4] ; Читаем значение
    test    r12, r12        ; Проверяем, не NULL ли указатель
    jz      .no_store       ; Если NULL, не сохраняем
    mov     [r12], eax      ; Сохраняем значение
    
.no_store:
    ; Обновляем front: front = (front + 1) % capacity
    inc     rdx            ; Увеличиваем front
    cmp     rdx, [rbx + 8] ; Сравниваем с capacity
    jl      .no_wrap       ; Если меньше, не оборачиваем
    xor     rdx, rdx       ; Иначе обнуляем
.no_wrap:
    mov     [rbx + 16], rdx ; Сохраняем новый front
    
    ; Уменьшаем size
    dec     qword [rbx + 32]
    
    ; Проверяем, нужно ли уменьшить емкость
    mov     r13, [rbx + 32] ; size
    mov     r14, [rbx + 8]  ; capacity
    
    ; Если capacity > min_capacity И size <= capacity / SHRINK_THRESHOLD
    mov     rax, [rbx + 40] ; min_capacity
    cmp     r14, rax        ; capacity > min_capacity?
    jle     .no_shrink      ; Если нет, не уменьшаем
    
    ; Проверяем условие уменьшения: size <= capacity / 4
    mov     rcx, r14        ; capacity
    shr     rcx, 2          ; capacity / 4
    cmp     r13, rcx        ; size <= capacity/4?
    jg      .no_shrink      ; Если нет, не уменьшаем
    
    ; Вычисляем новую емкость: max(size * 2, min_capacity)
    mov     rax, r13        ; size
    shl     rax, 1          ; size * 2
    cmp     rax, [rbx + 40] ; Сравниваем с min_capacity
    jge     .new_cap_ok     ; Если >=, используем это значение
    mov     rax, [rbx + 40] ; Иначе min_capacity
    
.new_cap_ok:
    ; Убедимся, что новая емкость действительно меньше текущей
    cmp     rax, r14        ; Новая емкость < текущей?
    jge     .no_shrink      ; Если нет, не уменьшаем
    
    ; Выполняем уменьшение
    mov     rdi, rbx        ; q
    mov     rsi, rax        ; новая емкость
    call    queue_reallocate ; Перераспределяем память
    
.no_shrink:
    mov     rax, 1          ; Возвращаем true
    jmp     .exit
    
.fail_empty:
    xor     rax, rax        ; Возвращаем false
.exit:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; void queue_fill_random(Queue* q, size_t count, int32_t min_val, int32_t max_val)
queue_fill_random:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    
    mov     rbx, rdi        ; q
    mov     r12, rsi        ; count
    mov     r13d, edx       ; min_val
    mov     r14d, ecx       ; max_val
    
    ; Инициализируем random seed
    xor     rdi, rdi        ; NULL для time(NULL)
    call    time            ; Получаем текущее время
    mov     edi, eax        ; seed = time(NULL)
    call    srand           ; Инициализируем генератор
    
    ; Вычисляем range = max - min + 1
    mov     r15d, r14d      ; max_val
    sub     r15d, r13d      ; max - min
    inc     r15d            ; +1 = диапазон
    
.fill_loop:
    test    r12, r12        ; Проверяем, остались ли элементы
    jz      .done           ; Если count == 0, завершаем
    
    ; Генерируем случайное число
    call    rand            ; Возвращает в eax
    
    ; Приводим к диапазону [min, max]
    xor     rdx, rdx        ; Обнуляем для деления
    mov     ecx, r15d       ; range
    div     ecx             ; eax = rand()/range, edx = rand() % range
    
    mov     eax, edx        ; Остаток от деления (0..range-1)
    add     eax, r13d       ; + min_val -> [min, max]
    
    ; Добавляем в очередь
    mov     rdi, rbx        ; q
    mov     esi, eax        ; value
    ; Сохраняем регистры перед вызовом (не все регистры caller-saved)
    push    r12
    push    r13
    push    r14
    push    r15
    call    queue_enqueue   ; Добавляем элемент
    ; Восстанавливаем регистры
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    
    dec     r12             ; Уменьшаем счетчик
    jmp     .fill_loop      ; Повторяем
    
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; void queue_remove_even(Queue* q)
queue_remove_even:
    push    rbx
    push    r12
    push    r13
    
    mov     rbx, rdi        ; q
    
    ; Получаем текущий размер
    mov     r12, [rbx + 32] ; size
    test    r12, r12        ; Проверяем, не пуста ли очередь
    jz      .done           ; Если пуста, ничего не делаем
    
    mov     r13, r12        ; Сохраняем размер как счетчик
    
.process_loop:
    test    r13, r13        ; Проверяем, остались ли элементы
    jz      .done           ; Если нет, завершаем
    
    ; Извлекаем элемент
    mov     rdi, rbx        ; q
    sub     rsp, 16         ; Выделяем место на стеке для временного хранения
    mov     rsi, rsp        ; Указатель на временное хранилище
    call    queue_dequeue   ; Извлекаем элемент
    test    rax, rax        ; Проверяем успешность
    jz      .cleanup        ; Если false, выходим
    
    ; Получаем значение
    mov     eax, [rsp]      ; Читаем сохраненное значение
    
    ; Проверяем, четное ли число
    test    eax, 1          ; Проверяем младший бит
    jnz     .is_odd         ; Если 1, число нечетное
    
    ; Четное - не добавляем обратно
    add     rsp, 16         ; Освобождаем стек
    jmp     .continue       ; Переходим к следующему
    
.is_odd:
    ; Нечетное - добавляем обратно
    mov     rdi, rbx        ; q
    mov     esi, eax        ; value
    ; Сохраняем все caller-saved регистры
    push    rax
    push    rcx
    push    rdx
    push    r8
    push    r9
    push    r10
    push    r11
    call    queue_enqueue   ; Добавляем обратно
    ; Восстанавливаем регистры
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdx
    pop     rcx
    pop     rax
    add     rsp, 16         ; Освобождаем стек
    
.continue:
    dec     r13             ; Уменьшаем счетчик
    jmp     .process_loop   ; Повторяем
    
.cleanup:
    add     rsp, 16         ; Освобождаем стек в случае ошибки
.done:
    pop     r13
    pop     r12
    pop     rbx
    ret

; size_t queue_count_ends_with_one(Queue* q)
queue_count_ends_with_one:
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi        ; q
    xor     r12, r12        ; Обнуляем счетчик результата
    
    ; Получаем текущий размер
    mov     r13, [rbx + 32] ; size
    test    r13, r13        ; Проверяем, не пуста ли очередь
    jz      .done           ; Если пуста, возвращаем 0
    
    ; Сохраняем исходный front
    mov     r14, [rbx + 16] ; front index
    
    ; Проходим по всем элементам
    mov     rcx, [rbx]      ; Указатель на массив данных
    mov     r8, [rbx + 8]   ; capacity
    mov     r9, r13         ; Счетчик элементов
    
.check_loop:
    test    r9, r9          ; Проверяем, остались ли элементы
    jz      .done           ; Если нет, завершаем
    
    ; Получаем текущий элемент
    mov     eax, [rcx + r14*4] ; data[front + i]
    
    ; Проверяем, оканчивается ли на 1
    ; Берем абсолютное значение (для отрицательных чисел)
    cdq                     ; Расширяем eax до edx:eax
    xor     eax, edx        ; XOR с sign bit
    sub     eax, edx        ; Вычитаем sign bit -> абсолютное значение
    
    ; Делим на 10, смотрим остаток
    xor     edx, edx        ; Обнуляем для деления
    mov     r10d, 10        ; Делитель = 10
    div     r10d            ; eax = число/10, edx = число % 10
    
    cmp     edx, 1          ; Остаток == 1?
    jne     .not_ends_with_one ; Если нет, пропускаем
    
    inc     r12             ; Увеличиваем счетчик
    
.not_ends_with_one:
    ; Переходим к следующему элементу
    inc     r14             ; Увеличиваем индекс
    cmp     r14, r8         ; Проверяем на выход за границы
    jl      .no_wrap_idx    ; Если меньше capacity, продолжаем
    xor     r14, r14        ; Иначе обнуляем (циклический буфер)
.no_wrap_idx:
    
    dec     r9              ; Уменьшаем счетчик
    jmp     .check_loop     ; Повторяем
    
.done:
    mov     rax, r12        ; Возвращаем результат
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; size_t queue_get_odd_numbers(Queue* q, int32_t **buffer)
queue_get_odd_numbers:
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi        ; q
    mov     r14, rsi        ; buffer (указатель на указатель)
    
    xor     r12, r12        ; Счетчик нечетных чисел (результат)
    
    ; Получаем текущий размер
    mov     r13, [rbx + 32] ; size
    test    r13, r13        ; Проверяем, не пуста ли очередь
    jz      .no_elements    ; Если пуста, обрабатываем особый случай
    
    ; Выделяем память под результат (худший случай - все элементы нечетные)
    mov     rdi, r13        ; size (максимальное возможное количество)
    shl     rdi, 2          ; size * 4 (sizeof int32_t)
    ; Сохраняем регистры перед malloc (не все caller-saved)
    push    rbx
    push    r12
    push    r13
    push    r14
    call    malloc          ; Выделяем память
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    test    rax, rax        ; Проверяем на NULL
    jz      .error          ; Если NULL, ошибка
    
    mov     [r14], rax      ; Сохраняем указатель в переданном buffer
    mov     r8, rax         ; Сохраняем указатель на буфер для удобства
    
    ; Проходим по всем элементам очереди
    mov     rcx, [rbx]      ; Указатель на массив данных
    mov     r9, [rbx + 16]  ; front index
    mov     r10, [rbx + 8]  ; capacity
    mov     r11, r13        ; Счетчик элементов
    
.scan_loop:
    test    r11, r11        ; Проверяем, остались ли элементы
    jz      .done_scan      ; Если нет, завершаем
    
    ; Получаем текущий элемент
    mov     eax, [rcx + r9*4] ; data[front + i]
    
    ; Проверяем, нечетное ли (младший бит = 1)
    test    eax, 1          ; Проверяем младший бит
    jz      .even_number    ; Если 0, число четное
    
    ; Нечетное - сохраняем в результат
    mov     [r8 + r12*4], eax ; buffer[count] = текущий элемент
    inc     r12             ; Увеличиваем счетчик нечетных
    
.even_number:
    ; Переходим к следующему элементу
    inc     r9              ; Увеличиваем индекс
    cmp     r9, r10         ; Проверяем на выход за границы
    jl      .no_wrap_scan   ; Если меньше capacity, продолжаем
    xor     r9, r9          ; Иначе обнуляем
.no_wrap_scan:
    
    dec     r11             ; Уменьшаем счетчик
    jmp     .scan_loop      ; Повторяем
    
.done_scan:
    mov     rax, r12        ; Возвращаем количество нечетных
    jmp     .exit
    
.no_elements:
    ; Выделяем пустой буфер (1 элемент для безопасности)
    mov     rdi, 4          ; 4 байта = 1 int32_t
    ; Сохраняем регистры
    push    rbx
    push    r12
    push    r13
    push    r14
    call    malloc
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    test    rax, rax        ; Проверяем на NULL
    jz      .error          ; Если NULL, ошибка
    mov     [r14], rax      ; Сохраняем указатель на буфер
    xor     rax, rax        ; Возвращаем 0 (нет нечетных)
    jmp     .exit
    
.error:
    xor     rax, rax        ; Возвращаем 0 при ошибке
    
.exit:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
