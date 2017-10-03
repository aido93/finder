# finder
c++-bicycle for 'find' utility

## Dependencies
* boost filesystem
* flex
* bison

## Building
mkdir build && cd build && cmake .. && make

## Usage
./finder

to interrupt search process press Ctrl+C. To exit press 'quit' or 'exit'

Tokens:
1) 'name' - 'contains', '==', 'is'
2) 'size' - '<', '>', '==', 'is'
3) 'attribute' - 'is'/'not' -  'hidden', 'directory', 'readonly'
4) 'and', 'or', 'not'

## Example of command

./finder

"/home/user" name contains "config" and size < 1500
