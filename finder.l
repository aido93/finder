%option noyywrap

%{
#include "predicate_abstract_factory.hpp"
#include <stdio.h>
#include <stdint.h>

#define YY_DECL extern "C" int yylex()

#include "finder.tab.hpp"

#include "config.h"

#ifdef USE_READLINE

	#include <readline/readline.h>
	const char* begin_line=">";
	inline int readline_input(char* buf, const size_t max_size)
	{
		static char* residue_string=nullptr;
		static char* input_line=nullptr;
		if ( YY_CURRENT_BUFFER_LVALUE->yy_is_interactive ) 
		{ 
			if(residue_string == nullptr)
			{
				input_line=readline(begin_line);
				if(input_line==nullptr)
				{
					input_line = strdup("");
				}
				residue_string=input_line;
			}
			int n; 
			for ( n = 0; n < max_size-1 && residue_string[n]!='\0'; ++n ) 
			{
				buf[n] = residue_string[n]; 
			}
			residue_string = &input_line[n];
	        if (residue_string[0] == '\0')
    	    {
        	    residue_string=nullptr;
            	free(input_line);
        	}
			if(n < max_size)
			{
	        	buf[n++]='\n';
			}
			return n;
		}
	}
	#define YY_INPUT(buf, result, max_size) \
		result=readline_input((buf), (max_size));
	 
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
\n					{return NEWLINE_T;}
.    				{ fprintf(stderr, "Unexpected input character '%c', ignoring\n", *yytext); }

%%
