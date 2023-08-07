CC = gcc
DBG_BIN = lldb
CFLAGS = #-D_GNU_SOURCE
CFLAGS += -std=c11
CFLAGS += -Wall
CFLAGS += -pedantic
CFLAGS += -Werror
CFLAGS += -Wextra
CFLAGS += -Wmissing-declarations

ifeq ($(shell uname), Linux)

CFLAGS += -I/usr/local/include
LDFLAGS = -L/usr/local/lib
LIBS = -lraylib

else

CFLAGS += $(shell pkg-config --cflags raylib)
LDFLAGS = $(shell pkg-config --libs raylib)

endif

SRC_FILES = ./src/*.c
BIN_DIR = ./bin
BIN = $(BIN_DIR)/life
TEST_DIR = ./tests
TEST_SRC = $(filter-out ./src/main.c, $(wildcard ./src/*.c)) $(TEST_DIR)/*.c

build: bin-dir
	$(CC) $(CFLAGS) $(LDFLAGS) $(LIBS) -o $(BIN) $(SRC_FILES)

bin-dir:
	mkdir -p $(BIN_DIR)

debug: debug-build
	$(DBG_BIN) $(BIN) $(ARGS)

debug-build: bin-dir
	$(CC) $(CFLAGS) $(LDFLAGS) $(LIBS) -g -o $(BIN) $(SRC_FILES)

run: build
	@$(BIN) $(ARGS)

test:
	$(CC) $(CFLAGS) $(LDFLAGS) $(LIBS) -o $(TEST_DIR)/tests $(TEST_SRC) && $(TEST_DIR)/tests

test-debug:
	$(CC) $(CFLAGS) $(LDFLAGS) $(LIBS) -g -o $(TEST_DIR)/tests $(TEST_SRC) && lldb $(TEST_DIR)/tests $(ARGS)

clean:
	rm -rf $(BIN_DIR)/* $(TEST_DIR)/tests*

gen-compilation-db:
	bear -- make build

gen-compilation-db-make:
	make --always-make --dry-run \
	| grep -wE 'gcc|g\+\+' \
	| grep -w '\-c' \
	| jq -nR '[inputs|{directory:".", command:., file: match(" [^ ]+$").string[1:]}]' \
	> compile_commands.json
