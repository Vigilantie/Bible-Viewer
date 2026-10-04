.PHONY: all parse_bible clean

SRC=../src
cJSON=../external/cJSON

all:
	mkdir -p build/tests/o
	clang++ -std=c++17 -c $(SRC)/parse.cpp -I$(SRC) -I$(cJSON) -o build/tests/o/parse.o
	clang++ -std=c++17 -c parse_bible.cpp -I$(cJSON) -o build/tests/o/parse_bible.o
	clang -c $(cJSON)/cJSON.c -o build/tests/o/cJSON.o
	clang++ build/tests/o/parse.o build/tests/o/parse_bible.o build/tests/o/cJSON.o -o build/tests/parse_bible

parse_bible:
	mkdir -p build/tests
	clang++ -std=c++17 -c src/parse.cpp -Isrc -Iexternal/cJSON -o build/tests/o/parse.o
	clang++ -std=c++17 -c tests/parse_bible.cpp -Isrc -Iexternal/cJSON -o build/tests/o/parse_bible.o
	clang -c external/cJSON/cJSON.c -o build/tests/o/cJSON.o
	clang++ build/tests/o/parse.o build/tests/o/temp.o build/tests/o/cJSON.o -o build/tests/parse_bible

highlight:
	clang++ ../src/core/util.cpp ../src/core/highlight.cpp highlightTests.cpp -I../include -lsqlite3 -std=c++17

clean:
	rm -r build/tests
