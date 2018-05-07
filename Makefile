include local.mk
CC=chpl
MODULES=-M$(CHINGON_HOME)/src -M$(CDO_HOME)/src -M$(NUMSUCH_HOME)/src -M$(CDOEXTRAS_HOME)/src
INCLUDES = -I/usr/include -I$(BLAS_HOME)/include -I$(POSTGRES_HOME)
LIBS=-L$(BLAS_HOME)/lib -lblas
FLAGS=--fast --print-callstack-on-error --print-commands
SRCDIR=src
BINDIR=bin
TESTDIR=test
EXEC=relch
TEST_MODULES=-M$(CHARCOAL_HOME)/src -M$(SRCDIR)

default: $(SRCDIR)/Relch.chpl
	$(CC) $(MODULES) $(FLAGS) ${INCLUDES} ${LIBS} -o $(BINDIR)/$(EXEC) $<

run:
	./$(BINDIR)/$(EXEC) -f qlearn.cfg


test: $(SRCDIR)/Relch.chpl $(SRCDIR)/policies.chpl $(SRCDIR)/agents.chpl $(TESTDIR)/RelchTests.chpl 
	$(CC) $(MODULES) $(TEST_MODULES) $(FLAGS) ${INCLUDES} ${LIBS} -o $(TESTDIR)/test $(TESTDIR)/RelchTests.chpl ;\
	./$(TESTDIR)/test ; \
	rm $(TESTDIR)/test
