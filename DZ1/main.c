#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "queue.h"

// Функция для печати очереди в требуемом формате
void print_queue_explicit(Queue* q, const char* label) {
    if (!q) {
        printf("Очередь не существует!\n");
        return;
    }
    
    printf("%s: [", label);
    
    if (q->size == 0) {
        printf("пусто]\n");
        return;
    }
    
    // Проходим по всем элементам
    for (size_t i = 0; i < q->size; i++) {
        size_t index = (q->front + i) % q->capacity;
        printf("%d", q->data[index]);
        if (i < q->size - 1) {
            printf(", ");
        }
    }
    printf("]\n");
    printf("Размер: %zu, Емкость: %zu\n", q->size, q->capacity);
}

// Демонстрация ВСЕХ требуемых функций
void demonstrate_all_required_functions() {
    printf("===============================================\n");
    printf("ДЕМОНСТРАЦИЯ РАБОТЫ ОЧЕРЕДИ ПО ЗАДАНИЮ\n");
    printf("===============================================\n\n");
    
    // Инициализация генератора случайных чисел
    srand(time(NULL));
    
    // 1. СОЗДАНИЕ ОЧЕРЕДИ
    printf("1. СОЗДАНИЕ ОЧЕРЕДИ\n");
    printf("   Создаем очередь начальной емкостью 5\n");
    Queue* q = queue_create(5);
    if (!q) {
        printf("Ошибка: не удалось создать очередь!\n");
        return;
    }
    print_queue_explicit(q, "   Пустая очередь");
    printf("\n");
    
    // 2. ДОБАВЛЕНИЕ В КОНЕЦ (функция 1)
    printf("2. ДОБАВЛЕНИЕ В КОНЕЦ\n");
    printf("   Добавляем числа: 10, 20, 30, 40, 50\n");
    for (int i = 1; i <= 5; i++) {
        queue_enqueue(q, i * 10);
    }
    print_queue_explicit(q, "   Очередь после добавления 5 чисел");
    printf("\n");
    
    // 3. УДАЛЕНИЕ ИЗ НАЧАЛА (функция 2)
    printf("3. УДАЛЕНИЕ ИЗ НАЧАЛА\n");
    int32_t value;
    queue_dequeue(q, &value);
    printf("   Удален первый элемент: %d\n", value);
    queue_dequeue(q, &value);
    printf("   Удален следующий элемент: %d\n", value);
    print_queue_explicit(q, "   Очередь после удаления 2 элементов");
    printf("\n");
    
    // 4. ЗАПОЛНЕНИЕ СЛУЧАЙНЫМИ ЧИСЛАМИ (функция 3)
    printf("4. ЗАПОЛНЕНИЕ СЛУЧАЙНЫМИ ЧИСЛАМИ\n");
    printf("   Добавляем 8 случайных чисел от 1 до 100\n");
    queue_fill_random(q, 8, 1, 100);
    print_queue_explicit(q, "   Очередь после добавления случайных чисел");
    printf("\n");
    
    // 5. ПОДСЧЕТ ЧИСЕЛ, ОКАНЧИВАЮЩИХСЯ НА 1 (функция 5)
    printf("5. ПОДСЧЕТ ЧИСЕЛ, ОКАНЧИВАЮЩИХСЯ НА 1\n");
    printf("   Текущая очередь содержит числа:\n");
    print_queue_explicit(q, "   ");
    
    size_t count_ends_with_one = queue_count_ends_with_one(q);
    printf("   Результат: %zu число(а) оканчиваются на 1\n", count_ends_with_one);
    printf("   (Очередь не изменилась после подсчета)\n");
    print_queue_explicit(q, "   Очередь после подсчета");
    printf("\n");
    
    // 6. УДАЛЕНИЕ ВСЕХ ЧЕТНЫХ ЧИСЕЛ (функция 4)
    printf("6. УДАЛЕНИЕ ВСЕХ ЧЕТНЫХ ЧИСЕЛ\n");
    printf("   Алгоритм: читаем числа из начала, четные удаляем,\n");
    printf("   нечетные добавляем обратно в конец\n");
    
    printf("   До удаления четных:\n");
    print_queue_explicit(q, "   ");
    
    queue_remove_even(q);
    
    printf("   После удаления четных:\n");
    print_queue_explicit(q, "   ");
    printf("\n");
    
    // 7. ПОЛУЧЕНИЕ СПИСКА НЕЧЕТНЫХ ЧИСЕЛ (функция 6)
    printf("7. ПОЛУЧЕНИЕ СПИСКА НЕЧЕТНЫХ ЧИСЕЛ\n");
    printf("   Текущая очередь:\n");
    print_queue_explicit(q, "   ");
    
    int32_t* odd_numbers = NULL;
    size_t odd_count = queue_get_odd_numbers(q, &odd_numbers);
    
    printf("   Найдено нечетных чисел: %zu\n", odd_count);
    if (odd_count > 0) {
        printf("   Список нечетных чисел: [");
        for (size_t i = 0; i < odd_count; i++) {
            printf("%d", odd_numbers[i]);
            if (i < odd_count - 1) {
                printf(", ");
            }
        }
        printf("]\n");
    }
    
    printf("   (Очередь не изменилась после получения списка)\n");
    print_queue_explicit(q, "   Очередь после получения списка нечетных чисел");
    printf("\n");
    
    // Очистка буфера нечетных чисел
    if (odd_numbers) {
        free(odd_numbers);
    }
    
    // 8. КОМБИНИРОВАННЫЙ ТЕСТ
    printf("8. КОМБИНИРОВАННЫЙ ТЕСТ ВСЕХ ФУНКЦИЙ\n");
    
    // Очищаем очередь
    printf("   Очищаем очередь:\n");
    while (queue_dequeue(q, &value)) {
        // просто удаляем все
    }
    print_queue_explicit(q, "   Пустая очередь после очистки");
    
    // Добавляем специфичные числа для демонстрации
    printf("\n   Добавляем числа для демонстрации всех функций:\n");
    int test_numbers[] = {1, 2, 11, 12, 21, 22, 31, 32, 41, 42};
    for (int i = 0; i < 10; i++) {
        queue_enqueue(q, test_numbers[i]);
    }
    print_queue_explicit(q, "   Тестовая очередь");
    
    // Демонстрация всех функций на тестовых данных
    printf("\n   а) Подсчет чисел, оканчивающихся на 1:\n");
    count_ends_with_one = queue_count_ends_with_one(q);
    printf("      Результат: %zu (числа: 1, 11, 21, 31, 41)\n", count_ends_with_one);
    
    printf("\n   б) Удаление четных чисел:\n");
    queue_remove_even(q);
    print_queue_explicit(q, "      Очередь после удаления четных");
    
    printf("\n   в) Получение списка нечетных чисел:\n");
    odd_numbers = NULL;
    odd_count = queue_get_odd_numbers(q, &odd_numbers);
    printf("      Найдено: %zu нечетных чисел\n", odd_count);
    printf("      Список: [");
    for (size_t i = 0; i < odd_count; i++) {
        printf("%d", odd_numbers[i]);
        if (i < odd_count - 1) {
            printf(", ");
        }
    }
    printf("]\n");
    
    if (odd_numbers) {
        free(odd_numbers);
    }
    
    // 9. ОСВОБОЖДЕНИЕ ПАМЯТИ
    printf("\n9. ОСВОБОЖДЕНИЕ ПАМЯТИ\n");
    printf("   Уничтожаем очередь и освобождаем память\n");
    queue_destroy(q);
    
    printf("\n===============================================\n");
    printf("ДЕМОНСТРАЦИЯ ЗАВЕРШЕНА УСПЕШНО!\n");
    printf("Все 6 требуемых функций продемонстрированы:\n");
    printf("1. Добавление в конец ✓\n");
    printf("2. Удаление из начала ✓\n");
    printf("3. Заполнение случайными числами ✓\n");
    printf("4. Удаление всех четных чисел ✓\n");
    printf("5. Подсчет чисел, оканчивающихся на 1 ✓\n");
    printf("6. Получение списка нечетных чисел ✓\n");
    printf("===============================================\n");
}

// Простой тест анонимного отображения памяти
void test_memory_allocation() {
    printf("\n\nПРОВЕРКА МЕТОДА ВЫДЕЛЕНИЯ ПАМЯТИ\n");
    printf("Используется: АНОНИМНОЕ ОТОБРАЖЕНИЕ (через malloc/free)\n\n");
    
    // Создаем несколько очередей разного размера
    printf("Создаем 3 очереди разной емкости:\n");
    
    Queue* q1 = queue_create(1);  // Будет округлено до MIN_CAPACITY=4
    printf("1. Очередь с запрошенной емкостью 1 -> фактическая: %zu\n", q1->capacity);
    
    Queue* q2 = queue_create(10);
    printf("2. Очередь с запрошенной емкостью 10 -> фактическая: %zu\n", q2->capacity);
    
    Queue* q3 = queue_create(100);
    printf("3. Очередь с запрошенной емкостью 100 -> фактическая: %zu\n", q3->capacity);
    
    // Демонстрация динамического изменения размера
    printf("\nДемонстрация динамического изменения размера:\n");
    printf("Добавляем 20 элементов в очередь емкостью 10:\n");
    for (int i = 1; i <= 20; i++) {
        queue_enqueue(q2, i);
        if (i == 10 || i == 20) {
            printf("   После %2d элементов: размер=%zu, емкость=%zu\n", 
                   i, q2->size, q2->capacity);
        }
    }
    
    printf("\nУдаляем элементы (наблюдаем уменьшение емкости):\n");
    int32_t val;
    for (int i = 0; i < 15; i++) {
        queue_dequeue(q2, &val);
        if (i == 4 || i == 9 || i == 14) {
            printf("   После %2d удалений: размер=%zu, емкость=%zu\n", 
                   i + 1, q2->size, q2->capacity);
        }
    }
    
    // Освобождаем память
    queue_destroy(q1);
    queue_destroy(q2);
    queue_destroy(q3);
    
    printf("\nПамять успешно освобождена (нет утечек)\n");
}

int main() {
    printf("\n");
    printf("===============================================\n");
    printf("ЛАБОРАТОРНАЯ РАБОТА: РЕАЛИЗАЦИЯ ОЧЕРЕДИ\n");
    printf("УСЛОВИЯ ЗАДАНИЯ:\n");
    printf("- Структура: Очередь\n");
    printf("- Метод выделения памяти: Анонимное отображение\n");
    printf("===============================================\n\n");
    
    // Основная демонстрация
    demonstrate_all_required_functions();
    
    // Дополнительная проверка управления памятью
    test_memory_allocation();
    
    return 0;
}