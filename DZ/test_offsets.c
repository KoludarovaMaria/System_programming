#include <stdio.h>
#include <stddef.h>

typedef struct {
    int *data;
    size_t front;
    size_t rear;
    size_t size;
    size_t capacity;
} Queue;

int main() {
    printf("sizeof(Queue) = %zu\n", sizeof(Queue));
    printf("offsetof(data) = %zu\n", offsetof(Queue, data));
    printf("offsetof(front) = %zu\n", offsetof(Queue, front));
    printf("offsetof(rear) = %zu\n", offsetof(Queue, rear));
    printf("offsetof(size) = %zu\n", offsetof(Queue, size));
    printf("offsetof(capacity) = %zu\n", offsetof(Queue, capacity));
    return 0;
}
