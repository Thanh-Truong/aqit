ifndef ARCHITECTURE
  $(error The environment variable ARCHITECTURE not set!)
endif

export LD_LIBRARY_PATH=$(AMOS_HOME)/bin

ifeq ($(ARCHITECTURE),Apple32)
XFLAGS = -mmacosx-version-min=10.6
endif

ifeq ($(ARCHITECTURE),Linux32)
DL = -ldl
endif

CC = cc

CFLAGS = $(XFLAGS) -O2 -DUNIX=1 -DLINUX=1 -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -m32

BINDIR = $(AMOS_HOME)/bin

SOURCES = basictest.c logger.c main.c

OBJECTS=$(SOURCES:.c=.o)

INCLUDES = -I$(AMOS_HOME)/C -I$(AMOS_HOME)/system/include

all:  loggerx

loggerx: $(OBJECTS)
	$(CC) -O2  $(CFLAGS) $(INCLUDES) \
              -o logger -L$(BINDIR) $(SRCDIR) \
              -lm $(DL) -m32 -lpthread $(OBJECTS)
%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES) 
clean:
	rm -f *.o
	rm -f logger
