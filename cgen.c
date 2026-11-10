#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include "cgen.h"

extern int line_num;

void ssopen(sstream *S)
{
	S->stream = open_memstream(&S->buffer, &S->bufsize);
}

char *ssvalue(sstream *S)
{
	fflush(S->stream);
	return S->buffer;
}

void ssclose(sstream *S)
{
	fclose(S->stream);
}

char *template(const char *pat, ...)
{
	sstream S;
	ssopen(&S);

	va_list arg;
	va_start(arg, pat);
	vfprintf(S.stream, pat, arg);
	va_end(arg);

	char *ret = ssvalue(&S);
	ssclose(&S);
	return ret;
}

/* Prefix every non-empty line of s with a tab */
char *indent(const char *s)
{
	sstream S;
	ssopen(&S);

	int at_line_start = 1;
	for (; *s; s++) {
		if (at_line_start && *s != '\n')
			fputc('\t', S.stream);
		fputc(*s, S.stream);
		at_line_start = (*s == '\n');
	}

	char *ret = ssvalue(&S);
	ssclose(&S);
	return ret;
}

/* Shared by decl_list and param_list: walk the LIST_SEP separated names */
static char *join_names(const char *names, const char *before_each)
{
	sstream S;
	ssopen(&S);

	char *copy = strdup(names);
	int first = 1;
	for (char *name = strtok(copy, LIST_SEP); name; name = strtok(NULL, LIST_SEP)) {
		fprintf(S.stream, "%s%s%s", first ? "" : ", ", before_each, name);
		first = 0;
	}
	free(copy);

	char *ret = ssvalue(&S);
	ssclose(&S);
	return ret;
}

char *decl_list(const char *type, const char *names)
{
	/* In C the '*' belongs to each name, not to the type: char *a, *b */
	size_t len = strlen(type);
	if (len > 0 && type[len - 1] == '*') {
		char *base = strdup(type);
		base[len - 1] = '\0';
		return template("%s %s", base, join_names(names, "*"));
	}
	return template("%s %s", type, join_names(names, ""));
}

char *param_list(const char *type, const char *names)
{
	return join_names(names, template("%s ", type));
}

/*
	Report errors
*/
void yyerror(char const *pat, ...)
{
	va_list arg;
	fprintf(stderr, "line %d: ", line_num);

	va_start(arg, pat);
	vfprintf(stderr, pat, arg);
	va_end(arg);

	fprintf(stderr, "\n");

	yyerror_count++;
}

int yyerror_count = 0;

const char *c_prologue =
		"#include \"pilib.h\"\n"
		"\n";
