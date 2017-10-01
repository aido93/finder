%option noyywrap

%{
#include "predicate_abstract_factory.hpp"
#include <stdio.h>
#include <stdint.h>

#define YY_DECL int yylex()

#include "finder.tab.hpp"

#define USE_READLINE

#ifdef USE_READLINE

	#include <readline/readline.h>
	const char* begin_line=">";
	inline void readline_input(char* buf, int* result, const size_t max_size)
	{
		char* residue_string=NULL;
		char* input_line=NULL;
		if ( YY_CURRENT_BUFFER_LVALUE->yy_is_interactive ) 
		{ 
			if(!residue_string)
			{
				input_line=readline(begin_line);
				residue_string=input_line;
			}
			size_t n; 
			if(input_line)
				for ( n = 0; n < max_size-1 && residue_string[n]!='\0'; ++n ) 
				{
					buf[n] = residue_string[n]; 
				}
	        buf[n++]='\n';
			if(n==max_size && (input_line[n]!='\0' || input_line[n]!=EOF))
			{
				residue_string=&input_line[n+1];
			}
	        else 
    	    {
        	    residue_string=NULL;
            	free(input_line);
        	}
			*result = n; 
		}
	}
	#define YY_INPUT(buf, result, max_size) \
		readline_input((buf), (&result), (max_size));
	 
#endif
%}

%%

[ \t]	; // ignore all whitespace
[0-9]+				{yylval.ival = atoi(yytext); return INT;}
\"[a-zA-Z0-9_\- .\/()]+\"	{yylval.str = strdup(yytext); return STR;}

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
