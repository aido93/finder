%option noyywrap

%{
#include "predicate_abstract_factory.hpp"
#include <stdio.h>
#include <stdint.h>
#include "finder.tab.hpp"
#include <readline/readline.h>
static char* residue_string=NULL;
static char* input_line=NULL;
extern const char* begin_line;
#define YY_DECL int yylex()


#define YY_INPUT(buf,result,max_size) \
	if ( YY_CURRENT_BUFFER_LVALUE->yy_is_interactive ) \
		{ \
		if(!residue_string)\
		{\
			input_line=readline(begin_line);\
			residue_string=input_line;\
		}\
		size_t n; \
		if(input_line)\
		for ( n = 0; n < max_size-1 && residue_string[n]!='\0'; ++n ) \
		{\
			buf[n] = residue_string[n]; \
		}\
        buf[n++]='\n';\
		if(n==max_size && (input_line[n]!='\0' || input_line[n]!=EOF))\
			residue_string=&input_line[n+1];\
        else \
        {\
            residue_string=NULL;\
            free(input_line);\
        }\
		result = n; \
		} \
	else \
		{ \
		errno=0; \
		while ( (result = fread(buf, 1, max_size, yyin))==0 && ferror(yyin)) \
			{ \
			if( errno != EINTR) \
				{ \
				YY_FATAL_ERROR( "input in flex scanner failed" ); \
				break; \
				} \
			errno=0; \
			clearerr(yyin); \
			} \
		}
%}

%%

[ \t]	; // ignore all whitespace
[0-9]+				{yylval.ival = atoi(yytext); return INT;}
\"[a-zA-Z0-9]+\"    {yylval.str = strdup(yytext); return STR;}

"and"				{return AND;}
"or"				{return OR;}
"not"				{return NOT;}
"("					{return LEFT;}
")"					{return RIGHT;}
	
"name"				{return NAME;}
"size"				{return SIZE;}
"attribute" 		{return ATTRIBUTE;}
"=="				{return IS;}
"<"                 {return LESS;}
">"                 {return MORE;}
"is"				{return IS;}
"contains"			{return CONTAINS;}

"exit"				{return QUIT;}
"quit"				{return QUIT;}
\n					{return NEWLINE;}

%%
