# Компиляторы и флаги
CC = gcc
FASM = fasm
CFLAGS = -Wall -Wextra -std=c11 -O2
LDFLAGS = 

# Цели
TARGET = queue_demo
OBJS = main.o queue.o queue_asm.o

# Правила по умолчанию
all: $(TARGET)

# Сборка основной программы
$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) -o $@

# Компиляция C файлов
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Ассемблирование FASM файлов
queue_asm.o: queue_asm.asm
	$(FASM) queue_asm.asm queue_asm.o

# Очистка
clean:
	rm -f $(OBJS) $(TARGET)

# Запуск
run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run