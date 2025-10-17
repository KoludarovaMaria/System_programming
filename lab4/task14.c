#include <stdio.h>

int main() {
    int n;
    
    printf("Введите n: ");
    scanf("%d", &n);
    
    printf("Числа, совпадающие с последними разрядами своих квадратов:\n");
    
    for (int i = 1; i <= n; i++) {
        long long square = (long long)i * i;
        int temp = i;
        int digits = 0;
        
        while (temp > 0) {
            digits++;
            temp /= 10;
        }
        
        long long power = 1;
        for (int j = 0; j < digits; j++) {
            power *= 10;
        }
        
        if (square % power == i) {
            printf("%d (квадрат: %lld)\n", i, square);
        }
    }
    
    return 0;
}