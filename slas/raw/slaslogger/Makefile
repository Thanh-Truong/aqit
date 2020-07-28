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

CC = gcc

CFLAGS = $(XFLAGS) -O2 -DUNIX=1 -DLINUX=1  -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -g -m32 

BINDIR = $(AMOS_HOME)/bin

SOURCES = slaslogger.c test.c read_blogfile.c write_blogfile.c slwindow.c  ../winstats/slwinstats.c
OBJECTS =$(SOURCES:.c=.o)

INCLUDES = -I$(AMOS_HOME)/C -I$(AMOS_HOME)/system/include -I$(AMOS_HOME)/scsq/include -I../../common -I$(AMOS_HOME)/validate/C

all: $(BINDIR)/liblofixP.so $(BINDIR)/liblofixS.so logger $(OBJECTS)
	$(CC) -O2  $(CFLAGS) $(INCLUDES) \
              -o $(AMOS_HOME)/bin/slasraw.exe main.c  $(AMOS_HOME)/validate/C/swin.c -L$(BINDIR) $(SRCDIR) \
              $(AMOS_HOME)/bin/libscsq.a ../lofixP/lofixP.o ../lofixS/lofixS.o ../../common/pbt.o ../logger/logger.o -lamos -lm $(DL) -m32 -lpthread $(OBJECTS)
ifeq ($(ARCHITECTURE),Apple32)
	install_name_tool -change libamos.so @executable_path/libamos.so \
                          $(BINDIR)/slasraw.exe
endif

$(BINDIR)/liblofixP.so: 
	cd ../lofixP && make clean && make

$(BINDIR)/liblofixS.so: 
	cd ../lofixS && make clean && make

logger:
	cd ../logger && make clean && make

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES)

clean:
	rm -f $(BINDIR)/slasraw.exe *.o  $(BINDIR)/slasraw.dmp
	rm -f $(BINDIR)/liblofixP.so $(BINDIR)/liblofixS.so
	cd ../logger && make clean
	cd ../winstats && rm -f *.o
	cd ../slaslogger && rm -f *.o
