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

CFLAGS = -O2 -DUNIX=1 -DLINUX=1  -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -m32 -g $(XFLAGS)

SOURCES = lofixP.c ../../common/pbt.c

LIBDIR = $(AMOS_HOME)/bin

INCLUDES= -I $(AMOS_HOME)/C -I $(AMOS_HOME)/system/include 

OBJECTS=$(SOURCES:.c=.o)

all: $(OBJECTS)
	$(CC) $(LFLAGS) -o $(LIBDIR)/liblofixP.so -lm -lpthread $(OBJECTS) 

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES) 

clean:
	rm -f $(OBJECTS)
	rm -f $(LIBDIR)/liblofixP.so
