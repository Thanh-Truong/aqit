ifndef ARCHITECTURE
  $(error The environment variable ARCHITECTURE not set!)
endif

ifeq ($(ARCHITECTURE),Apple32)
XFLAGS = -mmacosx-version-min=10.6
LFLAGS = -m32 -undefined dynamic_lookup -dynamic
endif

ifeq ($(ARCHITECTURE),Linux32)
LFLAGS = -m32 -shared -L $(AMOS_HOME)/bin -l amos 
endif

CC = cc

CFLAGS = -O2 -G -DUNIX=1 -DLINUX=1 -U_FORTIFY_SOURCE -m32 $(XFLAGS)
PFORDELTA=../../pfordelta
SOURCES = darray.c scary.c $(PFORDELTA)/pack.c $(PFORDELTA)/pfordelta.c $(PFORDELTA)/s16.c $(PFORDELTA)/unpack.c $(PFORDELTA)/coding_policy.c

LIBDIR = $(AMOS_HOME)/bin

INCLUDES= -I $(AMOS_HOME)/C -I $(AMOS_HOME)/system/include -I $(PFORDELTA)/

OBJECTS=$(SOURCES:.c=.o)

all: $(OBJECTS)
	$(CC) $(LFLAGS) -o $(LIBDIR)/scaryamos.so -lm -lpthread $(OBJECTS)

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES) 

clean:
	rm -f $(OBJECTS)
