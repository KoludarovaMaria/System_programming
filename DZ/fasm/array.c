#include "array.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Объявляем rand как внешнюю функцию для FASM
extern int rand(void);

DynamicArray* array_init(size_t capacity) {
    // Создаем анонимное отображение памяти для структуры и данных
    size_t total_size = sizeof(DynamicArray) + capacity * sizeof(int);
    void *memory = mmap(NULL, total_size, 
                       PROT_READ | PROT_WRITE, 
                       MAP_PRIVATE | MAP_ANONYMOUS, 
                       -1, 0);
    
    if (memory == MAP_FAILED) {
        return NULL;
    }
    
    DynamicArray *arr = (DynamicArray*)memory;
    arr->data = (int*)((char*)memory + sizeof(DynamicArray));
    arr->size = 0;
    arr->capacity = capacity;
    
    // Инициализация генератора случайных чисел
    srand(time(NULL));
    
    return arr;
}

void array_free(DynamicArray *arr) {
    if (arr) {
        size_t total_size = sizeof(DynamicArray) + arr->capacity * sizeof(int);
        munmap(arr, total_size);
    }
}

void array_print(DynamicArray *arr) {
    if (arr->size == 0) {
        printf("Массив пуст\n");
        return;
    }
    
    printf("Массив[%zu]: ", arr->size);
    for (size_t i = 0; i < arr->size; i++) {
        printf("%d ", arr->data[i]);
    }
    printf("\n");
}
