%option noyywrap

%{
#include "predicate_abstract_factory.hpp"
#include <stdio.h>
#include <stdint.h>

#define YY_DECL int yylex()

#include "finder.tab.hpp"

//#include "abstract_factory.hpp"
%}

%%

[ \t]	; // ignore all whitespace
[0-9]+				{yylval.ival = atoi(yytext); return INT;}
\"[a-zA-Z0-9\/]+\"	{yylval.str = strdup(yytext); return STR;}

"and"				{return AND;}
"or"				{return OR;}
"not"				{return NOT;}
"("					{return LEFT;}
")"					{return RIGHT;}
	
"name"				{return NAME;}
"size"				{return SIZE;}
"attribute" 		{return ATTRIBUTE;}

"readonly"	 		{return READONLY;}
"hidden" 			{return HIDDEN;}
"directory" 		{return DIRECTORY;}

"=="				{return IS;}
"<"                 {return LESS;}
">"                 {return MORE;}
"is"				{return IS;}
"contains"			{return CONTAINS;}

"exit"				{return QUIT;}
"quit"				{return QUIT;}
\n					{return NEWLINE;}
.    				{ fprintf(stderr, "Unexpected input character '%c', ignoring\n", *yytext); }

%%
