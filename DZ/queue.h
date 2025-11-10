#ifndef QUEUE_H
#define QUEUE_H

#include <stddef.h>
#include <sys/mman.h>

typedef struct {
    int *data;
    size_t front;
    size_t rear;
    size_t size;
    size_t capacity;
} Queue;

// Инициализация очереди с анонимным отображением
Queue* queue_init(size_t capacity);
// Освобождение памяти
void queue_free(Queue *q);

// Ассемблерные функции
extern void queue_enqueue_asm(Queue *q, int value);
extern int queue_dequeue_asm(Queue *q);
extern void queue_fill_random_asm(Queue *q, size_t count);
extern size_t queue_count_even_asm(Queue *q);
extern void queue_get_odd_numbers_asm(Queue *q, int *result, size_t *count);
extern size_t queue_count_primes_asm(Queue *q);
extern size_t queue_count_ends_with_1_asm(Queue *q);
extern void queue_remove_even_asm(Queue *q);

// Вспомогательные функции на C
int queue_is_empty(Queue *q);
int queue_is_full(Queue *q);
void queue_print(Queue *q);

#endif