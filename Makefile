CFLAGS = -g -O3 -Wall -Wno-format-truncation
CFLAGS += -I/TDengine/include -I/usr/include
CXXFLAGS = --std=c++17 -g -O3 -Wall -Wno-format-truncation
ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS += -I"$(ERLANG_PATH)" -Ic_src -fPIC
CXXFLAGS += -I"$(ERLANG_PATH)" -Ic_src -fPIC
LIB_NAME = priv/lib_taos_nif.so
LDFLAGS = -L/usr/lib -ltaos

NIF_SRC=\
	c_src/lib_taos_nif.c

all: $(LIB_NAME)

$(LIB_NAME): $(NIF_SRC)
	mkdir -p priv
	$(CC) $(CFLAGS) -shared $^ $(LDFLAGS) -o $@

clean:
	rm -f $(LIB_NAME)

.PHONY: all clean