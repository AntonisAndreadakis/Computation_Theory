%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "cgen.h"
	#include "myanalyzer.tab.h"

	int line_num = 1;

	/* Pi allows 'single quoted' strings; C does not, so rewrite them as "..." */
	static char *single_to_double(const char *s)
	{
		size_t len = strlen(s);
		char *out = malloc(2 * len + 1);
		char *p = out;

		*p++ = '"';
		for (size_t i = 1; i + 1 < len; i++) {
			if (s[i] == '"' || s[i] == '\\')
				*p++ = '\\';
			*p++ = s[i];
		}
		*p++ = '"';
		*p = '\0';
		return out;
	}
%}

%option noyywrap nounput noinput

DIGIT	[0-9]
NUMBER	{DIGIT}+
DECIMAL	("."{NUMBER})|({NUMBER}("."{NUMBER}?)?)
REAL	{DECIMAL}([eE][+-]?{NUMBER})?
ID	[a-zA-Z_][0-9a-zA-Z_]*
SQ_STRING	'[^'\n]*'
DQ_STRING	\"(\\.|[^"\\\n])*\"

%x comment

%%

int		return KW_INT;
real		return KW_REAL;
string		return KW_STRING;
bool		return KW_BOOL;
var		return KW_VAR;
const		return KW_CONST;
func		return KW_FUNCTION;
begin		return KW_BEGIN;
if		return KW_IF;
else		return KW_ELSE;
for		return KW_FOR;
while		return KW_WHILE;
break		return KW_BREAK;
continue	return KW_CONTINUE;
return		return KW_RETURN;
true		return KW_TRUE;
false		return KW_FALSE;
nil		return KW_NIL;
not		return KW_NOT;
and		return KW_AND;
or		return KW_OR;

{ID}		{ yylval.crepr = strdup(yytext);		return TOKEN_IDENTIFIER;	}
{NUMBER}	{ yylval.crepr = strdup(yytext);		return TOKEN_NUM;		}
{REAL}		{ yylval.crepr = strdup(yytext);		return TOKEN_REAL;		}
{DQ_STRING}	{ yylval.crepr = strdup(yytext);		return TOKEN_STRING;		}
{SQ_STRING}	{ yylval.crepr = single_to_double(yytext);	return TOKEN_STRING;		}

"**"	return POWER;
"=="	return EQUAL;
"!="	return NOT_EQUAL;
"<="	return LESS_EQUAL;
">="	return GREATER_EQUAL;
"<"	return LESS;
">"	return GREATER;

[-+*/%=,()\[\]{};]	return yytext[0];

"//"[^\n]*		/* eat line comments */

"/*"			BEGIN(comment);
<comment>[^*\n]*	/* eat anything that's not a '*' */
<comment>"*"+[^*/\n]*	/* eat up '*'s not followed by '/' */
<comment>\n		++line_num;
<comment>"*"+"/"	BEGIN(INITIAL);
<comment><<EOF>>	{ yyerror("Unterminated comment"); return 0; }

[ \r\t]			/* skip whitespace */
\n			++line_num;

.	{ yyerror("Lexical error: unrecognized character '%s'", yytext); }

%%
