#Andreadakis Antonios 2013030059

#Description:
	This is a lexical and syntactical analysis of the imaginary language pi,
	using flex and bison. To be more specific, I am creating a transpiler.
	My program reads .pi files, search for Lexical and Syntactical mistakes
	and then translate the .pi file in to .c file. We accept it if there is no
	lexical	or syntactical error.
	If no error occurs compile it and execute it.

#Executing files:
	I created a Makefile in order to compile myanalyzer.y and mylexer.l
	Simply open a terminal on the specific folder and type 'make'.
	Then, execute command "./mycompiler < anyFilename.pi" in order to
	have a visual result or "./mycompiler < anyFilename.pi > anyfilename.c"
	and produce the .c file.
	After that, compile the .c file with "gcc -o anyfilename anyfilename.c"
	Last, execute "./anyfilename" and done!

#Comments:
Some notices:
	1) shift/reduce conflicts were created in order to make my program
	able to accept .pi input files and produce files in C language.
		-First shift/reduce on state 66.
			This refers to 'statemet_declaration'. Specificaly on "statement ';'".
			In order to read prime.pi line 12 -> 1 shift/reduce conflict
		-----Removing this rule, or using // and make it as comment fixes the problem.

		-Second shift/reduce on state 87.
			This refers to 'expressions'. Specificaly on "TOKEN_NUM ';'".
			In order to read prime.pi line 21 -> 1 shift/reduce conflict
		-----Removing this rule, or using // and make it as comment fixes the problem.

		-Third shift/reduce on state 181.
			This refers to 'function_variable_list'. Specificaly on "expression".
			In order to read almost any .pi program I don't use the ';'
			at the end of "expression".
		-----Inserting the ';' fixes the problem.
	So, for those 3 conflicts we can actually accept any .pi program as input. If we fix
	those shift/reduce, the program will not accept any .pi program at all.

	2) If I chose a different way to implement the assignment, maybe
	there wouldn't exist those conflicts and the files would be accepted normally.
	
	3) prime.pi from provided files, had an error in line 36 where (num<=limit).
	For my purpose of use, I made it (limit==num).
