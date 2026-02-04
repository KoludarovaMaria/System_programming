FASM = fasm
CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -g -m64 -fno-pie -no-pie
LDFLAGS = -m64 -no-pie
TARGET = queue_demo
OBJECTS = queue.o main.o

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS)

queue.o: queue1.asm
	$(FASM) $< $@

main.o: main.c queue.h
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run