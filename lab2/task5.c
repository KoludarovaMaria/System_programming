#include <stdio.h>

int sum_of_digits(long long n) {
    int sum = 0;
    while (n > 0) {
        sum += n % 10;
        n /= 10;
    }
    return sum;
}

int main() {
    long long number = 5277616985;
    int result = sum_of_digits(number);
    printf("Sum of digits: %d\n", result);
    return 0;
}