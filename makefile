
TARGET=dgemm_test

# compiler
CC=gcc
# debug
DEBUG=-g
# optimisation
OPT=-O2
# warnings
WARN=-Wall

GSLFLAGS=-L/usr/lib/arm-linux-gnueabihf -lgsl -lm

BLASFLAG=-lblas

OMPFLAGS=-fopenmp

CCFLAGS= $(OPT) $(WARN) $(GSLFLAGS) $(BLASGSL) $(OMPFLAGS)

# linker
LD=gcc
LDFLAGS=$(GSLFLAGS) $(BLASFLAG) $(OMPFLAGS) -export-dynamic

OBJS=dgemm_test.o
SRC=teste_GSL_DGEMM.c

all: $(OBJS)
	$(LD) -o $(TARGET) $(OBJS) $(LDFLAGS)

dgemm_test.o: $(SRC)
	$(CC) -c $(CCFLAGS) $(SRC)  -o $(OBJS)

clean:
	rm -f *.o $(TARGET)
