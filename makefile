all: lexer parser compiler print_init

	
lexer: 
	@flex mylexer.l

	

	
parser:
	@bison -d -v -r all myanalyzer.y

	
	
compiler:
	@gcc -o mycompiler myanalyzer.tab.c lex.yy.c -lfl

	

	
clean:
	@rm -f  myanalyzer.tab.c lex.yy.c
	@rm -f  myanalyzer.tab.h
	@rm -f *.output 
	@rm -f mycompiler
	@rm -f myanalyzer_output.c
	

	
	
print_init: 
	@echo "Pi compiler created!"


	
