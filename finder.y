%{

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string>
#include <regex>
#include "predicate_abstract_factory.hpp"
#include <iostream>
using namespace std;
extern int yylex();
extern int yyparse();
extern FILE* yyin;
const char* begin_line="> ";
predicate_abstract_factory factory;

void yyerror(const char* s)
{
	std::cerr<<"error: "<<s<<"\n";
}
%}

%union {
	uint32_t   	ival;
	char		*str;
	predicate	*pred;
}

%token<ival> INT
%token<str> STR

%token LEFT RIGHT
%left OR
%left AND
%left NOT

%left NAME SIZE ATTRIBUTE
%token IS LESS MORE CONTAINS
%token NEWLINE QUIT

%type<pred> entry_point braced_expr not_expr filter
%start input

%%

input  : /*empty*/
	   | input line
;

line: STR entry_point NEWLINE 
	{
		std::cout<<"string::"<<$1<<std::endl;
		string path = regex_replace($1, regex("^\" +| +\"$|/+\"$"), "$1");
        if(path[path.length()-1] != '/')
        {
		    path+="/";
        }
		state s;
		bf::recursive_directory_iterator dir{bf::path(path)};
        for(auto file: dir)
        {
			std::cout<<file.path().string()<<std::endl;
			s.file=file;
			if((*$2)(s))
			{
				auto fn=file.path().string();
				std::cout<<"\t"<<fn.substr(path.length(), fn.length()-path.length())<<std::endl;
			}
		}
	} 
	| error NEWLINE
	{
		yyerrok;
	}
    | QUIT NEWLINE { printf("bye!\n"); exit(0); }
;

entry_point: 
		    braced_expr
			{
				$$ = $1;
			}
			| not_expr
			{
				$$ = $1;
			}
			| filter
			{
				$$ = $1;
			}
;

braced_expr: LEFT not_expr RIGHT	
			{ 
				$$ = $2;
			}
			| LEFT filter RIGHT
			{
				$$ = $2;
			}
			| LEFT braced_expr RIGHT
			{
				$$ = $2;
			}
			| braced_expr AND entry_point
			{
				$$=(*$1) && $3;
			}
			| braced_expr OR entry_point
			{
				$$=(*$1) || $3;
			}
;

not_expr 	: NOT braced_expr
			{
				$$ = !(*$2);
			}
			| NOT filter
			{
				$$ = !(*$2);
			}
;

filter  : 
		SIZE IS INT
	    {
			auto func = factory.get_function("is_equal");
			inner_state s;
			s.size=$3;
			func->set_inner_state(s);
			$$=func;
		}
		|
		SIZE MORE INT 
	    {
			auto func = factory.get_function("is_more");
			inner_state s;
			s.size=$3;
			func->set_inner_state(s);
			$$=func;
		}
		|
		SIZE LESS INT 
	    {
			auto func = factory.get_function("is_less");
			inner_state s;
			s.size=$3;
			func->set_inner_state(s);
			$$=func;
		}
		| filter AND entry_point
		{
			$$=(*$1) && $3;
		}
		| filter OR entry_point
		{
			$$=(*$1) || $3;
		}
;

%%

int main() {
	initialize_factory(factory);
	yyin = stdin;

	do { 
		yyparse();
	} while(!feof(yyin));

	return 0;
}

