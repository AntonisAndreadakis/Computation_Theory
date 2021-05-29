%{

#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "cgen.c"	
#include "cgen.h"
#include "pilib.h"


extern int yylex(void);

extern int line_num;

%}

%union
{
	char* crepr;
}

%define parse.trace
%debug

//Tokens are terminals, types are non-terminals
%token <crepr> TOKEN_IDENTIFIER
%token <crepr> TOKEN_NUM
%token <crepr> TOKEN_REAL
//%token <crepr> TOKEN_BOOL
%token <crepr> TOKEN_STRING


//Keywords:
%token KW_INT
%token KW_FALSE
%token KW_FOR
%token KW_NIL
%token KW_BEGIN
%token KW_REAL
%token KW_VAR
%token KW_WHILE

%token KW_STRING
%token KW_CONST
%token KW_BREAK

%token KW_BOOL
%token KW_IF
%token KW_CONTINUE

%token KW_TRUE
%token KW_ELSE
%token KW_FUNCTION
%token KW_RETURN

%right KW_NOT
%left KW_AND
%left KW_OR

//Operators:
%left '+'
%left '-'
%left '*'
%left '/'
%left '%'
%left POWER //isws 8elei douleia
%left EQUAL
%left NOT_EQUAL
%left LESS
%left LESS_EQUAL
%left GREATER
%left GREATER_EQUAL

//Delimiters:
%right ';'
//%left '('
//%left ')'
%left ','
//%left '{'
//%left '}'
//%left '['
//%left ']'




%type <crepr> main_body
%type <crepr> func_main
%type <crepr> func
%type <crepr> outside_decl
%type <crepr> function_list
%type <crepr> return_state
%type <crepr> parameters_list
%type <crepr> parameters
%type <crepr> pos_statements
%type <crepr> list_statements
%type <crepr> statement_declaration
%type <crepr> statements
%type <crepr> if_statement

%type <crepr> for_statement
%type <crepr> while_statement
%type <crepr> function
%type <crepr> return
%type <crepr> function_variable_list
%type <crepr> statement_cont
%type <crepr> expression
%type <crepr> table_exp
%type <crepr> profunc_call
%type <crepr> declaration
%type <crepr> var_body
%type <crepr> var_list
%type <crepr> var_initialize
%type <crepr> var_ident
%type <crepr> data_type
%type <crepr> type






%type <crepr> program

%start program

%%


program:  main_body { //decl_list KW_FUNCTION KW_BEGIN '(' ')' '{' main_body '}'
/*	We have a successful parse!
	Check for any errors and generate output.	*/
	if (yyerror_count == 0) {
	// include the pilib.h file
		puts(c_prologue); 
		printf("/* program */ \n\n");
		printf("%s\n\n", $1);
		//we can skip next printf:
		printf("/* int main() {\n%s\n} */\n", $1);
		}
	}
;


//how program is built:
main_body: func_main	{ $$ = template("%s\n", $1);			}
| func func_main	{ $$ = template("%s\n%s\n", $1, $2);		}
| func_main func	{ $$ = template("%s\n%s\n", $1, $2);		}
| func func_main func	{ $$ = template("%s\n%s\n%s\n", $1, $2, $3);	}
;

func: outside_decl	{ $$ = template("%s\n", $1);		}
| func outside_decl	{ $$ = template("%s\n%s\n", $1, $2);	}
;

outside_decl: declaration	{ $$ = template("%s",$1);	} 
| function_list			{ $$ = template("%s",$1);	}
;

//any function:
function_list : KW_FUNCTION var_ident '(' parameters_list ')' return_state '{' pos_statements '}' ';'	{ $$ = template("%s %s(%s) {\n%s\n};\n", $6, $2, $4, $8); }
;

//return type of function:
return_state: type	{ $$ = template("%s", $1);	}
| '[' ']' type		{ $$ = template("%s*", $3);	}
;
//parameters:
parameters_list: %empty					{ $$ = template("");						}
| parameters ',' parameters type ',' parameters_list	{ $$ = template("%s %s ,%s %s, %s", $4, $1, $4, $3, $6);	}
| parameters ',' parameters type			{ $$ = template("%s %s, %s %s", $4, $1, $4, $3);		}
| parameters type ',' parameters_list			{ $$ = template("%s %s , %s", $2, $1, $4);			}
| parameters type					{ $$ = template("%s %s", $2, $1);				}
;

parameters: TOKEN_IDENTIFIER	{ $$ = template("%s", $1);	}
| TOKEN_IDENTIFIER '[' ']'	{ $$ = template("%s[]", $1);	}
;

//set main function to void, as mentioned in the assignment:
func_main: KW_FUNCTION KW_BEGIN '(' ')' '{' pos_statements '}'	{ $$ = template("void main(){\n%s}", $6); }
;
//some statements:
pos_statements: %empty	{ $$ = template("");		}
|list_statements	{ $$ = template("%s", $1);	}
;

list_statements: statement_declaration	{ $$ = template("\t%s\n", $1);		}
| list_statements statement_declaration	{ $$ = template("%s\n\t%s\n", $1, $2);	}
;

statement_declaration: declaration	{ $$ = template("%s", $1);	}
| statements				{ $$ = template("%s", $1);	}
| statements ';' //in order to read prime.pi line 12 -> 1 shift/reduce conflict (can't find a way to fix)
;

//I created only if-else, while, for:
statements: var_ident '=' expression 		{ $$ = template("%s = %s;",$1, $3);	}
| var_ident '=' function 			{ $$ = template("%s = %s", $1, $3);	}
| if_statement					{ $$ = template("%s", $1);		}
| for_statement ';'				{ $$ = template("%s", $1);		}
| while_statement ';'				{ $$ = template("%s", $1);		}
| function ';'					{ $$ = template("%s", $1);		}
| return ';'					{ $$ = template("%s", $1);		}
;

if_statement: KW_IF '(' expression ')' '{' pos_statements '}' ';'			{ $$ = template("\tif(%s){\n%s\n}", $3, $6);				} // if multi-line.
| KW_IF '(' expression ')' '{' pos_statements '}' KW_ELSE '{' pos_statements '}' ';'	{ $$ = template("if(%s){\n\t%s\n}\n\telse{\n\t%s\t}", $3, $6, $10);	} //if-else multiline.
| KW_IF '(' expression ')' statement_declaration					{ $$ = template("if(%s) \n\t\t%s\n\t", $3, $5); }
| KW_ELSE statement_declaration								{ $$ = template("else %s", $2);			}
| KW_ELSE '{' pos_statements '}' ';'							{ $$ = template("else {\n\t\n%s\n\t}", $3);	}
;


for_statement : KW_FOR '(' statements ';' expression ';' statement_cont ')' '{' statements pos_statements '}'	{ $$ = template("for (%s; %s; %s++){\n%s\n%s\n}", $3, $5, $7, $10, $11);}
;

while_statement: KW_WHILE '(' expression ')' '{' statements pos_statements '}'	{$$ = template("while(%s) {\n%s\n%s\n}", $3, $6,$7);}
;

function: TOKEN_IDENTIFIER '(' function_variable_list ')'	{$$ = template("%s(%s);\n", $1, $3);}
;

return: KW_RETURN	{ $$ = template("return;"); }
| KW_RETURN expression	{ $$ = template("return %s;", $2); }
;  

function_variable_list: %empty			{ $$ = template("");			}
| expression 					{ $$ = template("%s", $1);		}
| function_variable_list ',' expression		{ $$ = template("%s , %s", $1, $3);	}
;

statement_cont:  KW_RETURN 			{ $$ = template("return;");			}
| KW_RETURN expression 				{ $$ = template("return %s;", $2);		}  
| var_ident '=' expression 			{ $$ = template("%s = %s;", $1, $3);		}
| var_ident '=' '(' type ')' expression 	{ $$ = template("%s = (%s)%s;", $1, $4,$6);	}
| var_ident table_exp '=' expression 		{ $$ = template("%s%s = %s;", $1, $2, $4);	}  
| var_ident '+' '=' expression			{ $$ = template("%s += %s;", $1, $4);		}
| var_ident '-' '=' expression			{ $$ = template("%s -= %s;", $1, $4);		}
| var_ident table_exp '+' '=' expression 	{ $$ = template("%s%s += %s;", $1, $2, $5);	}
| var_ident table_exp '-' '=' expression 	{ $$ = template("%s%s -= %s;", $1, $2, $5);	}			  
| KW_BREAK ';'					{ $$ = template("break;");			}
| KW_CONTINUE					{ $$ = template("continue;");			}
| profunc_call					{ $$ = template("%s;", $1);			}
;


//expressions:
expression: TOKEN_NUM			{ $$ = template("%s", $1);		}
| TOKEN_NUM ';'				{ $$ = template("%s", $1);		} //in order to read prime.pi line 21 -> 1 shift/reduce conflict
| TOKEN_STRING				{ $$ = template("%s", $1);		}				
| TOKEN_REAL				{ $$ = template("%s", $1);		}
| var_ident				{ $$ = template("%s", $1);		}
| var_ident table_exp			{ $$ = template("%s %s", $1, $2);	}
| profunc_call				{ $$ = template("%s", $1);		}		
| '(' expression ')'			{ $$ = template("(%s)", $2);		}
| expression POWER expression		{ $$ = template("pow(%s, %s)", $1, $3); }
| expression '*' expression		{ $$ = template("%s * %s", $1, $3);	}
| expression '/' expression		{ $$ = template("%s / %s", $1, $3);	}
| expression '%' expression		{ $$ = template("%s %% %s", $1, $3);	}		  
| '+' expression			{ $$ = template("+ %s", $2);		}
| '-' expression 			{ $$ = template("- %s", $2);		}
| expression '+' expression 		{ $$ = template("%s + %s", $1, $3);	}
| expression '-' expression 		{ $$ = template("%s - %s", $1, $3);	}
| expression EQUAL expression 		{ $$ = template("%s == %s", $1, $3);	}
| expression NOT_EQUAL expression	{ $$ = template("%s != %s", $1, $3);	}
| expression LESS expression		{ $$ = template("%s < %s", $1, $3);	}
| expression LESS_EQUAL expression	{ $$ = template("%s <= %s", $1, $3);	}
| expression GREATER expression		{ $$ = template("%s > %s", $1, $3);	}
| expression GREATER_EQUAL expression	{ $$ = template("%s >= %s", $1, $3);	}
| expression KW_AND expression		{ $$ = template("%s && %s", $1, $3);	}
| expression KW_OR expression		{ $$ = template("%s || %s", $1, $3);	}
| expression KW_NOT expression		{ $$ = template("%s ! %s", $1, $3);	}
| KW_FALSE				{ $$ = template("0");	}
| KW_TRUE 				{ $$ = template("1");	}
;

table_exp: '[' expression ']'		{ $$ = template("[%s]",  $2);		}
| table_exp '[' expression ']'		{ $$ = template("%s [%s]", $1, $3);	}
;

//call function:
profunc_call: TOKEN_IDENTIFIER '(' expression ')' 	{ $$ = template("%s(%s);", $1, $3); }
;

//define variable type as var or const:
declaration: KW_VAR var_body	{ $$ = template("%s", $2);		}
| KW_CONST var_body		{ $$ = template("const %s", $2);	}
;

var_body: var_list type ';'	{ $$ = template("%s %s;", $2, $1);}
;

var_list: var_list ',' var_initialize	{ $$ = template("%s, %s", $1, $3 );}
| var_initialize			{ $$ = template("%s", $1); }
;

var_initialize: var_ident	{ $$ = template("%s", $1); }
| var_ident '=' data_type	{ $$ = template("%s = %s", $1, $3); }
;

var_ident: TOKEN_IDENTIFIER		{ $$ = template("%s", $1); }
| TOKEN_IDENTIFIER  TOKEN_NUM 		{ $$ = template("%s[%s]", $1, $2); }
;

data_type: TOKEN_IDENTIFIER	{ $$ = template("%s", $1);	}
| TOKEN_NUM			{ $$ = template("%s", $1);	}
| TOKEN_STRING			{ $$ = template("%s", $1);	}
| TOKEN_REAL			{ $$ = template("%s", $1);	}
//| TOKEN_BOOL			{ $$ = template("%s", $1);	}
| '-' TOKEN_IDENTIFIER		{ $$ = template("-%s", $2);	}
| '-' TOKEN_NUM			{ $$ = template("-%s", $2);	}
| '-' TOKEN_REAL		{ $$ = template("-%s", $2);	}
| KW_TRUE			{ $$ = "1";	}
| KW_FALSE			{ $$ = "0";	}
; 


type: KW_INT	{ $$ = template("%s", "int");		}
| KW_REAL	{ $$ = template("%s", "double");	}
| KW_STRING	{ $$ = template("%s", "char*");		}
| KW_BOOL	{ $$ = template("%s", "int");		}
;

%%


int main () {
	if ( yyparse() == 0 )
		printf("//Accepted!\n");
	else
		printf("Rejected!\n");
}



