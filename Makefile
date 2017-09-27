all: finder

finder.tab.cpp finder.tab.hpp:	finder.y
	bison -d -t finder.y -r all --report-file bison_report.txt -o finder.tab.cpp

lex.yy.c: finder.l
	flex --outfile=./lex.yy.c finder.l

finder.o: finder.tab.cpp finder.tab.hpp
	g++ -std=c++11 -I. -c -o finder.tab.o finder.tab.cpp

lexer.o: lex.yy.c
	g++ -std=c++11 lex.yy.c -I. -c -o lexer.o

predicate_abstract_factory.o: predicate_abstract_factory.hpp predicate_abstract_factory.cpp
	g++ -std=c++11 predicate_abstract_factory.cpp -c -o predicate_abstract_factory.o

finder: finder.o lexer.o predicate_abstract_factory.o 
	g++ -ggdb lexer.o finder.tab.o predicate_abstract_factory.o -lboost_system -lboost_filesystem -lfl -lreadline -o finder

clean:
	rm finder finder.tab.c lex.yy.c finder.tab.h
