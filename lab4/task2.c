#include <stdio.h>

int main() {
    int n;
    printf("Enter n: ");
    scanf("%d", &n);
    
    long long sum = 0;
    int k = 1;

    while (k <= n) {
        if ((k - 1) % 2 == 0) {
            sum += k * k;
        } else {
            sum -= k * k;
        }
        k++;
    }

    printf("Result: %lld\n", sum);
    return 0;
}