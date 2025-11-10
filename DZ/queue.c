#include "queue.h"
#include <stdio.h>
#include <stdlib.h>

Queue* queue_init(size_t capacity) {
    // Создаем анонимное отображение памяти для структуры и данных
    size_t total_size = sizeof(Queue) + capacity * sizeof(int);
    void *memory = mmap(NULL, total_size, 
                       PROT_READ | PROT_WRITE, 
                       MAP_PRIVATE | MAP_ANONYMOUS, 
                       -1, 0);
    
    if (memory == MAP_FAILED) {
        return NULL;
    }
    
    Queue *q = (Queue*)memory;
    q->data = (int*)((char*)memory + sizeof(Queue));
    q->front = 0;
    q->rear = 0;
    q->size = 0;
    q->capacity = capacity;
    
    return q;
}

void queue_free(Queue *q) {
    if (q) {
        size_t total_size = sizeof(Queue) + q->capacity * sizeof(int);
        munmap(q, total_size);
    }
}

int queue_is_empty(Queue *q) {
    return q->size == 0;
}

int queue_is_full(Queue *q) {
    return q->size == q->capacity;
}

void queue_print(Queue *q) {
    if (queue_is_empty(q)) {
        printf("Очередь пуста\n");
        return;
    }
    
    printf("Очередь[%zu]: ", q->size);
    for (size_t i = 0; i < q->size; i++) {
        size_t index = (q->front + i) % q->capacity;
        printf("%d ", q->data[index]);
    }
    printf("\n");
}