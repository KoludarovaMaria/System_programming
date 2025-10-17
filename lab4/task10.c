#include <stdio.h>
#include <string.h>

int main() {
    char correct_password[] = "password123";
    char input[50];
    int attempts = 0;
    int max_attempts = 5;
    
    printf("Система аутентификации\n");
    
    while (attempts < max_attempts) {
        printf("Введите пароль (попытка %d/%d): ", attempts + 1, max_attempts);
        scanf("%s", input);
        
        if (strcmp(input, correct_password) == 0) {
            printf("Вошли\n");
            return 0;
        } else {
            printf("Неверный пароль\n");
            attempts++;
        }
    }
    
    printf("Неудача\n");
    return 1;
}