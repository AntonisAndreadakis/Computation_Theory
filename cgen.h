#ifndef CGEN_H
#define CGEN_H

#include <stdio.h>

/*
	String streams are handy for using standard C-library
	functions to produce formatted strings.
*/
typedef struct sstream
{
	char *buffer;
	size_t bufsize;
	FILE* stream;
} sstream;

void ssopen(sstream* S);
char* ssvalue(sstream* S);
void ssclose(sstream* S);


/*
 	This function takes the same arguments as printf,
 	but returns a new string with the output value in it.
 */
char* template(const char* pat, ...);

/* Returns a copy of s with every non-empty line indented by one tab. */
char* indent(const char* s);

/*
	Lists of names are passed around as one string, separated by LIST_SEP.
	decl_list:  ("int", "a|b")   -> "int a, b"      ("char*", "a|b") -> "char *a, *b"
	param_list: ("int", "a|b[]") -> "int a, int b[]"
*/
#define LIST_SEP "\x01"
char* decl_list(const char* type, const char* names);
char* param_list(const char* type, const char* names);

/*
	This is the function used to report errors in the translation.
*/
void yyerror(char const* pat, ...);

/*
	This is set to the number of calls to yyerror
 */
extern int yyerror_count;


/* This is output at the head of a c program. */
extern const char* c_prologue;


#endif
