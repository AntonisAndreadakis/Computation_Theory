%{
/*
 * Parser and C code generator for the Pi language.
 *
 * Code generation convention (this is what keeps the grammar conflict-free):
 *   - an expression NEVER contains a ';'
 *   - a statement ALWAYS ends with ";\n" or "}\n"
 *   - a body is a sequence of such lines, not yet indented
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cgen.h"

extern int yylex(void);

/* bison passes a ready-made message; never let it be used as a format string */
#define yyerror(msg) yyerror("%s", msg)

/* Prototypes of all Pi functions, so they may be called before their definition */
static char *prototypes = "";
%}

%union
{
	char *crepr;
}

%define parse.error verbose

%token <crepr> TOKEN_IDENTIFIER TOKEN_NUM TOKEN_REAL TOKEN_STRING

%token KW_INT KW_REAL KW_STRING KW_BOOL
%token KW_VAR KW_CONST KW_FUNCTION KW_BEGIN
%token KW_IF KW_ELSE KW_FOR KW_WHILE KW_BREAK KW_CONTINUE KW_RETURN
%token KW_TRUE KW_FALSE KW_NIL
%token KW_NOT KW_AND KW_OR
%token POWER EQUAL NOT_EQUAL LESS LESS_EQUAL GREATER GREATER_EQUAL

/*
 * Operator precedence, lowest first. Operators on the same line share a level.
 * Apart from '**' (translated to a pow() call) the levels match C, so the
 * generated text means in C exactly what was parsed here.
 */
%left KW_OR
%left KW_AND
%left EQUAL NOT_EQUAL
%left LESS LESS_EQUAL GREATER GREATER_EQUAL
%left '+' '-'
%left '*' '/' '%'
%right POWER
%precedence UNARY	/* not, unary + and -, casts */

/* Dangling else: an 'else' binds to the nearest 'if' */
%precedence THEN
%precedence KW_ELSE

%type <crepr> top_items top_item func_main function ret_type
%type <crepr> params_opt params param_group param_names param_name
%type <crepr> declaration declarators declarator type
%type <crepr> body item block ctrl_body else_body
%type <crepr> stmt if_stmt other_stmt simple for_part for_cond
%type <crepr> assign lvalue call args_opt args expr

%start program

%%

/* ---------- program structure ---------- */

program: top_items func_main top_items
	{
		if (yyerror_count == 0) {
			puts(c_prologue);
			if (*prototypes)
				printf("%s\n", prototypes);
			printf("%s%s%s", $1, $2, $3);
			printf("int main(void) {\n\tpi_begin();\n\treturn 0;\n}\n");
		}
	}
;

top_items: %empty		{ $$ = ""; }
| top_items top_item		{ $$ = template("%s%s", $1, $2); }
;

top_item: declaration		{ $$ = template("%s\n", $1); }
| function			{ $$ = $1; }
| ';'				{ $$ = ""; }	/* optional ';' after a function */
;

/* 'func begin()' is the entry point; it becomes pi_begin(), called from main() */
func_main: KW_FUNCTION KW_BEGIN '(' ')' '{' body '}'
	{ $$ = template("void pi_begin(void) {\n%s}\n\n", indent($6)); }
;

function: KW_FUNCTION TOKEN_IDENTIFIER '(' params_opt ')' ret_type '{' body '}'
	{
		char *signature = template("%s %s(%s)", $6, $2, $4);
		prototypes = template("%s%s;\n", prototypes, signature);
		$$ = template("%s {\n%s}\n\n", signature, indent($8));
	}
;

ret_type: %empty		{ $$ = "void"; }
| type				{ $$ = $1; }
| '[' ']' type			{ $$ = template("%s*", $3); }
;

/* Parameters: "n int, k int", grouped "a, b int", arrays "v[] int" / "v []int" */
params_opt: %empty		{ $$ = "void"; }
| params			{ $$ = $1; }
;

params: param_group		{ $$ = $1; }
| params ',' param_group	{ $$ = template("%s, %s", $1, $3); }
;

param_group: param_names type	{ $$ = param_list($2, $1); }
;

param_names: param_name		{ $$ = $1; }
| param_names ',' param_name	{ $$ = template("%s" LIST_SEP "%s", $1, $3); }
;

param_name: TOKEN_IDENTIFIER	{ $$ = $1; }
| TOKEN_IDENTIFIER '[' ']'	{ $$ = template("%s[]", $1); }
;

/* ---------- declarations ---------- */

declaration: KW_VAR declarators type ';'	{ $$ = template("%s;", decl_list($3, $2)); }
| KW_CONST declarators type ';'			{ $$ = template("const %s;", decl_list($3, $2)); }
;

declarators: declarator		{ $$ = $1; }
| declarators ',' declarator	{ $$ = template("%s" LIST_SEP "%s", $1, $3); }
;

declarator: TOKEN_IDENTIFIER		{ $$ = $1; }
| TOKEN_IDENTIFIER '[' expr ']'		{ $$ = template("%s[%s]", $1, $3); }
| TOKEN_IDENTIFIER '=' expr		{ $$ = template("%s = %s", $1, $3); }
;

type: KW_INT	{ $$ = "int"; }
| KW_REAL	{ $$ = "double"; }
| KW_STRING	{ $$ = "char*"; }
| KW_BOOL	{ $$ = "int"; }
;

/* ---------- statements ---------- */

body: %empty			{ $$ = ""; }
| body item			{ $$ = template("%s%s", $1, $2); }
;

item: declaration		{ $$ = template("%s\n", $1); }
| stmt				{ $$ = $1; }
| ';'				{ $$ = ""; }	/* optional ';' after a '}' */
;

stmt: block			{ $$ = template("{\n%s}\n", indent($1)); }
| if_stmt			{ $$ = $1; }
| other_stmt			{ $$ = $1; }
;

/* The value of a block is its inner lines, without the braces */
block: '{' body '}'		{ $$ = $2; }
;

/* Body of if/while/for: always emitted inside braces, so no double braces */
ctrl_body: block		{ $$ = indent($1); }
| if_stmt			{ $$ = indent($1); }
| other_stmt			{ $$ = indent($1); }
;

if_stmt: KW_IF '(' expr ')' ctrl_body %prec THEN	{ $$ = template("if (%s) {\n%s}\n", $3, $5); }
| KW_IF '(' expr ')' ctrl_body KW_ELSE else_body	{ $$ = template("if (%s) {\n%s} else %s", $3, $5, $7); }
;

else_body: if_stmt		{ $$ = $1; }	/* gives a flat "else if" chain */
| block				{ $$ = template("{\n%s}\n", indent($1)); }
| other_stmt			{ $$ = template("{\n%s}\n", indent($1)); }
;

other_stmt: simple ';'					{ $$ = template("%s;\n", $1); }
| KW_WHILE '(' expr ')' ctrl_body			{ $$ = template("while (%s) {\n%s}\n", $3, $5); }
| KW_FOR '(' for_part ';' for_cond ';' for_part ')' ctrl_body
	{ $$ = template("for (%s; %s; %s) {\n%s}\n", $3, $5, $7, $9); }
;

for_part: %empty		{ $$ = ""; }
| assign			{ $$ = $1; }
;

for_cond: %empty		{ $$ = ""; }
| expr				{ $$ = $1; }
;

simple: assign			{ $$ = $1; }
| call				{ $$ = $1; }
| KW_RETURN			{ $$ = "return"; }
| KW_RETURN expr		{ $$ = template("return %s", $2); }
| KW_BREAK			{ $$ = "break"; }
| KW_CONTINUE			{ $$ = "continue"; }
;

assign: lvalue '=' expr		{ $$ = template("%s = %s", $1, $3); }
| lvalue '+' '=' expr		{ $$ = template("%s += %s", $1, $4); }
| lvalue '-' '=' expr		{ $$ = template("%s -= %s", $1, $4); }
;

lvalue: TOKEN_IDENTIFIER	{ $$ = $1; }
| lvalue '[' expr ']'		{ $$ = template("%s[%s]", $1, $3); }
;

call: TOKEN_IDENTIFIER '(' args_opt ')'	{ $$ = template("%s(%s)", $1, $3); }
;

args_opt: %empty		{ $$ = ""; }
| args				{ $$ = $1; }
;

args: expr			{ $$ = $1; }
| args ',' expr			{ $$ = template("%s, %s", $1, $3); }
;

/* ---------- expressions ---------- */

expr: TOKEN_NUM			{ $$ = $1; }
| TOKEN_REAL			{ $$ = $1; }
| TOKEN_STRING			{ $$ = $1; }
| KW_TRUE			{ $$ = "1"; }
| KW_FALSE			{ $$ = "0"; }
| KW_NIL			{ $$ = "NULL"; }
| lvalue			{ $$ = $1; }
| call				{ $$ = $1; }
| '(' expr ')'			{ $$ = template("(%s)", $2); }
| '(' type ')' expr %prec UNARY	{ $$ = template("(%s) %s", $2, $4); }
| KW_NOT expr %prec UNARY	{ $$ = template("!%s", $2); }
| '-' expr %prec UNARY		{ $$ = template($2[0] == '-' ? "-(%s)" : "-%s", $2); }
| '+' expr %prec UNARY		{ $$ = template($2[0] == '+' ? "+(%s)" : "+%s", $2); }
| expr POWER expr		{ $$ = template("pow(%s, %s)", $1, $3); }
| expr '*' expr			{ $$ = template("%s * %s", $1, $3); }
| expr '/' expr			{ $$ = template("%s / %s", $1, $3); }
| expr '%' expr			{ $$ = template("%s %% %s", $1, $3); }
| expr '+' expr			{ $$ = template("%s + %s", $1, $3); }
| expr '-' expr			{ $$ = template("%s - %s", $1, $3); }
| expr LESS expr		{ $$ = template("%s < %s", $1, $3); }
| expr LESS_EQUAL expr		{ $$ = template("%s <= %s", $1, $3); }
| expr GREATER expr		{ $$ = template("%s > %s", $1, $3); }
| expr GREATER_EQUAL expr	{ $$ = template("%s >= %s", $1, $3); }
| expr EQUAL expr		{ $$ = template("%s == %s", $1, $3); }
| expr NOT_EQUAL expr		{ $$ = template("%s != %s", $1, $3); }
| expr KW_AND expr		{ $$ = template("%s && %s", $1, $3); }
| expr KW_OR expr		{ $$ = template("%s || %s", $1, $3); }
;

%%

int main(void)
{
	if (yyparse() == 0 && yyerror_count == 0) {
		fprintf(stderr, "Accepted!\n");
		return 0;
	}
	fprintf(stderr, "Rejected!\n");
	return 1;
}
