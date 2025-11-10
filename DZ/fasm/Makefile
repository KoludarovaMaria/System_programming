# Компиляторы и флаги
CC = gcc
FASM = fasm
CFLAGS = -Wall -Wextra -std=c11 -O2
LDFLAGS = 

# Цели
TARGET = array_demo
OBJS = main.o array.o array_asm.o

# Правила по умолчанию
all: $(TARGET)

# Сборка основной программы
$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

# Компиляция C файлов
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Ассемблирование FASM файлов
array_asm.o: array_asm.asm
	$(FASM) array_asm.asm array_asm.o

# Очистка
clean:
	rm -f $(TARGET) $(OBJS)

# Запуск
run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
