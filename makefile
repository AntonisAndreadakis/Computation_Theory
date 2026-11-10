CC      = gcc
CFLAGS  = -Wall -g
SAMPLES = $(wildcard *.pi)

.PHONY: all test clean

all: mycompiler

mycompiler: myanalyzer.tab.c lex.yy.c cgen.c cgen.h
	$(CC) $(CFLAGS) -o $@ myanalyzer.tab.c lex.yy.c cgen.c

myanalyzer.tab.c: myanalyzer.y
	bison -d -v myanalyzer.y

myanalyzer.tab.h: myanalyzer.tab.c

lex.yy.c: mylexer.l myanalyzer.tab.h
	flex mylexer.l

# Translate every sample to C and compile the result (output goes to build/)
test: mycompiler
	@mkdir -p build
	@for f in $(SAMPLES); do \
		n=$${f%.pi}; \
		./mycompiler < $$f > build/$$n.c 2> build/$$n.log \
			&& $(CC) -Wall -I. -o build/$$n build/$$n.c -lm \
			&& echo "PASS $$f" || { echo "FAIL $$f"; cat build/$$n.log; exit 1; }; \
	done

clean:
	rm -f myanalyzer.tab.c myanalyzer.tab.h myanalyzer.output lex.yy.c mycompiler
	rm -rf build
