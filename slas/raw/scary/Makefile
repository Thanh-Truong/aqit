CC=gcc
CFLAGS=-Wall -O4 -g
LDFLAGS= -g
PFORDELTA=../pfordelta
SOURCES=scary.c main.c $(PFORDELTA)/pack.c $(PFORDELTA)/pfordelta.c $(PFORDELTA)/s16.c $(PFORDELTA)/unpack.c $(PFORDELTA)/coding_policy.c
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=scary


all: $(SOURCES) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS) 
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm $(OBJECTS) $(EXECUTABLE)
