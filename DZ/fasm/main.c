#include "array.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main() {
    printf("=== Демонстрация работы с массивом (анонимное отображение) ===\n");
    
    // Инициализация массива
    DynamicArray *arr = array_init(50);
    if (!arr) {
        printf("Ошибка инициализации массива!\n");
        return 1;
    }
    
    printf("1. Создание массива размером 10\n");
    array_create_asm(arr, 10);
    array_print(arr);
    
    printf("\n2. Заполнение массива случайными числами\n");
    array_fill_random_asm(arr);
    array_print(arr);
    
    printf("\n3. Нахождение суммы элементов массива\n");
    int sum = array_sum_asm(arr);
    printf("Сумма элементов: %d\n", sum);
    
    printf("\n4. Подсчет количества четных чисел\n");
    size_t even_count = array_count_even_asm(arr);
    printf("Количество четных чисел: %zu\n", even_count);
    
    printf("\n5. Получение списка нечетных чисел\n");
    int odd_numbers[50];
    size_t odd_count = 0;
    array_get_odd_numbers_asm(arr, odd_numbers, &odd_count);
    printf("Нечетные числа (%zu): ", odd_count);
    for (size_t i = 0; i < odd_count; i++) {
        printf("%d ", odd_numbers[i]);
    }
    printf("\n");
    
    printf("\n6. Подсчет количества простых чисел\n");
    size_t prime_count = array_count_primes_asm(arr);
    printf("Количество простых чисел: %zu\n", prime_count);
    
    printf("\n7. Реверсирование элементов массива\n");
    printf("До реверса: ");
    array_print(arr);
    array_reverse_asm(arr);
    printf("После реверса: ");
    array_print(arr);
    
    // Освобождение памяти
    array_free(arr);
    
    printf("\nПрограмма завершена успешно!\n");
    return 0;
}
