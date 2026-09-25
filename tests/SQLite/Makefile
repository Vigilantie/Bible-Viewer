.PHONY: all SQLite clean

all:
	clang++ test.cpp ../../src/search.cpp -std=c++17 -lsqlite3 -o SQLite

test:
	./SQLite

clean:
	rm -f SQLite
