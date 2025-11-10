#ifndef ARRAY_H
#define ARRAY_H

#include <stddef.h>
#include <sys/mman.h>

typedef struct {
    int *data;
    size_t size;
    size_t capacity;
} DynamicArray;

// Инициализация массива с анонимным отображением
DynamicArray* array_init(size_t capacity);
// Освобождение памяти
void array_free(DynamicArray *arr);

// Ассемблерные функции
extern void array_create_asm(DynamicArray *arr, size_t size);
extern void array_fill_random_asm(DynamicArray *arr);
extern int array_sum_asm(DynamicArray *arr);
extern size_t array_count_even_asm(DynamicArray *arr);
extern void array_get_odd_numbers_asm(DynamicArray *arr, int *result, size_t *count);
extern size_t array_count_primes_asm(DynamicArray *arr);
extern void array_reverse_asm(DynamicArray *arr);

// Вспомогательные функции на C
void array_print(DynamicArray *arr);

#endif
