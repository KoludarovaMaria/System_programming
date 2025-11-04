#include <stdio.h>

int main() {
    long long number = 5277616985;
    int sum = 0;
    long long temp = number;
    
    while (temp != 0) {
        sum += temp % 10;
        temp /= 10;
    }
    
    printf("Number: %lld\n", number);
    printf("Sum of digits: %d\n", sum);
    return 0;
}