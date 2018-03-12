include local.mk
CC=chpl
MODULES=-M$(CHINGON_HOME)/src -M$(CDO_HOME)/src -M$(NUMSUCH_HOME)/src -M$(CHREST_HOME)/src
INCLUDES = -I/usr/include -I$(BLAS_HOME)/include -I$(POSTGRES_HOME)
LIBS=-L$(BLAS_HOME)/lib -lblas
FLAGS=--fast --print-callstack-on-error --print-commands
SRCDIR=src
BINDIR=bin
TESTDIR=test
EXEC=relch

default: $(SRCDIR)/Relch.chpl
	$(CC) $(MODULES) $(FLAGS) ${INCLUDES} ${LIBS} -o $(BINDIR)/$(EXEC) $<

run:
	./$(BINDIR)/$(EXEC)
