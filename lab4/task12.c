#include <stdio.h>   // для printf
#include <stdbool.h> // для типа bool (C99 и выше)

// Функция проверки, что цифры числа идут в неубывающем порядке слева направо
bool check(int n) {
    int last = n % 10;  // получаем последнюю цифру
    n /= 10;            // удаляем последнюю цифру
    
    while (n > 0) {
        int curr = n % 10;  // текущая цифра (справа налево)
        if (curr > last) return false;  // если текущая больше предыдущей
        last = curr;        // обновляем предыдущую цифру
        n /= 10;           // удаляем текущую цифру
    }
    return true;
}

int main() {
    // Использование тернарного оператора для вывода Yes/No
    printf("1489: %s\n", check(1489) ? "Yes" : "No");
    printf("4632: %s\n", check(4632) ? "Yes" : "No");
    
    return 0;
}