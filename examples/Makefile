include ../local.mk

CC=chpl
MODULES=-M$(CHINGON_HOME)/src -M$(CDO_HOME)/src -M$(NUMSUCH_HOME)/src -M$(CDOEXTRAS_HOME)/src
INCLUDES = -I/usr/include -I$(BLAS_HOME)/include -I$(POSTGRES_HOME)
LIBS=-L$(BLAS_HOME)/lib -lblas
FLAGS=--fast --print-callstack-on-error --print-commands
SRCDIR=src
BINDIR=bin
TESTDIR=test
EXEC=relch

default: dungeon run-dungeon

run-fl: frozenLake.chpl
	$(CC) -M../src $(MODULES) $(FLAGS) ${INCLUDES} ${LIBS} -o fl $< ; \
	./fl -f frozenLake.cfg; \
	rm fl;

elsa: elsa.chpl
	rm elsa; \
	$(CC) -M../src $(MODULES) $(FLAGS) ${INCLUDES} ${LIBS} -o elsa $<

run-elsa:
	./elsa -f elsa.cfg

dungeon: dungeon.chpl
	rm dungeon; \
	$(CC) -M../src $(MODULES) $(FLAGS) ${INCLUDES} ${LIBS} -o dungeon $<

run-dungeon:
	./dungeon -f dungeon.cfg

circle: circle_nn.chpl
	$(CC) -M../src $(MODULES) $(FLAGS) ${INCLUDES} ${LIBS} -o circle $< ; \
	./circle; \
	rm ./circle
