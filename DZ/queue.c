#include "queue.h"
#include <stdio.h>
#include <sys/mman.h>

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