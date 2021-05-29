%{
	#include <assert.h>
	#include <stdio.h>
	#include <string.h>
	#include "cgen.h"
	#include <math.h>
	#include "myanalyzer.tab.h"
	int line_num = 1;
	
%}


DIGIT	[0-9]
NUMBER	{DIGIT}{DIGIT}*
DECIMAL	("."{NUMBER})|({NUMBER}("."{NUMBER}?)?)
REAL	{DECIMAL}([eE][+-]?{NUMBER})?
ID	[a-zA-Z_][0-9a-zA-Z_]*
STRING	('[^'\n]*')|(\"(\\.|[^"\\])*\")    

%x comment

%%

int		{ yylval.crepr = strdup(yytext);	return KW_INT;		}
false		{ yylval.crepr = strdup(yytext); 	return KW_FALSE;	}
for		{ yylval.crepr = strdup(yytext);	return KW_FOR;		}
nil		{ yylval.crepr = strdup(yytext);	return KW_NIL;		}
begin		{ yylval.crepr = strdup(yytext); 	return KW_BEGIN;	}
real		{ yylval.crepr = strdup(yytext);	return KW_REAL;		}
var		{ yylval.crepr = strdup(yytext);	return KW_VAR;		}
while		{ yylval.crepr = strdup(yytext); 	return KW_WHILE;	}
and		{ yylval.crepr = strdup(yytext);	return KW_AND;		}
string		{ yylval.crepr = strdup(yytext);	return KW_STRING;	}
const		{ yylval.crepr = strdup(yytext);	return KW_CONST;	}
break		{ yylval.crepr = strdup(yytext);	return KW_BREAK;	}
or		{ yylval.crepr = strdup(yytext);	return KW_OR;		}
bool		{ yylval.crepr = strdup(yytext);	return KW_BOOL;		}
if		{ yylval.crepr = strdup(yytext);	return KW_IF;		}
continue	{ yylval.crepr = strdup(yytext);	return KW_CONTINUE;	}
not		{ yylval.crepr = strdup(yytext);	return KW_NOT;		}
true		{ yylval.crepr = strdup(yytext);	return KW_TRUE;		}
else		{ yylval.crepr = strdup(yytext);	return KW_ELSE;		}
func		{ yylval.crepr = strdup(yytext);	return KW_FUNCTION;	}
return		{ yylval.crepr = strdup(yytext);	return KW_RETURN;	}


{ID}			{ yylval.crepr = strdup(yytext);		return TOKEN_IDENTIFIER;	}
{NUMBER}		{ yylval.crepr = strdup(yytext);		return TOKEN_NUM;		}
{REAL}			{ yylval.crepr = strdup(yytext);		return TOKEN_REAL;		}
{STRING}		{ yylval.crepr = strdup(yytext);		return TOKEN_STRING;		}




"+"	{ yylval.crepr = strdup(yytext);	return '+';	}	
"-"	{ yylval.crepr = strdup(yytext);	return '-';	}	
"*"	{ yylval.crepr = strdup(yytext);	return '*';	}	
"/"	{ yylval.crepr = strdup(yytext);	return '/';	}	
"%"	{ yylval.crepr = strdup(yytext);	return '%';	}	
"**"	{ yylval.crepr = strdup(yytext);	return POWER;	}	

"=="	{ yylval.crepr = strdup(yytext);	return EQUAL;		}	
"!="	{ yylval.crepr = strdup(yytext);	return NOT_EQUAL;	}	
"<"	{ yylval.crepr = strdup(yytext);	return LESS;		}	
"<="	{ yylval.crepr = strdup(yytext);	return LESS_EQUAL;	}	
">"	{ yylval.crepr = strdup(yytext);	return GREATER;		}	
">="	{ yylval.crepr = strdup(yytext);	return GREATER_EQUAL;	}	



"="	{ yylval.crepr = strdup(yytext);	return '=';	}	

","	{ yylval.crepr = strdup(yytext);	return ',';	}	
"("	{ yylval.crepr = strdup(yytext);	return '(';	}
")"	{ yylval.crepr = strdup(yytext);	return ')';	}
"["	{ yylval.crepr = strdup(yytext);	return '[';	}
"]"	{ yylval.crepr = strdup(yytext);	return ']';	}
"{"	{ yylval.crepr = strdup(yytext);	return '{';	}
"}"	{ yylval.crepr = strdup(yytext);	return '}';	}
";"	{ yylval.crepr = strdup(yytext);	return ';';	}



"//"[^\n]*  	/* eat line comments */

"/*"			BEGIN(comment);
<comment>[^*\n]*        /* eat anything that's not a '*' */
<comment>"*"+[^*/\n]*   /* eat up '*'s not followed by ')'s */
<comment>\n             ++line_num;
<comment>"*"+"/"        BEGIN(INITIAL);


[ \r\t]				/* skip whitespace */
\n 				++line_num;
<<EOF>> 			return EOF;

.        { printf("\n\n/** Lexical error in line %d **/\n", line_num); yyerror("Unrecognized literal : '%s' \n", yytext); }

%%





