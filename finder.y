%{

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <functional>
#include <string>
#include <regex>
#include <iostream>
#include "predicate_abstract_factory.hpp"
using namespace std;
extern int yylex();
extern int yyparse();
extern FILE* yyin;

predicate_abstract_factory factory;

void yyerror(const char* s);
%}

%union {
	uint32_t   	ival;
	char		*str;
	predicate	*pred;
}

%token<ival> INT
%token<str> STR

%token LEFT RIGHT
%left AND OR
%left NOT

%left NAME SIZE ATTRIBUTE
%token IS LESS MORE CONTAINS
%token NEWLINE QUIT

%type<pred> entry_point braced_expr not_expr filter

%start finding

%%

finding: 
	   | finding line
;

line: NEWLINE
    | STR entry_point NEWLINE 
	{
		string path = string($1);
		path=path.substr(1, path.length()-2);
		path = regex_replace(path, regex("^ +| +$|/+$"), "$1");
        if(path[path.length()-1] != '/')
        {
		    path+="/";
        }
		state s;
		bf::recursive_directory_iterator dir{bf::path(path)}, end;
		auto it=bf::begin(dir);
		while(it!=end)
		{
			s.file=*it;
			if(bf::is_regular_file(s.file) && (*$2)(s))
			{
				auto fn=it->path().string();
				std::cout<<"\t"<<fn.substr(path.length(), fn.length()-path.length())<<std::endl;
			}
			try
			{
				it++;
			}
			catch(const bf::filesystem_error& err)
			{
				cout<<err.what()<<endl;
				continue;
			}
		}
	} 
    | QUIT NEWLINE { printf("bye!\n"); exit(0); }
;

entry_point  : braced_expr
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

void yyerror(const char* s) {
	fprintf(stderr, "Parse error: %s\n", s);
	exit(1);
}
