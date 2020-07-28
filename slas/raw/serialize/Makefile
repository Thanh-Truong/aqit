CC=gcc
CFLAGS=-Wall -O9
LDFLAGS=
SOURCES1=serialize.c
SOURCES2=derialize.c 
OBJECTS1=$(SOURCES1:.c=.o)
OBJECTS2=$(SOURCES2:.c=.o)
EXECUTABLE1=serialize
EXECUTABLE2=deserialize

debug: CFLAGS+=-g
debug: LDFLAGS+=-g

all: se des

se: $(SOURCES1) $(EXECUTABLE1)

des: $(SOURCES2) $(EXECUTABLE2)

$(EXECUTABLE1): $(OBJECTS1) 
	$(CC) $(LDFLAGS) $(OBJECTS1) -o $@

$(EXECUTABLE2): $(OBJECTS2) 
	$(CC) $(LDFLAGS) $(OBJECTS2) -o $@

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm $(OBJECTS1) $(EXECUTABLE1)
	rm $(OBJECTS2) $(EXECUTABLE2)
