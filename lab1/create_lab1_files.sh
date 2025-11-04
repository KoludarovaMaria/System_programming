#!/bin/bash

echo "Создание файлов для лабораторной работы №1..."

# 1. Создаем FASM программу
cat > Koludarova.asm << 'END'
format ELF executable
entry start

segment readable executable

start:
    mov eax, 4
    mov ebx, 1
    mov ecx, surname
    mov edx, surname_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, name
    mov edx, name_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, patronymic
    mov edx, patronymic_len
    int 0x80

    mov eax, 1
    xor ebx, ebx
    int 0x80

segment readable writeable

surname db 'Koludarova', 0xA
surname_len = $-surname

name db 'Maria', 0xA
name_len = $-name

patronymic db 'Alekseevna', 0xA
patronymic_len = $-patronymic
END

# 2. Компилируем FASM
fasm Koludarova.asm Koludarova_fasm
chmod +x Koludarova_fasm

# 3. Создаем C программу
cat > C_version.c << 'END'
#include <stdio.h>

int main() {
    printf("Koludarova\n");
    printf("Maria\n");
    printf("Alekseevna\n");
    return 0;
}
END

# 4. Компилируем C программу
gcc C_version.c -o C_version

# 5. Дизассемблируем
objdump -d Koludarova_fasm > Disassemble_fasm
objdump -d C_version >> Disassemble_fasm

# 6. Создаем структуру Work
mkdir -p "Work/Лабораторная работа №1!/ФИО"

# 7. Создаем текстовые файлы
echo "Птица говорун отличается умом и сообразительностью!" > "Work/Text @1"
echo "Отличается умом, отличается сообразительностью..." >> "Work/Text @1"

cp "Work/Text @1" "Work/Text \$2"
mv "Work/Text \$2" "Work/Лабораторная работа №1!/"
cp "Work/Text @1" "Work/Лабораторная работа №1!/ФИО/"

# 8. Обработка текста
head -n1 "Work/Text @1" > "Work/Text #3"
echo "Будь осторожен! Преступник вооружен!" >> "Work/Text #3"

tac "Work/Лабораторная работа №1!/ФИО/Text @1" > "Work/Лабораторная работа №1!/ФИО/Result_two"

# 9. Системная информация
ls "Work/Лабораторная работа №1!/ФИО"/T* > "Work/Лабораторная работа №1!/Result_3" 2>/dev/null
uname -a >> "Work/Лабораторная работа №1!/Result_3"
date >> "Work/Лабораторная работа №1!/Result_3"

# 10. Архивируем
gzip "Work/Text @1" "Work/Text #3"
tar -czf MyAchiv_fasm.tar.gz "Work/Text @1.gz" "Work/Text #3.gz"
gunzip "Work/Text @1.gz" "Work/Text #3.gz"

# 11. Создаем файл команд
cat > Work_files_fasm << 'END'
# Команды лабораторной работы №1
fasm Koludarova.asm Koludarova_fasm
gcc C_version.c -o C_version
objdump -d Koludarova_fasm > Disassemble_fasm
objdump -d C_version >> Disassemble_fasm
# ... и другие команды
END

echo "Все файлы созданы!"
echo "Для проверки запустите: ./Koludarova_fasm и ./C_version"
