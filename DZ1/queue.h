#ifndef QUEUE_H
#define QUEUE_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

// Структура очереди с динамическим массивом
typedef struct {
    int32_t *data;      // указатель на динамический массив
    size_t capacity;    // текущая емкость массива
    size_t front;       // индекс первого элемента
    size_t rear;        // индекс последнего элемента
    size_t size;        // текущий размер очереди
    size_t min_capacity;// минимальная емкость
} Queue;

// Функции, реализованные на ассемблере
#ifdef __cplusplus
extern "C" {
#endif

Queue* queue_create(size_t initial_capacity);
void queue_destroy(Queue* q);
bool queue_enqueue(Queue* q, int32_t value);
bool queue_dequeue(Queue* q, int32_t *value);
void queue_fill_random(Queue* q, size_t count, int32_t min_val, int32_t max_val);
void queue_remove_even(Queue* q);
size_t queue_count_ends_with_one(Queue* q);
size_t queue_get_odd_numbers(Queue* q, int32_t **buffer);

#ifdef __cplusplus
}
#endif

#endif // QUEUE_H