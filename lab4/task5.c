#include <stdio.h>

int main() {
    int n, count = 0;
    
    printf("Введите n: ");
    scanf("%d", &n);
    
    for (int i = 1; i <= n; i++) {
        if (i % 11 != 0 && i % 5 != 0) {
            count++;
        }
    }
    
    printf("Количество чисел от 1 до %d, не делящихся на 11 или на 5: %d\n", n, count);
    return 0;
}