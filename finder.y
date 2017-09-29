%{
/** TODO:
1) add to predicates test is_regular_file - done
2) add tests on predicate_abstract_factory.hpp
3) add cmake build - done
4) add simple syntax error handling - done
5) add new predicates and states (attribute)
6) refactor code to divide bison and logic
7) add libreadline support
8) add doxygen
9) add smart pointers
*/
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

void yyerror(const char* str) {
	std::cerr<<"Parse error: "<<str<<"\n";
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
%left AND OR
%left NOT

%left NAME SIZE ATTRIBUTE
%token IS LESS MORE CONTAINS HIDDEN READONLY DIRECTORY
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
		cout<<"Search finished"<<endl;
	} 
	| error NEWLINE
	{
		yyerrok;
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
		| SIZE MORE INT 
	    {
			auto func = factory.get_function("is_more");
			inner_state s;
			s.size=$3;
			func->set_inner_state(s);
			$$=func;
		}
		| SIZE LESS INT 
	    {
			auto func = factory.get_function("is_less");
			inner_state s;
			s.size=$3;
			func->set_inner_state(s);
			$$=func;
		}
		| NAME IS STR 
	    {
			auto func = factory.get_function("is_name_equals");
			inner_state s;
			//delete quotes
			s.str=string($3);
			s.str=s.str.substr(1, s.str.length()-2);
			func->set_inner_state(s);
			$$=func;
		}
		| NAME CONTAINS STR 
	    {
			auto func = factory.get_function("contains");
			inner_state s;
			//delete quotes
			s.str=string($3);
			s.str=s.str.substr(1, s.str.length()-2);
			func->set_inner_state(s);
			$$=func;
		}
		| ATTRIBUTE IS DIRECTORY
	    {
			auto func = factory.get_function("attribute_is");
			inner_state s;
			s.attr=attribute::directory;
			func->set_inner_state(s);
			$$=func;
		}
		| ATTRIBUTE IS HIDDEN
	    {
			auto func = factory.get_function("attribute_is");
			inner_state s;
			s.attr=attribute::hidden;
			func->set_inner_state(s);
			$$=func;
		}
		| ATTRIBUTE IS READONLY
	    {
			auto func = factory.get_function("attribute_is");
			inner_state s;
			s.attr=attribute::readonly;
			func->set_inner_state(s);
			$$=func;
		}
		| ATTRIBUTE NOT DIRECTORY
	    {
			auto func = factory.get_function("attribute_not");
			inner_state s;
			s.attr=attribute::directory;
			func->set_inner_state(s);
			$$=func;
		}
		| ATTRIBUTE NOT HIDDEN
	    {
			auto func = factory.get_function("attribute_not");
			inner_state s;
			s.attr=attribute::hidden;
			func->set_inner_state(s);
			$$=func;
		}
		| ATTRIBUTE NOT READONLY
	    {
			auto func = factory.get_function("attribute_not");
			inner_state s;
			s.attr=attribute::readonly;
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
