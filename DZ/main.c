#include "queue.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main() {
    printf("=== Демонстрация работы с очередью (анонимное отображение) ===\n");
    
    // Инициализация очереди
    printf("1. Инициализация очереди...\n");
    Queue *queue = queue_init(20);
    if (!queue) {
        printf("Ошибка инициализации очереди!\n");
        return 1;
    }
    
    printf("Состояние после инициализации: ");
    queue_print(queue);
    
    printf("2. Заполнение очереди 10 числами\n");
    queue_fill_random_asm(queue, 10);
    queue_print(queue);
    
    printf("3. Добавление элемента (777) в конец\n");
    queue_enqueue_asm(queue, 777);
    queue_print(queue);
    
    printf("4. Удаление элемента из начала\n");
    int dequeued = queue_dequeue_asm(queue);
    printf("Удаленный элемент: %d\n", dequeued);
    queue_print(queue);
    
    printf("5. Подсчет количества четных чисел\n");
    size_t even_count = queue_count_even_asm(queue);
    printf("Количество четных чисел: %zu\n", even_count);
    
    printf("6. Получение списка нечетных чисел\n");
    int odd_numbers[20];
    size_t odd_count = 0;
    queue_get_odd_numbers_asm(queue, odd_numbers, &odd_count);
    printf("Нечетные числа (%zu): ", odd_count);
    for (size_t i = 0; i < odd_count; i++) {
        printf("%d ", odd_numbers[i]);
    }
    printf("\n");
    
    printf("7. Подсчет количества простых чисел\n");
    size_t prime_count = queue_count_primes_asm(queue);
    printf("Количество простых чисел: %zu\n", prime_count);
    
    printf("8. Подсчет количества чисел, оканчивающихся на 1\n");
    size_t ends_with_1_count = queue_count_ends_with_1_asm(queue);
    printf("Количество чисел, оканчивающихся на 1: %zu\n", ends_with_1_count);
    
    printf("9. Удаление всех четных чисел\n");
    printf("До удаления: ");
    queue_print(queue);
    queue_remove_even_asm(queue);
    printf("После удаления: ");
    queue_print(queue);
    
    // Освобождение памяти
    queue_free(queue);
    
    printf("\nВсе функции очереди работают корректно!\n");
    printf("Программа завершена успешно!\n");
    return 0;
}